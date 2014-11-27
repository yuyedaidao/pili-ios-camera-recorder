//
//  SpsDecode.h
//  PLRecorderKit
//
//  Created by 0day on 14/11/3.
//  Copyright (c) 2014年 qgenius. All rights reserved.
//

#ifndef __PLRecorderKit__SpsDecode__
#define __PLRecorderKit__SpsDecode__

#include <stdio.h>
#include <math.h>

typedef unsigned int UINT;
typedef unsigned char BYTE;
typedef unsigned long DWORD;

UINT Ue(BYTE *pBuff, UINT nLen, UINT &nStartBit)
{
    //计算0bit的个数
    UINT nZeroNum = 0;
    while (nStartBit < nLen * 8)
    {
        if (pBuff[nStartBit / 8] & (0x80 >> (nStartBit % 8))) //&:按位与，%取余
        {
            break;
        }
        nZeroNum++;
        nStartBit++;
    }
    nStartBit ++;
    
    
    //计算结果
    DWORD dwRet = 0;
    for (UINT i=0; i<nZeroNum; i++)
    {
        dwRet <<= 1;
        if (pBuff[nStartBit / 8] & (0x80 >> (nStartBit % 8)))
        {
            dwRet += 1;
        }
        nStartBit++;
    }
    return (1 << nZeroNum) - 1 + dwRet;
}


int Se(BYTE *pBuff, UINT nLen, UINT &nStartBit)
{
    int UeVal=Ue(pBuff,nLen,nStartBit);
    double k=UeVal;
    int nValue=ceil(k/2);//ceil函数：ceil函数的作用是求不小于给定实数的最小整数。ceil(2)=ceil(1.2)=cei(1.5)=2.00
    if (UeVal % 2==0)
        nValue=-nValue;
    return nValue;
}


DWORD u(UINT BitCount,BYTE * buf,UINT &nStartBit)
{
    DWORD dwRet = 0;
    for (UINT i=0; i<BitCount; i++)
    {
        dwRet <<= 1;
        if (buf[nStartBit / 8] & (0x80 >> (nStartBit % 8)))
        {
            dwRet += 1;
        }
        nStartBit++;
    }
    return dwRet;
}


bool h264_decode_sps(BYTE * buf,unsigned int nLen,int &width,int &height)
{
    UINT StartBit=0;
    int forbidden_zero_bit=u(1,buf,StartBit);
    int nal_ref_idc=u(2,buf,StartBit);
    int nal_unit_type=u(5,buf,StartBit);
    if(nal_unit_type==7)
    {
        int profile_idc=u(8,buf,StartBit);
        int constraint_set0_flag=u(1,buf,StartBit);//(buf[1] & 0x80)>>7;
        int constraint_set1_flag=u(1,buf,StartBit);//(buf[1] & 0x40)>>6;
        int constraint_set2_flag=u(1,buf,StartBit);//(buf[1] & 0x20)>>5;
        int constraint_set3_flag=u(1,buf,StartBit);//(buf[1] & 0x10)>>4;
        int reserved_zero_4bits=u(4,buf,StartBit);
        int level_idc=u(8,buf,StartBit);
        
        int seq_parameter_set_id=Ue(buf,nLen,StartBit);
        
        if( profile_idc == 100 || profile_idc == 110 ||
           profile_idc == 122 || profile_idc == 144 )
        {
            int chroma_format_idc=Ue(buf,nLen,StartBit);
            if( chroma_format_idc == 3 )
                int residual_colour_transform_flag=u(1,buf,StartBit);
            int bit_depth_luma_minus8=Ue(buf,nLen,StartBit);
            int bit_depth_chroma_minus8=Ue(buf,nLen,StartBit);
            int qpprime_y_zero_transform_bypass_flag=u(1,buf,StartBit);
            int seq_scaling_matrix_present_flag=u(1,buf,StartBit);
            
            int seq_scaling_list_present_flag[8];
            if( seq_scaling_matrix_present_flag )
            {
                for( int i = 0; i < 8; i++ ) {
                    seq_scaling_list_present_flag[i]=u(1,buf,StartBit);
                }
            }
        }
        int log2_max_frame_num_minus4=Ue(buf,nLen,StartBit);
        int pic_order_cnt_type=Ue(buf,nLen,StartBit);
        if( pic_order_cnt_type == 0 )
            int log2_max_pic_order_cnt_lsb_minus4=Ue(buf,nLen,StartBit);
        else if( pic_order_cnt_type == 1 )
        {
            int delta_pic_order_always_zero_flag=u(1,buf,StartBit);
            int offset_for_non_ref_pic=Se(buf,nLen,StartBit);
            int offset_for_top_to_bottom_field=Se(buf,nLen,StartBit);
            int num_ref_frames_in_pic_order_cnt_cycle=Ue(buf,nLen,StartBit);
            
            int *offset_for_ref_frame=new int[num_ref_frames_in_pic_order_cnt_cycle];
            for( int i = 0; i < num_ref_frames_in_pic_order_cnt_cycle; i++ )
                offset_for_ref_frame[i]=Se(buf,nLen,StartBit);
            delete [] offset_for_ref_frame;
        }
        int num_ref_frames=Ue(buf,nLen,StartBit);
        int gaps_in_frame_num_value_allowed_flag=u(1,buf,StartBit);
        int pic_width_in_mbs_minus1=Ue(buf,nLen,StartBit);
        int pic_height_in_map_units_minus1=Ue(buf,nLen,StartBit);
        
        width=(pic_width_in_mbs_minus1+1)*16;
        height=(pic_height_in_map_units_minus1+1)*16;
        
        return true;
    }
    else
        return false;
}

#endif /* defined(__PLRecorderKit__SpsDecode__) */
