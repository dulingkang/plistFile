//
//  RWFile.m
//  RWFile
//
//  Created by 崔峰 on 15/6/27.
//  Copyright (c) 2015年 SmarterEye. All rights reserved.
//

#import "RWFile.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>


static RWFile *rwFile = nil;

@implementation RWFile

+ (RWFile *)sharedRWFile
{
    if (rwFile == nil)
    {
        rwFile = [[RWFile alloc] init];
    }
    return rwFile;
}

- (id)init
{
    if (self = [super init])
    {
        _dataArray = [[NSMutableArray alloc] initWithCapacity:0];
        _path = [NSString stringWithString:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] ];
        
        _plistPath = [_path stringByAppendingPathComponent:@"count.plist"];
        
        _path = [_path stringByAppendingPathComponent:@"RWFile"];
        [self isExistPath:_path];
    }
    _index = [_dataArray count];

    return self;
}

- (BOOL)isExistPath:(NSString *)path
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil])
        {
            NSLog(@"ciritcal error! cannot create folder");
            return YES;
        }
    }
    return NO;
}


- (BOOL)storeData:(NSData *)data
{
    NSString *path = [NSString stringWithString:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] ];
    
    path = [path stringByAppendingPathComponent:@"RWFile"];
    NSString *name = [NSString stringWithFormat:@"%ld.data", (long)_index];
    NSString *dataPath = [path stringByAppendingPathComponent:name];
    for (NSString *tmpPath in _dataArray) {
        if (tmpPath == dataPath) {
            dataPath = [dataPath stringByAppendingString:@"copy"];
        }
    }
    [data writeToFile:dataPath atomically:YES];
    [_dataArray addObject:dataPath];
    _index++;
    //[self saveCountToPlist:_index];
    return YES;
}

//- (void)saveCountToPlist:(id)count
//{
//    NSFileManager *fm = [NSFileManager defaultManager];
//    if (![fm fileExistsAtPath:_plistPath]){
//        if(![fm createFileAtPath:_plistPath contents:nil attributes:nil])
//        {
//            NSLog(@"create error");
//        }
//        else
//        {
//            NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:0, @"count", nil];
//            [dataDict writeToFile:_plistPath atomically:YES];
//        }
//    }
//    else {
//        NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithContentsOfFile:_plistPath];
//        NSInteger intCount = [dict objectForKey:@"count"];
//        NSString *stringCount = [NSString stringWithFormat:@"%s",intCount];
//        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"count", nil];
//        [dict writeToFile:_plistPath atomically:YES];
//    }
//    
//}

- (NSData *)getOneData:(NSInteger)index
{
    NSData *returnData = nil;
    if (_dataArray != nil && [_dataArray count] > 0) {
        NSString *path = [_dataArray objectAtIndex:index];
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:path])
        {
            returnData = [NSData dataWithContentsOfFile:path];
        }
    }
    return returnData;
}

+ (UIImage *)generateImageFromData:(unsigned char *)imgPixelData
                 withImgPixelWidth:(NSUInteger) imgPixelWidth
                withImgPixelHeight:(NSUInteger)imgPixelHeight
{
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imgPixelData, imgPixelWidth * imgPixelHeight * 4, NULL);
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = (int)(4 * imgPixelWidth);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(imgPixelWidth, imgPixelHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    
    CFRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    return finalImage;
}


+ (void)imageViewAutoLayout:(UIImageView *)imageView withImage:(UIImage *)image withWidth:(float)width withHeight:(float)height
{
    [imageView setTranslatesAutoresizingMaskIntoConstraints:YES];
    imageView.frame = CGRectMake(Left_Margin, 0, width,height);
    imageView.backgroundColor = [UIColor clearColor];
    
    float imgViewScale = imageView.frame.size.height/imageView.frame.size.width;
    float imgScale = image.size.height/image.size.width;
    float imgNowWidth;
    float imgNowHeight;
    
    if(image)
    {
        if(image.size.width >= imageView.frame.size.width || image.size.height >= imageView.frame.size.height)
        {
            if(imgScale >imgViewScale)
            {
                imgNowHeight = imageView.frame.size.height;
                imgNowWidth = imgNowHeight/imgScale;
                
                imageView.frame = CGRectMake((WIDTH - imgNowWidth)/2, Top_View_Height, imgNowWidth, imgNowHeight);
                imageView.image = image;
                
            }
            else if (imgScale == imgViewScale)
            {
                CGRect frame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, imageView.frame.size.width, imageView.frame.size.height);
                imageView.image = image;
            }
            else//imgScale < imgViewScale
            {
                imgNowWidth = imageView.frame.size.width;
                imgNowHeight = imgNowWidth * imgScale;
                
                imageView.frame = CGRectMake(Left_Margin, (height - imgNowHeight)/2 + Top_View_Height, imgNowWidth, imgNowHeight);
                imageView.image = image;
            }
        }
        else//image size is smaller than imgview
        {
            CGFloat width=imageView.frame.size.width;
            CGFloat height=width*(image.size.height/image.size.width);
            image=[RWFile scaleToSize:image size:CGSizeMake(width, height)];
            imageView.frame = CGRectMake((WIDTH-image.size.width)/2, (height - image.size.height)/2 + Top_View_Height , image.size.width, image.size.height);
            imageView.image = image;
        }
    }
}

+ (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size{
    
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [img drawInRect:CGRectMake(0,0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage =UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    //返回新的改变大小后的图片
    return scaledImage;
}



@end
