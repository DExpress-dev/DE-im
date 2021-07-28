//
//  capture_session.h
//  capture_session sdk
//
//  Created by fxh7622 iOS on 2017/2/9.
//  Copyright © 2017年 fxh7622. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

//分辨率的大小;
typedef NS_ENUM(NSUInteger, capture_window)
{
    //低分辨率;
    capture_window_640x480 = 0,
    //中分辨率;
    capture_window_960x540 = 1,
    //高分辨率;
    capture_window_1280x720 = 2,
    //超高分辨率(注意：此分辨率在6p下只能使用后置摄像头);
    capture_window_1920x1080 = 3
};

//采集摄像头位置;
typedef NS_ENUM(NSInteger, capture_position)
{
    front_camera = 0,  //前置摄像头;
    back_camera        //后置摄像头;
};

@protocol capture_beautiful_impl_delegate <NSObject>

//视频取样数据回调 sampleBuffer:采集到的视频数据;
- (void)videoOutput:(CVPixelBufferRef)pixelBuffer;

//音频取样数据回调 sampleBuffer:采集到的音频数据(此处注意类型和视频类型不相同);
- (void)audioOutput:(AudioQueueBufferRef)sampleBuffer :(int64_t)currPts;

@end


@interface capture_beautiful : NSObject

//展示视频图像的试图;
@property (nonatomic, assign) id <capture_beautiful_impl_delegate> delegate;

- (instancetype)default_capture_session;

//****主要的提供函数****//

//初始化视频采集器
//capture_position:采集视频使用的摄像头;
//capture_window:采集大小;
//useBeautiful:是否使用美颜采集;
//sample_rate:采样率;
//channels:声道 1:单声道；2:立体声;
//per_channel:语音每采样点占用位数[8/16/24/32];
- (bool)initVideoCapture:(capture_position)videoDevicePosition
                        :(capture_window)videoWindow
                        :(BOOL)useBeautiful
                        :(UInt32)sampleRate
                        :(UInt32)channels
                        :(UInt32)perChannel
                        :(UInt32)frameSize;

//开始视频采集;
- (void)startCapture;

//停止视频采集;
- (void)stopCapture;

//****提供的相关函数****//
//监测是否具有视频权限;
//返回值:是否具有视频权限;
- (BOOL)checkVideoAuth;

//监测音频权限;
//返回值:是否具有音频权限;
- (BOOL)checkAudioAuth;

//切换摄像头;
//videoDevicePosition:切换后的摄像头位置;
- (void)setVideoPosition:(capture_position)videoDevicePosition;

//得到目前采集使用的宽度和高度 width:得到目前采集视频使用的宽度; height:得到目前采集视频使用的高度;
-(void)getWidthHeight:(int *)width height:(int *)height;

@end
