//
//  ViewController.m
//  PhotoTaking
//
//  Created by Allan Zhang on 10/3/16.
//  Copyright © 2016 Allan Zhang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)photoAction:(UIButton *)sender
{
    [self performSegueWithIdentifier:@"showPhoto" sender:self];
}
@end
