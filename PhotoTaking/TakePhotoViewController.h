//
//  TakePhotoViewController.h
//  PhotoTaking
//
//  Created by Allan Zhang on 10/3/16.
//  Copyright © 2016 Allan Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TakePhotoViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (strong, nonatomic) IBOutlet UIView *overlayView;

- (IBAction)didTapOnTakePhoto:(UIButton *)sender;
- (IBAction)didTapOnBack:(UIButton *)sender;
- (IBAction)didTapOnPhotosSelection:(UIButton *)sender;
- (IBAction)didTapFlashSwitch:(UIButton *)sender;
- (IBAction)didTapCameraTurn:(UIButton *)sender;



@end
