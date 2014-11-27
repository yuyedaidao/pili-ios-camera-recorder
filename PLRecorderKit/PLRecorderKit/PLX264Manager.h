//
//  PLX264Manager.h
//  PLRecorderKit
//
//  Created by 0day on 14/11/1.
//  Copyright (c) 2014年 qgenius. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <x264.h>
#import <common/common.h>
#import <encoder/set.h>
#import <librtmp/rtmp.h>

@interface PLX264Manager : NSObject {
    RTMP    *rtmp;
    
    x264_param_t * p264Param;
    x264_picture_t * p264Pic;
    x264_t *p264Handle;
    x264_nal_t  *p264Nal;
    int previous_nal_size;
    unsigned  char * pNal;
    FILE *fp;
    unsigned char szBodyBuffer[1024*32];
}

- (void)initForX264; //初始化x264
- (void)initRTMPWithURL:(NSURL *)url;

//- (void)initForFilePath; //初始化编码后文件的保存路径

- (void)encoderToH264:(CMSampleBufferRef)sampleBuffer; //将CMSampleBufferRef格式的数据编码成h264并写入文件

@end
