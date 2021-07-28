//
//  audio_play.h
//  audio_play
//
//  Created by fxh7622 on 17/3/19.
//  Copyright © 2017年 张大圣. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

//音频播放位置;
typedef NS_ENUM(NSInteger, play_type)
{
    pt_headset = 0,    //耳机播放;
    pt_speaker = 1     //扬声器播放;
};

//音频播放;
@interface audioPlay : NSObject
{
}

//****处理pcm数据;
//启动播放; sampleRate: 采样率; channels: 声道; perChannel: 每个采样点16bit量化;
-(void)audioPlayer:(UInt32)sampleRate :(UInt32)channels :(UInt32)perChannel :(play_type)playType :(Float32)frameSize;

//停止播放;
-(void)audioStoper;

//清空队列;
-(void)audioCleanup;

//播放声音;
//buffer: 需要播放的音频数据;
-(void)addBuffer:(void*)buffer :(int)size;


@end




