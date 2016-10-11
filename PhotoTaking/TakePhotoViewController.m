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
@property (strong, nonatomic) UIImageView* dimView;

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
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:(UIBarButtonItemStyleDone) target:self action:@selector(onSave:)];
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
    
    //    [self applyMoonCrop];
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
    
    self.containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.containerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.containerView];
    
    self.originalImageView = [[UIImageView alloc] initWithFrame:self.containerView.bounds];
    self.originalImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.originalImageView.userInteractionEnabled = YES;
    [self.containerView addSubview:self.originalImageView];
    
    self.dimView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.dimView.contentMode = UIViewContentModeScaleAspectFit;
    self.dimView.userInteractionEnabled = NO;
    [self.view addSubview:self.dimView];
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
    self.dimView.image = [self reverseMaskImage:[UIImage imageNamed:@"rounder"] toSize:self.dimView.bounds.size];
}

//Touch methods for panning image

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if([touch.view isKindOfClass:[UIImageView class]] && touch.view.tag == TAG_FOR_TOUCHING){
        previousLocation = [touch locationInView:self.view];
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
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if([touch.view isKindOfClass:[UIImageView class]] && touch.view.tag == 1){
        previousLocation = [touch locationInView:self.view];
    }
}

- (void)pinchedOnImage: (UIPinchGestureRecognizer *)sender
{
    self.originalImageView.transform = CGAffineTransformScale(self.originalImageView.transform, sender.scale, sender.scale);
    sender.scale = 1;   // to slow down
}

- (void)rotatedOnImage: (UIRotationGestureRecognizer *)sender
{
    self.originalImageView.transform = CGAffineTransformRotate(self.originalImageView.transform, sender.rotation);
    sender.rotation = 0;    // to slow down
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)onSave:(id)sender {
    
    UIImage* visibleImage = [self getVisibleImageFrom:self.containerView];
    UIImage* maskImage = [self growImage:[UIImage imageNamed:@"rounder"] toSize:self.view.bounds.size];
    UIImage* finalImage = [self maskImage:visibleImage withMask:maskImage];
    UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil);
}

- (UIImage*)getVisibleImageFrom:(UIView*)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, [UIScreen mainScreen].scale);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}

