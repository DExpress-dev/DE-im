//
//  rudp_ios.h
//  rudp_ios
//
//  Created by debug on 17/3/19.
//  Copyright © 2017年 张大圣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdio.h>

const int VCALL_BASE        = 1000;
const int VCALL_LOGIN       = VCALL_BASE + 101;
const int VCALL_CONTROL     = VCALL_BASE + 102;
const int VCALL_VIDEO       = VCALL_BASE + 103; //视频数据
const int VCALL_AUDIO       = VCALL_BASE + 104; //音频数据
const int VCALL_MEDIA       = VCALL_BASE + 105; //音视频数据
const int VCALL_HIDE        = VCALL_BASE + 106; //隐藏
const int VCALL_LOGOUT      = VCALL_BASE + 109; //下线

const int VCALL_NOITY_LOGIN = VCALL_BASE + 151; //通知有其它用户登录
const int VCALL_NOITY_VIDEO = VCALL_BASE + 152; //通知有其它用户的视频数据
const int VCALL_NOITY_AUDIO = VCALL_BASE + 153; //通知有其它用户的音频数据
const int VCALL_NOITY_MEDIA = VCALL_BASE + 154; //通知有其它用户的音视频数据
const int VCALL_NOITY_HIDE  = VCALL_BASE + 155; //通知有其它用户的隐藏
const int VCALL_NOITY_LOGOUT= VCALL_BASE + 159; //通知有其它用户退出

#pragma pack(push, 1)

struct header
{
    int protocol_id_;
};

enum Postion
{
    LEFT,
    MIDDLE,
    RIGHT
};

enum MediaHide
{
    VIDEO_HIDE,
    AUDIO_HIDE,
    MEDIA_HIDE
};

const int NAME_LEN      = 100;
struct postion_user
{
    bool hased_;
    Postion postion_;
    char usre_name_[NAME_LEN];
};

//登录请求
struct request_login
{
    char roomName_[NAME_LEN];
    char passWd_[NAME_LEN];
    char userName_[NAME_LEN];
};

//登录返回;
struct reponse_login
{
    int result_;
};

//推送其它用户
struct notify_user
{
    char usre_name_[NAME_LEN];
};

//推送下线
struct notify_logout
{
    char usre_name_[NAME_LEN];
};

//请求视频数据
struct request_video
{
    char usre_name_[NAME_LEN];
    int pts_;
    bool key_frames_;
    int sps_header_size_;
    int size_;
};

//请求音频数据
struct request_audio
{
    char usre_name_[NAME_LEN];
    int pts_;
    int size_;
};
struct request_buffer
{
    int size_;
};

//请求音视频数据
struct request_media
{
    char usre_name_[NAME_LEN];
    int size_;
};

//请求音视频数据
struct request_hide
{
    char usre_name_[NAME_LEN];
    MediaHide mode_;
    bool hide_;
};


#pragma pack(pop)

//回调接口;
@protocol ios_rudp_impl_delegate <NSObject>

//链接成功
- (void)onConnect :(char*)remote_ip
                  :(int)remote_port;

//推送用户信息
- (void)onNotifyUser:(char*)userName;

//登录返回;
- (void)onResponseLogin;

//接收视频数据
- (void)onNotifyVideo:(char*)userName
                     :(int)pts
                     :(bool)keyframe
                     :(int)sps_pps_size
                     :(int)size
                     :(char*)buffer
                     :(int)linker_handle
                     :(char*)remote_ip
                     :(int)remote_port
                     :(int)consume_timer;

//推送音频数据
- (void)onNotifyAudio:(char*)userName
                     :(int)pts
                     :(int)size
                     :(char*)buffer
                     :(int)linker_handle
                     :(char*)remote_ip
                     :(int)remote_port
                     :(int)consume_timer;

//推送隐藏
- (void)onNotifyHide:(char*)userName
                     :(MediaHide)mode
                     :(bool)hide;

//断开
-(void)onLoginout:(int)linker_handle
                 :(char*)remote_ip
                 :(int)remote_port;

//推送有用户断开
- (void)onNotifyLogout:(char*)userName;

-(void)onRto: (char*)remote_ip
            :(int)remote_port
            :(int)local_rto 
            :(int)remote_rto;

-(void)onRate :(char*)remote_ip
                :(int)remote_port
              :(unsigned int)send_rate 
              :(unsigned int)recv_rate;

@end

@interface ios_rudp_linker : NSObject
{
    
}

@property (nonatomic, assign) id <ios_rudp_impl_delegate> delegate;

//启动客户端；
-(void)checkNetWorkAuth;
-(int)beginClient :(char*)remoteIp     //远端ip地址
                  :(int)remotePort    //远端端口
                  :(int)timeOut       //链接超时时长
                  :(bool)delay         //是否延迟
                  :(int)delayTimer   //延迟时长（毫秒）
                  :(bool)encrypted;

-(BOOL)Login :(char*)roomName
             :(char*)passWd
             :(char*)userName
             :(int)time_out;
-(void)Logout;
-(int)sendVideo :(char*)userName
                :(int)pts
                :(bool)keyFrames
                :(int)sps_header_size
                :(int)size
                :(char*)buffer;

-(int)sendAudio:(char*)userName
               :(int)pts
               :(int)size
               :(char*)buffer;

-(int)sendMedia:(char*)userName
               :(int)size
               :(char*)buffer;

-(int)sendHide:(char*)userName
               :(MediaHide)mode
               :(bool)hide;

-(void)closeLinker :(int)linker_handle;

@end


