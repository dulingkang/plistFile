//
//  opencv_if.h
//  RWFile
//
//  Created by 崔峰 on 15/6/28.
//  Copyright (c) 2015年 SmarterEye. All rights reserved.
//

#ifndef __RWFile__opencv_if__
#define __RWFile__opencv_if__

#include <stdio.h>

#ifdef		__cplusplus
extern "C" {
#endif
    
#if 1
    typedef signed char         FDint8;
    typedef unsigned char       FDuint8;
    
    typedef short               FDint16;
    typedef unsigned short      FDuint16;
    
    typedef int                 FDint32;
    typedef unsigned int        FDuint32;
    
    typedef enum{
        FDERR_OK,
        FDERR_ERROR,
        FDERR_INVALID_PARAMETER,
        FDERR_OUT_OF_MEMORY
    } FDRESULT;
    
    
    typedef enum
    {
        FD_UNDEFINED     = 0x0000,
        
        FD_YUV420P       = 0x0001,
        FD_YUV420SP      = 0x0002,
        
        FD_RGB888        = 0x0010,
        
        FD_ARGB8888      = 0x0020,
        FD_RGBA8888      = 0x0021,
        FD_BGRA8888      = 0x0022,
        FD_ABGR8888      = 0x0023
    } FDColormode;
    
    


#define ANTI_SHAKING_CROP_OFFSET_DIV_FACTOR 20
    
    void rgb2yuv_convert(unsigned char *YUV, unsigned char *RGB_RAW,
                         unsigned int width, unsigned int height);
    
    void BGRA2YUV420(unsigned char* bgra_src, unsigned char* rgba_out, int width, int height);
#endif
    
    
    
    
    unsigned char* process_anti_shaking(unsigned char* bgra1, unsigned char* bgra2, unsigned char* bgra3, unsigned char* bgra4, unsigned char* bgra5, unsigned char* bgra6, unsigned char* bgra7);
    
#ifdef		__cplusplus
} 
#endif 

#endif /* defined(__RWFile__opencv_if__) */
