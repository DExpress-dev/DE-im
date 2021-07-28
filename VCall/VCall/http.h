//
//  http.h
//  Demo
//
//  Created by fxh7622 on 2020/9/6.
//  Copyright © 2020 Jessonliu. All rights reserved.
//

#ifndef http_h
#define http_h

#import <Foundation/Foundation.h>
#import <stdio.h>

@interface http_client : NSObject
{
}

@property (nonatomic , assign) bool auth_result_;
@property (nonatomic , assign) bool setStream_result_;
@property (nonatomic , assign) bool getStream_result_;

/*解析出来的数据*/

//返回值
@property (nonatomic, assign) NSInteger response_result;     //音频采样率;

//用户参数
@property (nonatomic, retain) NSString *roomName;           //音频采样率;
@property (nonatomic, retain) NSString *passWd;             //
@property (nonatomic, retain) NSString *userName;           //
@property (nonatomic, retain) NSString *user_ip;           //

//音视频参数
@property (nonatomic, retain) NSString *media_remote_ip;    //音视频服务器的远端ip地址
@property (nonatomic, assign) NSInteger media_remote_port;  //音视频服务器的远端端口
@property (nonatomic, assign) Float32 media_rate;           //音视频服务器的码率

//音频参数
@property (nonatomic, assign) UInt32 audio_sample_rate;     //音频采样率;
@property (nonatomic, assign) UInt32 audio_channels;        //此处必须为1，要不然会越界;
@property (nonatomic, assign) UInt32 audio_perchannel;      //注意此处必须为16，要不然无法播放音频，不要问我为什么，我也不知道;
@property (nonatomic, assign) UInt32 audio_buffer_size;     //音频采集buffer大小;
@property (nonatomic, assign) Float32 audio_size;           //

//视频参数
@property (nonatomic, assign) UInt32 frame_size;            //
@property (nonatomic, assign) UInt32 fps;                   //视频帧率;

//用户认证
-(bool)loginRoom :(NSString*)roomName   //房间名称
                 :(NSString*)passWd     //房间密码
                 : (NSString*)userName; //用户名称

//设置用户流信息
-(bool)setStream :(NSString*)uid        //用户id
                 :(NSString*)session    //用户登录分配的session
                 :(NSString*)key;       //用户的音视频加密key

//获取用户流信息
-(bool)getStream :(NSString*)uid        //用户id
                 :(NSString*)session    //用户登录后分配的session
                 :(NSString*)destUid    //想获取的目的用户id
                 :(NSString*)key;       //获取的目的用户视频加密key

//用户保活信息
-(void)keepAlive:(NSString*)roomName    //房间名称
                :(NSString*)userName;   //用户名称


@end

#endif /* http_h */
