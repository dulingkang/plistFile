//
//  ViewController.m
//  RWFile
//
//  Created by 崔峰 on 15/6/27.
//  Copyright (c) 2015年 SmarterEye. All rights reserved.
//

#import "ViewController.h"
#import "RWFile.h"
#import "opencv_if.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    int width = 360;
    int height = 640;
#if 0
    //Input BGRA type image.
    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"bgra"];
    NSData *data = [NSData dataWithContentsOfFile:dataPath];
    //NSLog(@"stringdata:%@", data);
    const char *str = [data bytes];
#endif
    
    NSString *dataPath1 = [[NSBundle mainBundle] pathForResource:@"1" ofType:@"bgra"];
    NSData *data1 = [NSData dataWithContentsOfFile:dataPath1];
    char *bgra1 = [data1 bytes];

    
    NSString *dataPath2 = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"bgra"];
    NSData *data2 = [NSData dataWithContentsOfFile:dataPath2];
    char *bgra2 = [data2 bytes];
    
    NSString *dataPath3 = [[NSBundle mainBundle] pathForResource:@"3" ofType:@"bgra"];
    NSData *data3 = [NSData dataWithContentsOfFile:dataPath3];
    char *bgra3 = [data3 bytes];
    
    NSString *dataPath4 = [[NSBundle mainBundle] pathForResource:@"4" ofType:@"bgra"];
    NSData *data4 = [NSData dataWithContentsOfFile:dataPath4];
    char *bgra4 = [data4 bytes];
    
    NSString *dataPath5 = [[NSBundle mainBundle] pathForResource:@"5" ofType:@"bgra"];
    NSData *data5 = [NSData dataWithContentsOfFile:dataPath5];
    char *bgra5 = [data5 bytes];
    
    NSString *dataPath6 = [[NSBundle mainBundle] pathForResource:@"6" ofType:@"bgra"];
    NSData *data6 = [NSData dataWithContentsOfFile:dataPath6];
    char *bgra6 = [data6 bytes];

    NSString *dataPath7 = [[NSBundle mainBundle] pathForResource:@"7" ofType:@"bgra"];
    NSData *data7 = [NSData dataWithContentsOfFile:dataPath7];
    char *bgra7 = [data7 bytes];
    
    unsigned char* dst = process_anti_shaking(bgra1, bgra2, bgra3, bgra4, bgra5, bgra6, bgra7);
    
    //BGRA2YUV420(unsigned char* bgra_src, unsigned char* rgba_out, int width, int height);
    //unsigned char* dst = bgra1;
    //BGRA2YUV420(bgra1, dst,  width,  height);

    //RWFile * rwFile = [RWFile sharedRWFile];
//    [rwFile storeData:data];
//    NSArray *readData = [rwFile getOneData:0];
    
    
    
#if 1
    //Show RGBA type image.
    self.imageView.image = [RWFile generateImageFromData:dst  withImgPixelWidth:width withImgPixelHeight:height];
    [RWFile imageViewAutoLayout:self.imageView withImage:self.imageView.image withWidth:WIDTH-50 withHeight:HEIGHT];
#endif
    
}

@end
