//
//  TakePhotoViewController.m
//  PhotoTaking
//
//  Created by Allan Zhang on 10/3/16.
//  Copyright © 2016 Allan Zhang. All rights reserved.
//

#import "TakePhotoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AVFoundation/AVFoundation.h>

@interface TakePhotoViewController () <UIGestureRecognizerDelegate>
{
    BOOL cameraIsReady;
    BOOL justHitCancelledToPreventPresentingCamera;
    CGPoint previousLocation;
    
    CGPoint lastPoint; //for pinching
    CGFloat lastScale; //for pinching
    
    CGFloat xStaticDeviationPercentage;
    CGFloat yStaticDeviationPercentage;
    
}

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImage *takenOrSelectedImage;
@property (strong, nonatomic) UIImageView *displayView;
@property (strong, nonatomic) UIImageView *topView;



@end

@implementation TakePhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    
    [self cameraConfiguration];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cameraIsReady:)
                                                 name:AVCaptureSessionDidStartRunningNotification object:nil];
    
    //Ensure that the camera is used as default
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera; //if there is a camera avaliable
    } else {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//otherwise go to the folder
    }
    
    BOOL modalPresent = (BOOL)(self.presentedViewController);
    //Present the Camera UIImagePicker if no image is taken
    if (!justHitCancelledToPreventPresentingCamera){
        //if (!appDelegate.imageStorageDictionary[@"picture1"]){
            if (modalPresent == NO){ //checks if the UIImagePickerController is already modally active
                if (![[self imagePickerController] isBeingDismissed]) [self dismissViewControllerAnimated:NO completion:nil];
                [self.navigationController presentViewController:self.imagePickerController animated:NO completion:nil];
            }
        //}
    }
    justHitCancelledToPreventPresentingCamera = NO;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
}

#pragma mark - Camera configuration

- (void)cameraConfiguration
{
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    self.imagePickerController.allowsEditing = NO;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera; //if there is a camera avaliable
    } else {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//otherwise go to the folder
    }
    self.imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    if (self.imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        self.imagePickerController.showsCameraControls = YES;
    }

}

- (void)cameraIsReady:(NSNotification *)notification
{
    NSLog(@"Camera is ready...");
    cameraIsReady = YES;
    
}

#pragma mark - Delegate methods for ImagePicker

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *imageTaken =  [info objectForKey:UIImagePickerControllerOriginalImage];
    self.takenOrSelectedImage = [self resizeImage:imageTaken];
    
    NSLog(@"%@", self.takenOrSelectedImage);
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    
    //The methods sets two UIImageViews: a background UIImageView with alpha 0.6, called self.displayView
    //and a foreground UIImageView with alpha 1.0, called self.topView
    //A mask is applied to self.topView
    
    [self displayImageOnScreen];
    [self displayImageOnTopView];
    
    
    NSLog(@"edit done");
}

- (void)displayImageOnScreen
{
    self.displayView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width*1.333333)];
    self.displayView.image = self.takenOrSelectedImage;
    self.displayView.tag = 1;
    self.displayView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.displayView];
    
    self.displayView.userInteractionEnabled = YES;
    self.displayView.alpha = 0.6;

    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchedOnImage:)];
    pinchGesture.delegate = self;
    [self.displayView addGestureRecognizer:pinchGesture];
   
    UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotatedOnImage:)];
    rotationGesture.delegate = self;
    [self.displayView addGestureRecognizer:rotationGesture];

    [self findAbsoluteDistanceToCenterWithPoint]; //doing it for the first time
}

- (void)displayImageOnTopView
{
    self.topView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width*1.333333)];
    self.topView.image = self.takenOrSelectedImage;
    self.topView.tag = 2;
    self.topView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.topView];
    
    [self applyMaskToImage];
}


//Touch methods for panning image

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if([touch.view isKindOfClass:[UIImageView class]] && touch.view.tag == 1){
        previousLocation = [touch locationInView:self.view];
        //[self applyMaskToImage];
    }
    
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if([touch.view isKindOfClass:[UIImageView class]] && touch.view.tag == 1){
        
        CGPoint location = [touch locationInView:self.view];
        
        float xDistanceFromBefore = location.x - previousLocation.x;
        float yDistanceFromBefore = location.y - previousLocation.y;
        
        self.displayView.center = CGPointMake(self.displayView.center.x + xDistanceFromBefore,
                                              self.displayView.center.y + yDistanceFromBefore);
        
        self.topView.center = CGPointMake(self.topView.center.x + xDistanceFromBefore,
                                          self.topView.center.y + yDistanceFromBefore);
        
        
        [self findAbsoluteDistanceToCenterWithPoint]; //see comments in method
        [self applyMaskToImage];
        
        
        previousLocation = location;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if([touch.view isKindOfClass:[UIImageView class]] && touch.view.tag == 1){
        previousLocation = [touch locationInView:self.view];
    }
}

