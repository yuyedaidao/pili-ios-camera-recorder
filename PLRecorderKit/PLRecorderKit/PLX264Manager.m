//
//  PLX264Manager.m
//  PLRecorderKit
//
//  Created by 0day on 14/11/1.
//  Copyright (c) 2014年 qgenius. All rights reserved.
//

#import "PLX264Manager.h"
#import <AVFoundation/AVFoundation.h>

#define RTMP_HEAD_SIZE   (sizeof(RTMPPacket)+RTMP_MAX_HEADER_SIZE)

int sps_len = 0;
int pps_len = 0;
long start_time = 0;
uint8_t sps[10000];
uint8_t pps[10000];

int send_video_sps_pps(RTMP *rtmp)
{
    RTMPPacket * packet;
    unsigned char * body;
    int i;
    
    packet = (RTMPPacket *)malloc(RTMP_HEAD_SIZE+1024);
    memset(packet,0,RTMP_HEAD_SIZE);
    
    packet->m_body = (char *)packet + RTMP_HEAD_SIZE;
    body = (unsigned char *)packet->m_body;
    
//    memcpy(winsys->pps,buf,len);
//    winsys->pps_len = len;
    
    i = 0;
    body[i++] = 0x17;
    body[i++] = 0x00;
    
    body[i++] = 0x00;
    body[i++] = 0x00;
    body[i++] = 0x00;
    
    /*AVCDecoderConfigurationRecord*/
    body[i++] = 0x01;
    body[i++] = sps[1];
    body[i++] = sps[2];
    body[i++] = sps[3];
    body[i++] = 0xff;
    
    /*sps*/
    body[i++]   = 0xe1;
    body[i++] = (sps_len >> 8) & 0xff;
    body[i++] = sps_len & 0xff;
    memcpy(&body[i],sps,sps_len);
    i +=  sps_len;
    
    /*pps*/
    body[i++]   = 0x01;
    body[i++] = (pps_len >> 8) & 0xff;
    body[i++] = (pps_len) & 0xff;
    memcpy(&body[i],pps,pps_len);
    i +=  pps_len;
    
    packet->m_packetType = RTMP_PACKET_TYPE_VIDEO;
    packet->m_nBodySize = i;
    packet->m_nChannel = 0x04;
    packet->m_nTimeStamp = 0;
    packet->m_hasAbsTimestamp = 0;
    packet->m_headerType = RTMP_PACKET_SIZE_MEDIUM;
    packet->m_nInfoField2 = rtmp->m_stream_id;
    
    /*调用发送接口*/
    RTMP_SendPacket(rtmp,packet,TRUE);
    free(packet);
    
    return 0;
}

long GetTickCount()
{
    return 0;
}

int send_rtmp_video(unsigned char * buf,int len, RTMP *rtmp)
{
    int type;
    long timeoffset;
    RTMPPacket * packet;
    unsigned char * body;
    
    timeoffset = GetTickCount() - start_time;  /*start_time为开始直播时的时间戳*/
    
    /*去掉帧界定符*/
    if (buf[2] == 0x00) { /*00 00 00 01*/
        buf += 4;
        len -= 4;
    } else if (buf[2] == 0x01){ /*00 00 01*/
        buf += 3;
        len -= 3;
    }
    type = buf[0]&0x1f;
    
    packet = (RTMPPacket *)malloc(RTMP_HEAD_SIZE+len+9);
    memset(packet,0,RTMP_HEAD_SIZE);
    
    packet->m_body = (char *)packet + RTMP_HEAD_SIZE;
    packet->m_nBodySize = len + 9;
    
    /*send video packet*/
    body = (unsigned char *)packet->m_body;
    memset(body,0,len+9);
    
    /*key frame*/
    body[0] = 0x27;
    if (type == NAL_SLICE_IDR) {
        body[0] = 0x17;
    }
    
    body[1] = 0x01;   /*nal unit*/
    body[2] = 0x00;
    body[3] = 0x00;
    body[4] = 0x00;
    
    body[5] = (len >> 24) & 0xff;
    body[6] = (len >> 16) & 0xff;
    body[7] = (len >>  8) & 0xff;
    body[8] = (len ) & 0xff;
    
    /*copy data*/
    memcpy(&body[9],buf,len);
    
    packet->m_hasAbsTimestamp = 0;
    packet->m_packetType = RTMP_PACKET_TYPE_VIDEO;
    packet->m_nInfoField2 = rtmp->m_stream_id;
    packet->m_nChannel = 0x04;
    packet->m_headerType = RTMP_PACKET_SIZE_LARGE;
    packet->m_nTimeStamp = timeoffset;
    
    /*调用发送接口*/
    RTMP_SendPacket(rtmp,packet,TRUE);
    free(packet);
    
    return 0;
}

int cap_rtmp_sendaac_spec(unsigned char *spec_buf,int spec_len, RTMP *rtmp)
{
    RTMPPacket * packet;
    unsigned char * body;
    int len;
    
    len = spec_len;  /*spec data长度,一般是2*/
    
    packet = (RTMPPacket *)malloc(RTMP_HEAD_SIZE+len+2);
    memset(packet,0,RTMP_HEAD_SIZE);
    
    packet->m_body = (char *)packet + RTMP_HEAD_SIZE;
    body = (unsigned char *)packet->m_body;
    
    /*AF 00 + AAC RAW data*/
    body[0] = 0xAF;
    body[1] = 0x00;
    memcpy(&body[2],spec_buf,len); /*spec_buf是AAC sequence header数据*/
    
    packet->m_packetType = RTMP_PACKET_TYPE_AUDIO;
    packet->m_nBodySize = len+2;
    packet->m_nChannel = 0x04;
    packet->m_nTimeStamp = 0;
    packet->m_hasAbsTimestamp = 0;
    packet->m_headerType = RTMP_PACKET_SIZE_LARGE;
    packet->m_nInfoField2 = rtmp->m_stream_id;
    
    /*调用发送接口*/
    RTMP_SendPacket(rtmp,packet,TRUE);
    
    return TRUE;
}

