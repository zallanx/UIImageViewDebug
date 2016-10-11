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
}

@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) UIImage *takenOrSelectedImage;

// added by Raymond
@property (strong, nonatomic) UIView* containerView;
@property (strong, nonatomic) UIImageView* originalImageView;
@property (strong, nonatomic) UIView* dimView;
@property (strong, nonatomic) UIImageView* croppedImageView;

@end

#define TAG_FOR_TOUCHING 1

@implementation TakePhotoViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    [self cameraConfiguration];
    
    [self initUIViews];
    [self initGestureRecognizersTo:self.originalImageView withTag:TAG_FOR_TOUCHING];
    
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
    self.takenOrSelectedImage = imageTaken;
    
    self.originalImageView.image = self.takenOrSelectedImage;
    NSLog(@"%@", self.takenOrSelectedImage);
    [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    
    [self applyMoonCrop];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSLog(@"Photo cancelled");
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

- (void)initUIViews {
    
    // create necessary views
    // see storyboard as reference
    /*
     containerView
     originalImageView
     dimView
     croppedImageView
     */
    
    self.containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.containerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.containerView];
    
    self.originalImageView = [[UIImageView alloc] initWithFrame:self.containerView.bounds];
    self.originalImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.originalImageView.userInteractionEnabled = YES;
    [self.containerView addSubview:self.originalImageView];
    
    self.dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    self.dimView.userInteractionEnabled = NO;
    [self.view addSubview:self.dimView];
    
    self.croppedImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.croppedImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.croppedImageView.userInteractionEnabled = NO;
    [self.view addSubview:self.croppedImageView];
}

- (void)initGestureRecognizersTo:(UIView*)view withTag:(int)tag {
    
    view.tag = tag;
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchedOnImage:)];
    pinchGesture.delegate = self;
    [view addGestureRecognizer:pinchGesture];
    
    UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotatedOnImage:)];
    rotationGesture.delegate = self;
    [view addGestureRecognizer:rotationGesture];
}

- (void)viewDidLayoutSubviews {
    
    self.containerView.frame = self.view.bounds;
    self.originalImageView.frame = self.containerView.bounds;
    self.dimView.frame = self.view.bounds;
    self.croppedImageView.frame = self.view.bounds;
    
    [self applyMoonCrop];
}

//Touch methods for panning image

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if([touch.view isKindOfClass:[UIImageView class]] && touch.view.tag == TAG_FOR_TOUCHING){
        previousLocation = [touch locationInView:self.view];
        //[self applyMaskToImage];
    }
    
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if([touch.view isKindOfClass:[UIImageView class]] && touch.view.tag == TAG_FOR_TOUCHING){
        
        CGPoint location = [touch locationInView:self.view];
        
        float xDistanceFromBefore = location.x - previousLocation.x;
        float yDistanceFromBefore = location.y - previousLocation.y;
        
        self.originalImageView.center = CGPointMake(self.originalImageView.center.x + xDistanceFromBefore,
                                                    self.originalImageView.center.y + yDistanceFromBefore);
        
        previousLocation = location;
        [self applyMoonCrop];
        //        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(applyMoonCrop) object:nil];
        //        [self performSelector:@selector(applyMoonCrop) withObject:nil afterDelay:0.05];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if([touch.view isKindOfClass:[UIImageView class]] && touch.view.tag == 1){
        previousLocation = [touch locationInView:self.view];
        [self applyMoonCrop];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [self applyMoonCrop];
}

- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches NS_AVAILABLE_IOS(9_1) {
    [self applyMoonCrop];
}

- (void)pinchedOnImage: (UIPinchGestureRecognizer *)sender
{
    self.originalImageView.transform = CGAffineTransformScale(self.originalImageView.transform, sender.scale, sender.scale);
    [self applyMoonCrop];
}

- (void)rotatedOnImage: (UIRotationGestureRecognizer *)sender
{
    self.originalImageView.transform = CGAffineTransformRotate(self.originalImageView.transform, sender.rotation);
    [self applyMoonCrop];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (UIImage*)getVisibleImageFrom:(UIView*)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0f);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    //    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}

- (void)applyMoonCrop {
    
    UIImage* visibleImage = [self getVisibleImageFrom:self.containerView];
    UIImage* maskImage = [self resizeImage:[UIImage imageNamed:@"rounder"] toSize:self.croppedImageView.bounds.size];
    
    CALayer *maskLayer = [CALayer layer];
    [maskLayer setContents:(id)maskImage.CGImage];
    [maskLayer setFrame:CGRectMake(0.0f, 0.0f, maskImage.size.width, maskImage.size.height)];
    
    self.croppedImageView.image = visibleImage;
    [self.croppedImageView.layer setMask:maskLayer];
}

- (UIImage*)resizeImage:(UIImage*)sourceImage toSize:(CGSize)size
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = 1;//size.width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    [sourceImage drawInRect:CGRectMake((size.width - newWidth)/2, (size.height - newHeight)/2, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
