//
//  codec_lib.h
//  codec_lib
//
//  Created by 崔峰 on 15/6/26.
//  Copyright (c) 2015年 崔峰. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface codec_lib : NSObject


////////////////// Anti Shaking //////////////////
-(int)AntiShaking_Create: (int)width h_size:(int)height;

/*
 Return value:
 -1: Error
 0: no frame ready.
 1: 1 frame ready to get from pDes.
 */
-(int)AntiShaking_Process: (unsigned char*)pSrc des_buf:(unsigned char*)pDes;

-(void)AntiShaking_Destroy;



////////////////// Low Light and image beautify //////////////////
-(int)LowLight_ImageBeautify_Create: (int)width h_size:(int)height;

/*
 Return value:
 -1: Error
 1: 1 frame ready to get from pDes.
 */
-(int)LowLight_ImageBeautify_Process: (unsigned char*)pSrc des_buf:(unsigned char*)pDes;

-(void)LowLight_ImageBeautify_Destroy;

@end