//
//  opencv_if.cpp
//  RWFile
//
//  Created by 崔峰 on 15/6/28.
//  Copyright (c) 2015年 SmarterEye. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "opencv_if.h"


//Include OpenCV API.
#import <opencv2/opencv.hpp>
using namespace cv;

#if 1

/*
 * packed and tested by Peter.Xu @ 2009.8
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

class FDFrame
{
public:
    FDColormode   format;
    FDint32       width;
    FDint32       height;
    FDint32       xOffset;
    FDint32       yOffset;
    FDuint8*      data;
};

#define MY(a,b,c) (( a*  0.2989  + b*  0.5866  + c*  0.1145))
#define MU(a,b,c) (( a*(-0.1688) + b*(-0.3312) + c*  0.5000 + 128))
#define MV(a,b,c) (( a*  0.5000  + b*(-0.4184) + c*(-0.0816) + 128))


#define DY(a,b,c) (MY(a,b,c) > 255 ? 255 : (MY(a,b,c) < 0 ? 0 : MY(a,b,c)))
#define DU(a,b,c) (MU(a,b,c) > 255 ? 255 : (MU(a,b,c) < 0 ? 0 : MU(a,b,c)))
#define DV(a,b,c) (MV(a,b,c) > 255 ? 255 : (MV(a,b,c) < 0 ? 0 : MV(a,b,c)))

void rgb2yuv_convert(unsigned char *YUV, unsigned char *RGB_RAW,
                     unsigned int width, unsigned int height)
{
    unsigned int i,x,y,j;
    unsigned char *Y = NULL;
    unsigned char *U = NULL;
    unsigned char *V = NULL;
    char temp;
    
    unsigned char *RGB = RGB_RAW + 0;
    //unsigned char *RGB = RGB_RAW + 54;   ////??????????
    unsigned char *tmp_buf;
    //int line_width = width * 3;
    int line_width = width * 4;
    
    tmp_buf = (unsigned char*)malloc(line_width);
    
    for(i = 0, j = height - 1; i < j; i++, j--){
        memcpy(tmp_buf, RGB + i * line_width, line_width);
        memcpy(RGB + i * line_width, RGB + j * line_width, line_width);
        memcpy(RGB + j * line_width, tmp_buf, line_width);
    }
    //椤哄簭璋冩暣
    //for(i=0; (unsigned int)i < width*height*3; i+=3)
    for(i=0; (unsigned int)i < width*height*4; i+=4)
    {
        temp = RGB[i];
        RGB[i] = RGB[i+2];
        RGB[i+2] = temp;
    }
    i = j = 0;
    
    Y = YUV;
    U = YUV + width*height;
    V = U + ((width*height)>>2);
    
    for(y=0; y < height; y++)
        for(x=0; x < width; x++)
        {
            j = y*width + x;
            i = j*3;
            Y[j] = (unsigned char)(DY(RGB[i], RGB[i+1], RGB[i+2]));
            
            if(x%2 == 1 && y%2 == 1)
            {
                j = (width>>1) * (y>>1) + (x>>1);
                //涓婇潰i浠嶆湁鏁�
                U[j] = (unsigned char)
                ((DU(RGB[i  ], RGB[i+1], RGB[i+2]) +
                  DU(RGB[i-3], RGB[i-2], RGB[i-1]) +
                  DU(RGB[i  -width*3], RGB[i+1-width*3], RGB[i+2-width*3]) +
                  DU(RGB[i-3-width*3], RGB[i-2-width*3], RGB[i-1-width*3]))/4);
                
                V[j] = (unsigned char)
                ((DV(RGB[i  ], RGB[i+1], RGB[i+2]) +
                  DV(RGB[i-3], RGB[i-2], RGB[i-1]) +
                  DV(RGB[i  -width*3], RGB[i+1-width*3], RGB[i+2-width*3]) +
                  DV(RGB[i-3-width*3], RGB[i-2-width*3], RGB[i-1-width*3]))/4);
            }
            
        }
    free(tmp_buf);
}


void image_stabilization_compensation(unsigned char* des_buf, FDFrame* frame)
{
    int i;
    int left, right;
    int up, down;
    unsigned char* src = NULL;
    unsigned char* des = NULL;
    
    int input_width = frame->width;
    int input_height = frame->height;
    int input_y_length = input_width*input_height;
    
    int input_width_uv = frame->width>>1;
    int input_height_uv = frame->height>>1;
    int input_u_lenght = input_width_uv*input_height_uv;
    
    int frame_offset_x = frame->xOffset;  //Get frame shaking offset.
    int frame_offset_y = frame->yOffset;
    int offset_x_max = ((input_width/ANTI_SHAKING_CROP_OFFSET_DIV_FACTOR)/2)*2;  //Get the max shaking range.
    int offset_y_max = ((input_height/ANTI_SHAKING_CROP_OFFSET_DIV_FACTOR)/2)*2;
    
    printf("image_stabilization_compensation offset=%d*%d, max=%d*%d, input %d*%d \n", frame_offset_x, frame_offset_y, offset_x_max, offset_y_max, input_width, input_height);
    /* Set the offset in the new area. */
    if(frame_offset_x > offset_x_max)
        frame_offset_x = offset_x_max;
    else if(frame_offset_x < -offset_x_max)
        frame_offset_x = -offset_x_max;
    
    if(frame_offset_y > offset_y_max)
        frame_offset_y = offset_y_max;
    else if(frame_offset_y < -offset_y_max)
        frame_offset_y = -offset_y_max;
    
    frame_offset_x = (frame_offset_x/2)*2;  //Get new frame shaking offset.
    frame_offset_y = (frame_offset_y/2)*2;
    printf("image_stabilization_compensation actual offset=%d*%d\n", frame_offset_x, frame_offset_y);
    
    
    //Part0:
    /*If no shaking detected, just copy the src data to destination buffer. Then return.*/
    src = (unsigned char*)frame->data;
    des = des_buf;
    if((0 == frame_offset_x)&&(0 == frame_offset_y))
    {
        printf("image_stabilization_compensation Part0: no shaking \n");
        memcpy(des, src, input_u_lenght + input_u_lenght*2);
        return;
    }
    
    
    //Part1:
    /* x,y both minus shaking. Top left area. */
    if((frame_offset_x<=0)&&(frame_offset_y<=0))
    {
        left = -frame_offset_x;
        right = input_width-left;
        up = -frame_offset_y;
        down = input_height-up;
        printf("image_stabilization_compensation Part1: Top left . left, right=%d*%d, up, down=%d*%d\n", left, right, up, down);
        
        /****Copy Y data****/
        src = (unsigned char*)frame->data;
        des = des_buf+left;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width;
        }
        
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width;
            src += input_width;
        }
        
        src = des_buf+left;
        des = des_buf;
        for(i=0; i<input_height; i++)
        {
            memcpy(des, src, left);
            des += input_width;
            src += input_width;
        }
        
        
        left = left>>1;
        right = right>>1;
        up = up>>1;
        down = down>>1;
        /****Copy U data****/
        src = (unsigned char*)frame->data + input_y_length;
        des = des_buf + input_y_length + left;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
        }
        
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        src = des_buf + input_y_length + left;
        des = des_buf + input_y_length;
        for(i=0; i<input_height_uv; i++)
        {
            memcpy(des, src, left);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        /****Copy V data****/
        src = (unsigned char*)frame->data + input_y_length + input_u_lenght;
        des = des_buf + input_y_length + input_u_lenght + left;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
        }
        
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        src = des_buf + input_y_length + input_u_lenght + left;
        des = des_buf + input_y_length + input_u_lenght;
        for(i=0; i<input_height_uv; i++)
        {
            memcpy(des, src, left);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        return;
    }
    
    
    //Part2:
    /* x<=0,y>=0. Bottom left area. */
    if((frame_offset_x<=0)&&(frame_offset_y>=0))
    {
        left = -frame_offset_x;
        right = input_width-left;
        up = frame_offset_y;
        down = input_height-up;
        printf("image_stabilization_compensation Part2: Bottom left. left, right=%d*%d, up, down=%d*%d\n", left, right, up, down);
        
        /****Copy Y data****/
        src = (unsigned char*)frame->data + input_width*up;
        des = des_buf+left;
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width;
            src += input_width;
        }
        
        src -= input_width;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width;
        }
        
        src = des_buf+left;
        des = des_buf;
        for(i=0; i<input_height; i++)
        {
            memcpy(des, src, left);
            des += input_width;
            src += input_width;
        }
        
        
        left = left>>1;
        right = right>>1;
        up = up>>1;
        down = down>>1;
        /****Copy U data****/
        src = (unsigned char*)frame->data + input_y_length + input_width_uv*up;
        des = des_buf + input_y_length + left;
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        src -= input_width_uv;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
        }
        
        src = des_buf+input_y_length+left;
        des = des_buf+input_y_length;
        for(i=0; i<input_height_uv; i++)
        {
            memcpy(des, src, left);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        
        /****Copy V data****/
        src = (unsigned char*)frame->data + input_y_length + input_u_lenght + input_width_uv*up;
        des = des_buf + input_y_length + input_u_lenght + left;
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        src -= input_width_uv;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
        }
        
        src = des_buf + input_y_length + input_u_lenght + left;
        des = des_buf + input_y_length + input_u_lenght;
        for(i=0; i<input_height_uv; i++)
        {
            memcpy(des, src, left);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        return;
    }
    
    
    //Part3:
    /* x>=0,y>=0. Bottom right area. */
    if((frame_offset_x>=0)&&(frame_offset_y>=0))
    {
        left = frame_offset_x;
        right = input_width-left;
        up = frame_offset_y;
        down = input_height-up;
        printf("image_stabilization_compensation Part3: Bottom right. left, right=%d*%d, up, down=%d*%d\n", left, right, up, down);
        
        /****Copy Y data****/
        src = (unsigned char*)frame->data + input_width*up + left;
        des = des_buf;
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width;
            src += input_width;
        }
        
        src -= input_width;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width;
        }
        
        src = des_buf + input_width - left*2;
        des = des_buf + input_width - left;
        for(i=0; i<input_height; i++)
        {
            memcpy(des, src, left);
            des += input_width;
            src += input_width;
        }
        
        
        left = left>>1;
        right = right>>1;
        up = up>>1;
        down = down>>1;
        /****Copy U data****/
        src = (unsigned char*)frame->data + input_y_length + input_width_uv*up + left;
        des = des_buf + input_y_length;
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        src -= input_width_uv;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
        }
        
        src = des_buf + input_y_length + input_width_uv - left*2;
        des = des_buf + input_y_length + input_width_uv - left;
        for(i=0; i<input_height_uv; i++)
        {
            memcpy(des, src, left);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        /****Copy V data****/
        src = (unsigned char*)frame->data + input_y_length + input_u_lenght + input_width_uv*up + left;
        des = des_buf + input_y_length + input_u_lenght;
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        src -= input_width_uv;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
        }
        
        src = des_buf + input_y_length + input_u_lenght + input_width_uv - left*2;
        des = des_buf + input_y_length + input_u_lenght + input_width_uv - left;
        for(i=0; i<input_height_uv; i++)
        {
            memcpy(des, src, left);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        return;
    }
    
    
    //Part4:
    /* x>=0,y<=0. Top right area. */
    if((frame_offset_x>=0)&&(frame_offset_y<=0))
    {
        left = frame_offset_x;
        right = input_width-left;
        up = -frame_offset_y;
        down = input_height-up;
        printf("image_stabilization_compensation Part4: Top right. left, right=%d*%d, up, down=%d*%d\n", left, right, up, down);
        
        /****Copy Y data****/
        src = (unsigned char*)frame->data + left;
        des = des_buf;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width;
        }
        
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width;
            src += input_width;
        }
        
        src = des_buf + input_width - left*2;
        des = des_buf + input_width - left;
        for(i=0; i<input_height; i++)
        {
            memcpy(des, src, left);
            des += input_width;
            src += input_width;
        }
        
        
        left = left>>1;
        right = right>>1;
        up = up>>1;
        down = down>>1;
        /****Copy U data****/
        src = (unsigned char*)frame->data + input_y_length + left;
        des = des_buf + input_y_length;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
        }
        
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        src = des_buf + input_y_length + input_width_uv - left*2;
        des = des_buf + input_y_length + input_width_uv - left;
        for(i=0; i<input_height_uv; i++)
        {
            memcpy(des, src, left);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        /****Copy V data****/
        src = (unsigned char*)frame->data + input_y_length + input_u_lenght + left;
        des = des_buf + input_y_length + input_u_lenght;
        for(i=0; i<up; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
        }
        
        for(i=0; i<down; i++)
        {
            memcpy(des, src, right);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        src = des_buf + input_y_length + input_u_lenght + input_width_uv - left*2;
        des = des_buf + input_y_length + input_u_lenght + input_width_uv - left;
        for(i=0; i<input_height_uv; i++)
        {
            memcpy(des, src, left);
            des += input_width_uv;
            src += input_width_uv;
        }
        
        return;
    }
}



