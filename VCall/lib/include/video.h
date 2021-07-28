//
//  video_encoder.h
//  video_encoder
//
//  Created by fxh7622 on 17/3/19.
//  Copyright © 2017年 张大圣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>

//视频编解码透出类;
@protocol video_encoder_impl_delegate <NSObject>

-(void)set_video_encode:(uint8_t *)frame withSize:(uint32_t)frameSize;
-(void)video_encodeing:(uint8_t *)frame
              withSize:(uint32_t)frameSize
             keyFrames:(bool)keyFrames
             spsHeader:(int)spsHeader
            videoWidth:(int)width
           videoHeigth:(int)heigth
              videoPts:(int64_t)pts;
@end

@protocol video_decoder_impl_delegate <NSObject>
- (void)video_decoded_buffer:(NSString*)userName :(CVImageBufferRef)imageBuffer;
@end

//****视频编码类;
@interface video_encoder : NSObject
{
}
@property (weak, nonatomic) id<video_encoder_impl_delegate> delegate;    //编码使用的显示对象;

//初始化视频编码器 width: 采集器采集到的视频宽度，以像素为单位 height: 采集器采集到的视频高度，以像素为单位 fps: 帧速率 bt: 码率;
//返回值: 是否创建编码器成功，成功则返回yes;
- (BOOL) initEncoder:(int)width height:(int)height fps:(int)fps bite:(int)bt;

//对视频数据进行编码 pixelBuffer: 需要编码的视频数据;
- (void) videoEncoderBeautify:(CVPixelBufferRef)pixelBuffer :(int64_t)pts;

//对视频数据进行编码 sampleBuffer: 需要编码的视频数据;
- (void) videoEncoder:(CMSampleBufferRef)sampleBuffer;

//得到数据头的大小;
-(UInt32) getHeaderSize;

//删除编码器;
- (void) deleteEncoder;

@end


//视频解码;
@interface video_decoder : NSObject
{
}

//解码使用的显示对象;
@property (weak, nonatomic) id<video_decoder_impl_delegate> delegate;
@property (nonatomic, strong) UIView *preView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preViewLayer; // 用来展示视频的layer对象
@property (nonatomic, assign) NSString *userName;    //音视频服务器的远端ip地址

//初始化解码器;
//返回值: 初始化解码器是否成功;
-(bool)initDecoder;

-(void)setUserName:(NSString*)userName;

//设置视频的 sps和pps frame: 数据 frameSize: 数据大小;
-(void)setDecode:(uint8_t *)frame withSize:(uint32_t)frameSize;

//得到数据头的大小;
-(UInt32) getHeaderSize;

//视频解码 frame: 需要解码的数据 frameSize: 需要解码的数据大小;
-(void)decodeing:(uint8_t *)frame withSize:(uint32_t)frameSize;

@end


