//
//  ViewController.h
//  PLRecorderKitDemo
//
//  Created by 0day on 14/10/30.
//  Copyright (c) 2014年 qgenius. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLPreviewView;
@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *previewView;

- (IBAction)recordButtonPressed:(id)sender;
- (IBAction)takePictureButtonPressed:(id)sender;
- (IBAction)changeCameraButtonPressed:(id)sender;

@end