- (UIImage*)growImage:(UIImage*)sourceImage toSize:(CGSize)size
{
    float oldWidth = sourceImage.size.width * [UIScreen mainScreen].scale;
    float oldHeight = sourceImage.size.height * [UIScreen mainScreen].scale;
    float scaleFactor = 1;//size.width / oldWidth;
    
    float newHeight = oldHeight * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    float width = size.width * [UIScreen mainScreen].scale;
    float height = size.height * [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [UIScreen mainScreen].scale);
    [sourceImage drawInRect:CGRectMake((width - newWidth)/2, (height - newHeight)/2, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*)maskImage:(UIImage *)image withMask:(UIImage *)mask
{
    int width = image.size.width * [UIScreen mainScreen].scale;
    int height = image.size.height * [UIScreen mainScreen].scale;
    
    // Create a suitable RGB+alpha bitmap context in BGRA colour space
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *memoryPoolForImage = (unsigned char *)calloc(width*height*4, 1);
    CGContextRef contextForImage = CGBitmapContextCreate(memoryPoolForImage, width, height, 8, width * 4, colourSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    
    unsigned char *memoryPoolForMask = (unsigned char *)calloc(width*height*4, 1);
    CGContextRef contextForMask = CGBitmapContextCreate(memoryPoolForMask, width, height, 8, width * 4, colourSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(colourSpace);
    
    // draw the current image to the newly created context
    CGContextDrawImage(contextForImage, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextDrawImage(contextForMask, CGRectMake(0, 0, width, height), mask.CGImage);
    
    // run through every pixel, a scan line at a time...
    for(int y = 0; y < height; y++)
    {
        // get a pointer to the start of this scan line
        unsigned char *linePointerForImage = &memoryPoolForImage[y * width * 4];
        unsigned char *linePointerForMask = &memoryPoolForMask[y * width * 4];
        
        // step through the pixels one by one...
        for(int x = 0; x < width; x++)
        {
            // get RGB values. We're dealing with premultiplied alpha
            // here, so we need to divide by the alpha channel (if it
            // isn't zero, of course) to get uninflected RGB. We
            // multiply by 255 to keep precision while still using
            // integers
            int r, g, b;
            if(linePointerForMask[3])
            {
                r = linePointerForImage[0] * 255 / linePointerForImage[3];
                g = linePointerForImage[1] * 255 / linePointerForImage[3];
                b = linePointerForImage[2] * 255 / linePointerForImage[3];
            }
            else
                r = g = b = 0;
            
            linePointerForImage[3] = linePointerForMask[3];
            
            // multiply by alpha again, divide by 255 to undo the
            // scaling before, store the new values and advance
            // the pointer we're reading pixel data from
            linePointerForImage[0] = r * linePointerForImage[3] / 255;
            linePointerForImage[1] = g * linePointerForImage[3] / 255;
            linePointerForImage[2] = b * linePointerForImage[3] / 255;
            
            linePointerForImage += 4;
            linePointerForMask += 4;
        }
    }
    
    // get a CG image from the context, wrap that into a
    // UIImage
    CGImageRef cgImage = CGBitmapContextCreateImage(contextForImage);
    UIImage *returnImage = [UIImage imageWithCGImage:cgImage scale:[UIScreen mainScreen].scale orientation:(UIImageOrientationUp)];
    
    // clean up
    CGImageRelease(cgImage);
    CGContextRelease(contextForImage);
    CGContextRelease(contextForMask);
    free(memoryPoolForImage);
    free(memoryPoolForMask);
    
    // and return
    return returnImage;
}

- (UIImage *)reverseMaskImage:(UIImage*)sourceImage toSize:(CGSize)size
{
    float oldWidth = sourceImage.size.width * [UIScreen mainScreen].scale;
    float oldHeight = sourceImage.size.height * [UIScreen mainScreen].scale;
    float scaleFactor = 1;//size.width / oldWidth;
    
    float newHeight = oldHeight * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    int width = size.width * [UIScreen mainScreen].scale;
    int height = size.height * [UIScreen mainScreen].scale;
    
    // Create a suitable RGB+alpha bitmap context in BGRA colour space
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *memoryPool = (unsigned char *)calloc(width*height*4, 1);
    CGContextRef context = CGBitmapContextCreate(memoryPool, width, height, 8, width * 4, colourSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);
    
    // draw the current image to the newly created context
    CGContextSetRGBFillColor(context, 0, 0, 0, 0.6);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    CGContextDrawImage(context, CGRectMake((width - newWidth)/2, (height - newHeight)/2, newWidth, newHeight), sourceImage.CGImage);
    
    // run through every pixel, a scan line at a time...
    for(int y = 0; y < height; y++)
    {
        // get a pointer to the start of this scan line
        unsigned char *linePointer = &memoryPool[y * width * 4];
        
        // step through the pixels one by one...
        for(int x = 0; x < width; x++)
        {
            // get RGB values. We're dealing with premultiplied alpha
            // here, so we need to divide by the alpha channel (if it
            // isn't zero, of course) to get uninflected RGB. We
            // multiply by 255 to keep precision while still using
            // integers
            int r, g, b;
            if(linePointer[3])
            {
                r = linePointer[0] * 255 / linePointer[3];
                g = linePointer[1] * 255 / linePointer[3];
                b = linePointer[2] * 255 / linePointer[3];
            }
            else
                r = g = b = 0;
            
            linePointer[3] = 1 - linePointer[3];
            
            // multiply by alpha again, divide by 255 to undo the
            // scaling before, store the new values and advance
            // the pointer we're reading pixel data from
            linePointer[0] = r * linePointer[3] / 255;
            linePointer[1] = g * linePointer[3] / 255;
            linePointer[2] = b * linePointer[3] / 255;
            
            linePointer += 4;
        }
    }
    
    // get a CG image from the context, wrap that into a
    // UIImage
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *returnImage = [UIImage imageWithCGImage:cgImage scale:[UIScreen mainScreen].scale orientation:(UIImageOrientationUp)];
    
    // clean up
    CGImageRelease(cgImage);
    CGContextRelease(context);
    free(memoryPool);
    
    // and return
    return returnImage;
}

@end
