//
//  RWFile.h
//  RWFile
//
//  Created by 崔峰 on 15/6/27.
//  Copyright (c) 2015年 SmarterEye. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define BOTTOM_VIEW_HEIGHT 70
#define Top_View_Height 54
#define Left_Margin 10
#define Right_Margin 10
#define WIDTH  [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

@interface RWFile : NSObject

@property (nonatomic, strong) NSString *plistPath;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSMutableArray *dataArray;

+ (RWFile *)sharedRWFile;
- (BOOL)storeData:(NSData *)data;
- (NSData *)getOneData:(NSInteger)index;
+ (UIImage *)generateImageFromData:(unsigned char *)imgPixelData
                 withImgPixelWidth:(NSUInteger) imgPixelWidth
                withImgPixelHeight:(NSUInteger)imgPixelHeight;
+ (void)imageViewAutoLayout:(UIImageView *)imageView withImage:(UIImage *)image withWidth:(float)width withHeight:(float)height;

@end