#define RGBA_BPP 4
void BGRA2YUV420(unsigned char* bgra_src, unsigned char* rgba_out, int width, int height)
{
    unsigned char* yuv420 = new unsigned char [width*height*2];
    Mat img_src(height, width, CV_8UC4, bgra_src, width*RGBA_BPP);
    Mat yuv_des;
    cvtColor(img_src, yuv_des, CV_BGRA2YUV_I420);
    
    FDFrame frame;
    frame.data = yuv_des.data;
    frame.width = width;
    frame.height = height;
    
    int offset = 9;
    frame.xOffset = offset;
    frame.yOffset = -32;
    
    
    image_stabilization_compensation(yuv420, &frame);
    
    Mat img_out_rgba(height, width, CV_8UC4, rgba_out, width*RGBA_BPP);
    Mat img_yuv_out(height*3/2, width, CV_8UC1, yuv420, width);
    cvtColor(img_yuv_out, img_out_rgba, CV_YUV2RGBA_I420);
    
    return;
}
#endif

#ifndef RGBA_BPP
#define RGBA_BPP 4
#endif

#import "codec_lib.h"


unsigned char* process_anti_shaking(unsigned char* bgra1, unsigned char* bgra2, unsigned char* bgra3, unsigned char* bgra4, unsigned char* bgra5, unsigned char* bgra6, unsigned char* bgra7)
{
    int width = 360;
    int height = 640;
    
    Mat img_src1(height, width, CV_8UC4, bgra1, width*RGBA_BPP);
    Mat img_src2(height, width, CV_8UC4, bgra2, width*RGBA_BPP);
    Mat img_src3(height, width, CV_8UC4, bgra3, width*RGBA_BPP);
    Mat img_src4(height, width, CV_8UC4, bgra4, width*RGBA_BPP);
    Mat img_src5(height, width, CV_8UC4, bgra5, width*RGBA_BPP);
    Mat img_src6(height, width, CV_8UC4, bgra6, width*RGBA_BPP);
    Mat img_src7(height, width, CV_8UC4, bgra7, width*RGBA_BPP);
    Mat yuv_src1;
    Mat yuv_src2;
    Mat yuv_src3;
    Mat yuv_src4;
    Mat yuv_src5;
    Mat yuv_src6;
    Mat yuv_src7;
    cvtColor(img_src1, yuv_src1, CV_BGRA2YUV_I420);
    cvtColor(img_src2, yuv_src2, CV_BGRA2YUV_I420);
    cvtColor(img_src3, yuv_src3, CV_BGRA2YUV_I420);
    cvtColor(img_src4, yuv_src4, CV_BGRA2YUV_I420);
    cvtColor(img_src5, yuv_src5, CV_BGRA2YUV_I420);
    cvtColor(img_src6, yuv_src6, CV_BGRA2YUV_I420);
    cvtColor(img_src7, yuv_src7, CV_BGRA2YUV_I420);
    
    unsigned char* out1 = new unsigned char [width*height*2];
    unsigned char* out2 = new unsigned char [width*height*2];
    unsigned char* out3 = new unsigned char [width*height*2];
    unsigned char* out4 = new unsigned char [width*height*2];
    unsigned char* out5 = new unsigned char [width*height*5];
    unsigned char* out6 = new unsigned char [width*height*5];
    
    
    codec_lib* zyj = [[codec_lib alloc] init];
    [zyj AntiShaking_Create:width h_size:height];
    
    int output=0;
    
    [zyj AntiShaking_Process:yuv_src1.data des_buf:out1];
    [zyj AntiShaking_Process:yuv_src2.data des_buf:out1];
    [zyj AntiShaking_Process:yuv_src3.data des_buf:out1];
    output = [zyj AntiShaking_Process:yuv_src4.data des_buf:out1];
    output = [zyj AntiShaking_Process:yuv_src5.data des_buf:out2];
    
    NSDate* tmpStartData = [NSDate date];
    output = [zyj AntiShaking_Process:yuv_src6.data des_buf:out3];
    printf("6 output=%d \n",output);
    double deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
    NSLog(@">>>>>>>>>>cost time1 = %f ms", deltaTime*1000);
    
    
    tmpStartData = [NSDate date];
    //You code here...
    [zyj AntiShaking_Process:yuv_src7.data des_buf:out4];
    deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
    NSLog(@">>>>>>>>>>cost time2 = %f ms", deltaTime*1000);
    
    [zyj AntiShaking_Destroy];
    
    
    Mat img_out_rgba(height, width, CV_8UC4, out5, width*RGBA_BPP);
    Mat img_yuv_out(height*3/2, width, CV_8UC1, out4, width);
    cvtColor(img_yuv_out, img_out_rgba, CV_YUV2RGBA_I420);

    
#if 0
    [zyj LowLight_ImageBeautify_Create:width h_size:height];
    tmpStartData = [NSDate date];
    [zyj LowLight_ImageBeautify_Process:yuv_src5.data des_buf:out6];
    deltaTime = [[NSDate date] timeIntervalSinceDate:tmpStartData];
    NSLog(@">>>>>>>>>>cost time3 = %f ms", deltaTime*1000);
    [zyj LowLight_ImageBeautify_Destroy];
    
    
    Mat img_out_rgba(height, width, CV_8UC4, out5, width*RGBA_BPP);
    Mat img_yuv_out(height*3/2, width, CV_8UC1, out6, width);
    cvtColor(img_yuv_out, img_out_rgba, CV_YUV2RGBA_I420);
#endif
    
    delete[] out1;
    delete[] out2;
    delete[] out3;
    //delete[] out4;
    
    return out5;
}


