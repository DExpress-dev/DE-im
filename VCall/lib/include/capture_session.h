//
//  capture_session.h
//  capture_session sdk
//
//  Created by fxh7622 iOS on 2017/2/9.
//  Copyright © 2017年 fxh7622. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, capture_session_preset)
{
    capture_session_preset_368x640 = 0, //低分辨率;
    capture_session_preset_540x960 = 1, //中分辨率;
    capture_session_preset_720x1280 = 2 //高分辨率;
};

typedef NS_ENUM(NSInteger, capture_device_position)
{
    capture_device_position_front = 0,  //前置摄像头;
    capture_device_position_back        //后置摄像头;
};

typedef NS_ENUM(NSInteger, capture_mode)
{
    normal_capture = 0,                 //普通采集;
    beautify_capture                    //美颜采集;
};

@protocol capture_session_impl_delegate <NSObject>

//视频取样数据回调 sampleBuffer:采集到的视频数据;
- (void)video_capture_output_buffer:(CMSampleBufferRef)sampleBuffer;

//音频取样数据回调 sampleBuffer:采集到的音频数据(此处注意类型和视频类型不相同);
- (void)audio_capture_output_buffer:(AudioQueueBufferRef)sampleBuffer;

//音频采样数据回调2
-(void)audio_capture_output_buffer_2:(AudioBuffer)sampleBuffer;

@end


@interface capture_session : NSObject

//展示视频图像的试图;
@property (nonatomic, strong) UIView *preView;              //普通的预览窗口;
@property (nonatomic, assign) id <capture_session_impl_delegate> delegate;

- (instancetype)default_capture_session;

//****主要的提供函数****//
//初始化;
-(bool)initSession;

//初始化视频采集器
//sessionPreset:采集视频用的大小;
//video_device_position:采集视频使用的摄像头;
//beautify_face_capture:是否使用美颜采集;
//sample_rate:采样率;
//channels:声道 1:单声道；2:立体声;
//per_channel:语音每采样点占用位数[8/16/24/32];
- (bool)initVideoCapture:(capture_session_preset)sessionPreset
                        :(capture_device_position)VideoDevicePosition
                        :(UInt32)sampleRate
                        :(UInt32)channels
                        :(UInt32)perChannel;

//开始视频采集;
- (void)startCapture;

//停止视频采集;
- (void)stopCapture;

//删除采集器;
-(void)uninitSession;

//****提供的相关函数****//
//监测是否具有视频权限;
//返回值:是否具有视频权限;
- (BOOL)checkVideoAuth;

//监测音频权限;
//返回值:是否具有音频权限;
- (BOOL)checkAudioAuth;

//切换摄像头;
//videoDevicePosition:切换后的摄像头位置;
- (void)setVideoPosition:(capture_device_position)videoDevicePosition;

//得到目前采集使用的宽度和高度 width:得到目前采集视频使用的宽度; height:得到目前采集视频使用的高度;
-(void)getWidthHeight:(int *)width height:(int *)height;

@end