//Pinch methods for zooming image

- (void)pinchedOnImage: (UIPinchGestureRecognizer *)sender
{
    //sender.view.transform = CGAffineTransformScale(sender.view.transform, sender.scale, sender.scale);
    self.displayView.transform = CGAffineTransformScale(self.displayView.transform, sender.scale, sender.scale);
    self.topView.transform = CGAffineTransformScale(self.topView.transform, sender.scale, sender.scale);
    
    sender.scale = 1;
    [self applyMaskToImage];
}

- (void)rotatedOnImage: (UIRotationGestureRecognizer *)sender
{
    //sender.view.transform = CGAffineTransformRotate(sender.view.transform, sender.rotation);
    self.displayView.transform = CGAffineTransformRotate(self.displayView.transform, sender.rotation);
    self.topView.transform = CGAffineTransformRotate(self.topView.transform, sender.rotation);
    
    sender.rotation = 0;
    [self applyMaskToImage];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}



- (void)findAbsoluteDistanceToCenterWithPoint
{
    //This method finds the static center the UIImageView prior to any changes made to them
    //The "1.333333" is used when originally displaying the UIImageView and is added here
    //It calculates the PERCENTAGE change of how much the user has panned the UIImageView from the center
    
    CGPoint staticCenter = CGPointMake(self.view.frame.size.width/2, (self.view.frame.size.width*1.333333)/2);
    
    float xDistanceChange = (self.displayView.center.x - staticCenter.x)/staticCenter.x;
    float yDistanceChange = (self.displayView.center.y - staticCenter.y)/staticCenter.y;
    
    xStaticDeviationPercentage = xDistanceChange;
    yStaticDeviationPercentage = yDistanceChange;
    
    NSLog(@"Percentage change: X:%f, Y:%f", xStaticDeviationPercentage, yStaticDeviationPercentage);
}



- (void)applyMaskToImage
{
    for (CALayer *sublayer in self.topView.layer.sublayers){
        [sublayer removeFromSuperlayer];
    }
    
    UIImage *moonImage = [UIImage imageNamed:@"rounder"];
    CALayer *maskLayer = [CALayer layer];
    [maskLayer setContents:(id)moonImage.CGImage];
    [maskLayer setFrame:CGRectMake(0.0f, 0.0f, moonImage.size.width, moonImage.size.height)];
    
    //Points the layer in the middle of the displayView
    
    maskLayer.position = (CGPoint){CGRectGetMidX(self.topView.bounds), CGRectGetMidY(self.topView.bounds)};
    
    //Explaination below:
    //0.5 anchors the point in the center of the image
    //The two floats xStaticDeviationPercentage and yStaticDeviationPercentage
    //is used to keep the mask appear in the center of the view while the user pans the image
    //At the moment, this is not working
    
    maskLayer.anchorPoint = CGPointMake(0.5 + xStaticDeviationPercentage,
                                        0.5 + yStaticDeviationPercentage); ///(1/1.333333) ignore this
    [self.topView.layer setMask:maskLayer];
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"Photo cancelled");
    
}

-(UIImage *)resizeImage:(UIImage *)image
{
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    
    float maxHeight = self.view.frame.size.width*1.333333*2;
    float maxWidth = self.view.frame.size.width*2;
    
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    
    if (actualHeight > maxHeight || actualWidth > maxWidth)
    {
        if(imgRatio < maxRatio)
        {
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio)
        {
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }
        else
        {
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = UIImagePNGRepresentation(img);
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithData:imageData];
    
}



- (UIImage *)createImageFromImage:(UIImage *)image
                    withMaskImage:(UIImage *)mask {
    CGImageRef imageRef = image.CGImage;
    CGImageRef maskRef = mask.CGImage;
    
    CGImageRef imageMask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                             CGImageGetHeight(maskRef),
                                             CGImageGetBitsPerComponent(maskRef),
                                             CGImageGetBitsPerPixel(maskRef),
                                             CGImageGetBytesPerRow(maskRef),
                                             CGImageGetDataProvider(maskRef),
                                             NULL,
                                             YES);
    
    CGImageRef maskedReference = CGImageCreateWithMask(imageRef, imageMask);
    CGImageRelease(imageMask);
    
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedReference];
    CGImageRelease(maskedReference);
    
    return maskedImage;
}

- (IBAction)didTapOnTakePhoto:(UIButton *)sender {
}

- (IBAction)didTapOnBack:(UIButton *)sender {
}

- (IBAction)didTapOnPhotosSelection:(UIButton *)sender {
}

- (IBAction)didTapFlashSwitch:(UIButton *)sender {
}

- (IBAction)didTapCameraTurn:(UIButton *)sender {
}
@end
