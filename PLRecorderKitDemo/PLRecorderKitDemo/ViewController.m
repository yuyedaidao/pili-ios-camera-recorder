//
//  ViewController.m
//  PLRecorderKitDemo
//
//  Created by 0day on 14/10/30.
//  Copyright (c) 2014年 qgenius. All rights reserved.
//

#import "ViewController.h"
#import <PLRecorderKit/PLRecorderKit.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    PLCaptureDeviceAuthorizedStatus status = [PLCaptureManager captureDeviceAuthorizedStatus];
    
    if (PLCaptureDeviceAuthorizedStatusUnknow == status) {
        [PLCaptureManager requestCaptureDeviceAccessWithCompletionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [PLCaptureManager sharedManager].previewView = self.previewView;
                });
            }
        }];
    } else if (PLCaptureDeviceAuthorizedStatusGranted == status) {
        [PLCaptureManager sharedManager].previewView = self.previewView;
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                            message:@"您没有授权开启摄像头"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    
    [PLCaptureManager sharedManager].pushURL = [NSURL URLWithString:@"rtmp://10.0.1.6/livestream/111"];
}

#pragma mark - Action

- (IBAction)recordButtonPressed:(id)sender {
    [[PLCaptureManager sharedManager] connect];
}

- (IBAction)takePictureButtonPressed:(id)sender {
}

- (IBAction)changeCameraButtonPressed:(id)sender {
}

@end