@implementation PLX264Manager

- (void)initForX264 {
    p264Param = malloc(sizeof(x264_param_t));
    p264Pic  = malloc(sizeof(x264_picture_t));
    memset(p264Pic,0,sizeof(x264_picture_t));
    //x264_param_default(p264Param);  //set default param
    x264_param_default_preset(p264Param, "veryfast", "zerolatency");
    p264Param->i_threads = 1;
    p264Param->i_width   = 352;  //set frame width
    p264Param->i_height  = 288;  //set frame height
    p264Param->b_cabac =0;
    p264Param->i_bframe =0;
    p264Param->b_interlaced=0;
    p264Param->rc.i_rc_method=X264_RC_ABR;//X264_RC_CQP
    p264Param->i_level_idc=21;
    p264Param->rc.i_bitrate=128;
    p264Param->b_intra_refresh = 1;
    p264Param->b_annexb = 1;
    p264Param->i_keyint_max=25;
    p264Param->i_fps_num=15;
    p264Param->i_fps_den=1;
    p264Param->b_annexb = 1;
    //    p264Param->i_csp = X264_CSP_I420;
    x264_param_apply_profile(p264Param, "baseline");
    if((p264Handle = x264_encoder_open(p264Param)) == NULL)
    {
        fprintf( stderr, "x264_encoder_open failed/n" );
        return ;
    }
    x264_picture_alloc(p264Pic, X264_CSP_I420, p264Param->i_width, p264Param->i_height);
    p264Pic->i_type = X264_TYPE_AUTO;
}

- (void)initRTMPWithURL:(NSURL *)url {
    NSString *urlString = url.absoluteString;
    char *cString = [urlString cStringUsingEncoding:NSASCIIStringEncoding];
    
    rtmp = RTMP_Alloc();
    RTMP_Init(rtmp);
    RTMP_SetupURL(rtmp, cString);
    RTMP_EnableWrite(rtmp);
    
    if(!RTMP_Connect(rtmp, NULL)) {
        return;
    }
    
    if (!RTMP_ConnectStream(rtmp, 0)) {
        return;
    }
}

//- (void)initForFilePath{
//    char *path = [self GetFilePathByfileName:"IOSCamDemo.h264"];
//    NSLog(@"%s",path);
//    fp = fopen(path,"wb");
//}

- (char*)GetFilePathByfileName:(char*)filename

{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *strName = [NSString stringWithFormat:@"%s",filename];
    
    NSString *writablePath = [documentsDirectory stringByAppendingPathComponent:strName];
    
    int len = [writablePath length];
    
    char *filepath = (char*)malloc(sizeof(char) * (len + 1));
    
    [writablePath getCString:filepath maxLength:len + 1 encoding:[NSString defaultCStringEncoding]];
    
    return filepath;
}

- (void)encoderToH264:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    uint8_t  *baseAddress0 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t  *baseAddress1 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    
    int         i264Nal;
    x264_picture_t pic_out;
    
    memcpy(p264Pic->img.plane[0], baseAddress0, 352*288);
    uint8_t * pDst1 = p264Pic->img.plane[1];
    uint8_t * pDst2 = p264Pic->img.plane[2];
    for( int i = 0; i < 352*288/4; i ++ )
    {
        *pDst1++ = *baseAddress1++;
        *pDst2++ = *baseAddress1++;
    }
    
    x264_encoder_encode( p264Handle, &p264Nal, &i264Nal, p264Pic ,&pic_out);
    
    int i, last;
    for (i = 0,last = 0;i < i264Nal; i++) {
        if (p264Nal[i].i_type == NAL_SPS) {
            
            sps_len = p264Nal[i].i_payload-4;
            NSLog(@"sps: %s sps_len: %d", sps, sps_len);
            memcpy(sps, p264Nal[i].p_payload+4, sps_len);
            
        } else if (p264Nal[i].i_type == NAL_PPS) {
            
            pps_len = p264Nal[i].i_payload-4;
            NSLog(@"pps: %s pps_len: %d", pps, pps_len);
            memcpy(pps, p264Nal[i].p_payload+4, pps_len);
            
            /*发送sps pps*/
            send_video_sps_pps(rtmp);
            
        } else {
            
            /*发送普通帧*/
            send_rtmp_video(p264Nal[i].p_payload, p264Nal[i].i_payload, rtmp);
        }
        last += p264Nal[i].i_payload;
    }
    
//    NSLog(@"i264Nal======%d",i264Nal);
//    
//    if (i264Nal > 0) {
//        
//        int i_size;
//        char * data=(char *)szBodyBuffer+100;
//        for (int i=0 ; i<i264Nal; i++) {
//            if (p264Handle->nal_buffer_size < p264Nal[i].i_payload*3/2+4) {
//                p264Handle->nal_buffer_size = p264Nal[i].i_payload*2+4;
//                x264_free( p264Handle->nal_buffer );
//                p264Handle->nal_buffer = x264_malloc( p264Handle->nal_buffer_size );
//            }
//            i_size = p264Nal[i].i_payload;
//            
//            memcpy(data, p264Nal[i].p_payload, p264Nal[i].i_payload);
//            fwrite(data, 1, i_size, fp);
//        }
//        
//    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

@end
