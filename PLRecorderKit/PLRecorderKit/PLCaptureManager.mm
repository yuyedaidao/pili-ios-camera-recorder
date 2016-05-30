//
//  PLCaptureManager.m
//  PiliKit
//
//  Created by 0day on 14/10/29.
//  Copyright (c) 2014年 qgenius. All rights reserved.
//

#import "PLCaptureManager.h"
#import <AVFoundation/AVFoundation.h>
#import "VCSimpleSession.h"

NSString *PLCaptureManagerWillChangeCaptureDevicePositionNotification = @"notification.captureManager.position.willChange";
NSString *PLCaptureManagerDidChangeCaptureDevicePositionNotification = @"notification.captureManager.position.didChange";

@interface PLCaptureManager ()
<
VCSessionDelegate
>

@property (nonatomic, strong) VCSimpleSession   *session;

@property (nonatomic, strong) NSString  *host;
@property (nonatomic, strong) NSString  *streamName;

@property (nonatomic, assign) PLStreamState streamState; // rewrite

@end

@implementation PLCaptureManager

+ (instancetype)sharedManager {
    static PLCaptureManager *s_manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_manager = [[self alloc] init];
    });
    
    return s_manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.session = [[VCSimpleSession alloc] initWithVideoSize:CGSizeMake(1280, 720) frameRate:30 bitrate:1000000 useInterfaceOrientation:YES];
        self.session.delegate = self;
        
        self.streamBitrateMode = PLStreamBitrateMode_Default;
        
        self.streamState = PLStreamStateDisconnected;
    }
    
    return self;
}

#pragma mark - VCSessionDelegate

- (void)connectionStatusChanged:(VCSessionState)state {
    PLStreamState streamState = self.streamState;
    switch (state) {
        case VCSessionStatePreviewStarted:
            break;
        case VCSessionStateStarting:
            streamState = PLStreamStateConnecting;
            break;
        case VCSessionStateStarted:
            streamState = PLStreamStateConnected;
            break;
        case VCSessionStateEnded:
            streamState = PLStreamStateDisconnected;
            break;
        case VCSessionStateError:
            streamState = PLStreamStateError;
            break;
        case VCSessionStateNone:
        default:
            streamState = PLStreamStateUnknow;
            break;
    }
    
    if (streamState != self.streamState) {
        self.streamState = streamState;
        
        if ([self.delegate respondsToSelector:@selector(captureManager:streamStateDidChange:)]) {
            [self.delegate captureManager:self streamStateDidChange:streamState];
        }
    }
}

#pragma mark - Property

- (void)setPushURL:(NSURL *)pushURL { //TODO:地址处理并不优雅
    _pushURL = pushURL;
    
    NSString *scheme = pushURL.scheme;
    
    if (![scheme isEqualToString:@"rtmp"]) {
        NSLog(@"Error, the url scheme %@ is not supported.", scheme);
        return;
    }
    
    NSString *urlString = pushURL.absoluteString;
    NSArray *components = [urlString componentsSeparatedByString:@"/"];
    [components enumerateObjectsUsingBlock:^(NSString *str, NSUInteger idx, BOOL *stop) {
        if ([str isEqualToString:@"doPublish=test123"]) {
            NSString *host = components[0];
            for (NSUInteger i = 1; i <= idx; i++) {
                host = [host stringByAppendingString:[NSString stringWithFormat:@"/%@", components[i]]];
            }
            self.host = host;
            
            NSString *name = components[idx + 1];
            for (NSUInteger i = idx + 2; i < components.count; i++) {
                name = [name stringByAppendingString:[NSString stringWithFormat:@"/%@", components[i]]];
            }
            self.streamName = name;
            
            *stop = YES;
        }
    }];
}

- (void)setPreviewView:(UIView *)previewView {
    _previewView = previewView;
    
    [previewView addSubview:self.session.previewView];
    self.session.previewView.frame = previewView.bounds;
}

- (void)setCaptureDevicePosition:(PLCaptureDevicePosition)captureDevicePosition {
    _captureDevicePosition = captureDevicePosition;
    
    if (captureDevicePosition == PLCaptureDevicePositionFront) {
        self.session.cameraState = VCCameraStateFront;
    } else {
        self.session.cameraState = VCCameraStateBack;
    }
}

- (BOOL)isTorchOn {
    return self.session.torch;
}

- (void)setTorchOn:(BOOL)torchOn {
    self.session.torch = torchOn;
}

- (void)setStreamBitrateMode:(PLStreamBitrateMode)streamBitrateMode {
    _streamBitrateMode = streamBitrateMode;
    
    int bitrate = 0;
    BOOL useAdaptiveBitrate = NO;
    switch (streamBitrateMode) {
        case PLStreamBitrateMode_500Kbps:
            bitrate = 500000;
            break;
        case PLStreamBitrateMode_160Kbps:
            bitrate = 160000;
            break;
        case PLStreamBitrateMode_Adaptive: {
            bitrate = 500000;
            useAdaptiveBitrate = YES;
        }
            break;
        case PLStreamBitrateMode_1Mbps:
        default:
            _streamBitrateMode = PLStreamBitrateMode_1Mbps;
            bitrate = 1000000;
            break;
    }
    
    self.session.bitrate = bitrate;
    self.session.useAdaptiveBitrate = useAdaptiveBitrate;
}

#pragma mark - Authorize

static PLCaptureDeviceAuthorizedStatus s_status = PLCaptureDeviceAuthorizedStatusUnknow;
+ (PLCaptureDeviceAuthorizedStatus)captureDeviceAuthorizedStatus {
    return s_status;
}

+ (void)requestCaptureDeviceAccessWithCompletionHandler:(void (^)(BOOL granted))block {
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted) {
            s_status = PLCaptureDeviceAuthorizedStatusGranted;
        } else {
            s_status = PLCaptureDeviceAuthorizedStatusUngranted;
        }
        
        if (block) {
            block(granted);
        }
    }];
}

#pragma mark - Operation

- (void)connect {
    [self.session startRtmpSessionWithURL:self.host andStreamKey:self.streamName];
}

- (void)disconnect {
    [self.session endRtmpSession];
}

@end
