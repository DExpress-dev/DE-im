//
//  ViewController.m
//  Demo
//
//  Created by Jessonliu iOS on 2017/3/30.
//  Copyright © 2017年 张大圣. All rights reserved.
//

#define PrintRect(frame) NSLog(@"X:%f,Y:%f,W:%f,H:%f",frame.origin.x,frame.origin.y,frame.size.width,frame.size.height)

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "http.h"

#include <netinet/in.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define AccountKey @"account"
#define PwdKey @"pwd"
#define RmbPwdKey @"rmb_pwd"
#define AutoLoginKey @"auto_login"

static NSString *appVersion = @"1.0.0.6";

//一些常量的定义;
const UInt32 KB             = 1024;
const UInt32 MB             = 1024 * KB;
const UInt32 TOPSCALE       = 90;
const int logoYSCALE        = 200;  //logo保存的相关位置信息
const int bottomX           = 23;   //下部的x位置
const int bottomY           = 54;
const int bottomW           = 60;
const int bottomH           = 60;
const int bottomOffset      = 45;   //下部间隔
const int bottomSpace       = 72;
const int controlInterval   = 50;
const int captureInterval   = 100;

const int accountTextX      = 50;
const int accountTextYSCALE = 500;
const int textH             = 30;
const int textInterval      = 50;
const int editWidth         = 220;

//字体大小
const float fontSize        = 13.5f;    //底部文字大小
const float welComeSize     = 15.0f;    //欢迎词大小
const float titleFontSize   = 16.0f;    //抬头文字大小
const float wifiSize        = 10.5f;    //wifi文字大小

//调试使用，输入和输出的数据;
static AudioBuffer  g_inputBuffer;
static AudioBuffer  g_outputBuffer;
static UInt32       g_inputByteSize  = 0;
static UInt32       g_outputByteSize = 0;

//**********
enum Mode{HOME, LOGIN, UPLOAD, SET};
enum State{NONE, UPLOADING, WATCHING};

//用户结构
struct User
{
    NSString *decoderUser_;             //解码用户名
    NSString *showUser_;                //显示用户名
    video_decoder *userVideoDecoder_;   //视频解码指针
    audio_decoder *userAuioDecoder_;    //音频解码指针
    audioPlay *userPlayer_;             //音频播放指针
    CGRect imageRect;                   //视频显示的位置
    UIImageView *imageView_;            //视频显示Image
    bool video_hide_;                   //隐藏视频
    bool audio_hide_;                   //隐藏音频
    bool media_hide_;                   //隐藏音视频
};

@interface WatchViewController () < capture_beautiful_impl_delegate,
                                    video_encoder_impl_delegate,
                                    video_decoder_impl_delegate,
                                    ios_rudp_impl_delegate>
{
    bool initPlayed_;
    bool sourceDown_;
    
    bool uploadClosed_;
    bool watchClosed_;
    int client_linker_handle_;
    
    UInt32 TOP;
    int logoY;
    int accountTextY;
    
    //****各种元素
    //登录界面
    UIView *loginView;
    UITextField *roomNameText;
    UITextField *passwordText;
    
    //首页界面
    UIView *homeView;
    
    //上传界面;
    UIView *uploadView;
    UIImageView *uploadLogoView;
    UIView *accountLine;
    UIButton *uploadLoginButton;
    
    UITextField *keyText;
    UIImageView *uploadImageView;
    UIImageView *closeImageView;
    UIImageView *cameraImageView;
    UIButton *videoPassWDButton;
    UIImageView *sessionIco;
    UIButton *CaptureButton;
    
    
    //设置界面;
    UIView *setView;
    UIImageView *setImageView;
    UIImageView *setLogoView;
    UIImageView *setAccoutIco;
    UIImageView *setSessionIco;
    UIImageView *setIpIco;
    UIImageView *setPortIco;
    UIImageView *setRateIco;
    
    UITextField *setAccountText;
    UITextField *setSessionText;
    UITextField *setIpText;
    UITextField *setPortText;
    UITextField *setRateText;
    
    //背景图片；
    UIView *backgroundView;
    UIImageView *backgroundImageView;
    
    //底部按钮;
    UIButton *videoBtn;
    UIButton *audioBtn;
    UIButton *uploadBtn;
    UIButton *homeBtn;
    UIButton *setBtn;
    
    //抬头文字
    UIView *titleView;
    UILabel *titleLab;
}

//sdk的相关对象;
@property (nonatomic, strong) ios_rudp_linker *client_ptr;              //客户端传输对象;
@property (nonatomic, strong) capture_beautiful *capture_session_ptr;   //美颜采集对象;
@property (nonatomic, strong) video_encoder *video_encoder_ptr;         //视频编码对象;
@property (nonatomic, strong) audio_encoder *audio_encoder_ptr;         //音频编码对象;
@property (nonatomic, assign) http_client *http_client_ptr;             //HTTP对象;
@property(retain,nonatomic) NSTimer* aliveTimer;                        //心跳时钟

//音视频使用的配置信息;
@property (nonatomic, assign) UInt32 audio_sample_rate;                 //音频采样率;
@property (nonatomic, assign) UInt32 audio_channels;                    //此处必须为1，要不然会越界;
@property (nonatomic, assign) UInt32 audio_perchannel;                  //注意此处必须为16，要不然无法播放音频，不要问我为什么，我也不知道;
@property (nonatomic, assign) UInt32 audio_buffer_size;                 //音频采集buffer大小;
@property (nonatomic, assign) Float32 audio_size;                       //
@property (nonatomic, assign) UInt32 frame_size;                        //
@property (nonatomic, assign) UInt32 fps;                               //视频帧率;

//链接音视频服务器所需的信息
@property (nonatomic, assign) NSString *media_remote_ip;                //音视频服务器的远端ip地址
@property (nonatomic, assign) NSInteger media_remote_port;              //音视频服务器的远端端口
@property (nonatomic, assign) Float32 media_rate;                       //音视频服务器的码率

//用户信息
@property (nonatomic, assign) NSString *roomName;                       //房间信息
@property (nonatomic, assign) NSString *passWd;                         //房间密码
@property (nonatomic, assign) NSString *userName;                       //用户名称
@property (nonatomic, assign) NSString *mainShowUser;                   //主显示的用户
@property (nonatomic, assign) User *leftUser;                           //左边用户
@property (nonatomic, assign) User *middleUser;                         //中间用户
@property (nonatomic, assign) User *rightUser;                          //右边用户

//采集位置（前后）和当前的模式
@property (nonatomic, assign) capture_position cur_position;            //采集设备的位置
@property (nonatomic, assign) Mode cur_mode;                            //当前模式

@property (strong, nonatomic) WKWebView *home_WebView;                  //首页展现view
@property (nonatomic, assign) UIImageView *wifiView;                    //wifi图标
@property (nonatomic, assign) UITextField *rtoText;                     //rto显示
@property (nonatomic, assign) UIImageView *rateView;                    //rate图标
@property (nonatomic, assign) UITextField *rateText;                    //速度显示

@property (nonatomic, assign) Boolean hideVideo;                        //隐藏视频
@property (nonatomic, assign) Boolean hideAudio;                        //隐藏音频
@property (nonatomic, assign) Boolean encryption;                       //传输加密

@end

@implementation WatchViewController

-(void)mathScale
{
    CGRect allRect = [ [UIScreen mainScreen]bounds];
    TOP = (allRect.size.height / 1000) * TOPSCALE;
    logoY = (allRect.size.height / 1000) * logoYSCALE;
    accountTextY = (allRect.size.height / 1000) * accountTextYSCALE;
}

//得到当前速度的string
-(NSString *)rateString: (unsigned int)rate
{
    unsigned int mb_round = 0;
    unsigned int kb_round = 0;
    unsigned int spare = rate;

    //得到MB
    if(spare >= MB)
    {
        mb_round = (spare / MB);
        spare = (spare % MB);
    }

    //得到KB
    if(spare >= KB)
    {
        kb_round = (spare / KB);
        spare = (spare % KB);
    }

    //组合;
    char speed[1024] = {0};
    if(mb_round > 0)
        sprintf(speed, "%dMB%dKB/s", mb_round, kb_round);
    else if(kb_round > 0)
        sprintf(speed, "%dKB/s", kb_round);
    else
        sprintf(speed, "%d/s", spare);

    NSString *resultString = [NSString stringWithUTF8String:speed];
    return resultString;
}


//将指定数据保存成aac文件
-(BOOL)saveAccFile:(NSString *)filePath
                  :(char*) data
{
    NSData *appendData = [NSData dataWithBytes:data length:strlen(data)];
    
    //读取原有数据;
    NSData * fileData =[NSData dataWithContentsOfFile:filePath];
    
    //定义acc数据类型
    NSMutableData * accData = [[NSMutableData alloc] init];
    
    //合并文件
    [accData appendData:fileData];
    [accData appendData:appendData];
    
    //NSMutableData是继承至NSData的所以可以调用writeToFile 把数据写入到一个指定的目录下
    return [accData writeToFile:filePath atomically:YES];
}

-(void)initShowUser{
    
    self.mainShowUser = self.userName;
    self.leftUser->showUser_ = self.leftUser->decoderUser_;
    if ([self.leftUser->decoderUser_ isEqual: @""])
        self.leftUser->imageView_.image = [UIImage imageNamed:@"hideBackground"];
    
    self.middleUser->showUser_ = self.middleUser->decoderUser_;
    if ([self.middleUser->decoderUser_ isEqual: @""])
        self.middleUser->imageView_.image = [UIImage imageNamed:@"hideBackground"];
    
    self.rightUser->showUser_ = self.rightUser->decoderUser_;
    if ([self.rightUser->decoderUser_ isEqual: @""])
        self.rightUser->imageView_.image = [UIImage imageNamed:@"hideBackground"];
}

-(void)leftClickImage{

    if ([self.mainShowUser isEqual: self.userName])
    {
        //主区域正在显示主用户（本地用户）
        self.mainShowUser = self.leftUser->decoderUser_;
        self.leftUser->showUser_ = self.userName;
    }
    else if([self.mainShowUser isEqual: self.leftUser->decoderUser_])
        [self initShowUser];
}

-(void)middleClickImage{
    
    if ([self.mainShowUser isEqual: self.userName])
    {
        //主区域正在显示主用户（本地用户）
        self.mainShowUser = self.middleUser->decoderUser_;
        self.middleUser->showUser_ = self.userName;
    }
    else if([self.mainShowUser isEqual: self.middleUser->decoderUser_])
    {
        [self initShowUser];
    }
}

-(void)rightClickImage{
    
    if ([self.mainShowUser isEqual: self.userName])
    {
        //主区域正在显示主用户（本地用户）
        self.mainShowUser = self.rightUser->decoderUser_;
        self.rightUser->showUser_ = self.userName;
    }
    else if([self.mainShowUser isEqual: self.rightUser->decoderUser_])
    {
        [self initShowUser];
    }
}

//创建用户;
-(User*) createUser:(NSString*)postion :(UIImageView *)backImage
{
    CGRect allRect = [[UIScreen mainScreen]bounds];
    
    int showWidth = allRect.size.width;
    const int widthInterval = 10;
    int singleWidth = (showWidth - 6 * widthInterval) / 3;
    int singleHeight = (singleWidth * 4) / 3;
    int singleTop = allRect.size.height - bottomSpace - singleHeight - TOP;
    
    User* userPtr = new User();
    userPtr->video_hide_ = false;
    userPtr->audio_hide_ = false;
    userPtr->media_hide_ = false;
    userPtr->decoderUser_ = @"";
    userPtr->showUser_ = @"";
    
    if([postion isEqualToString: @"Left"])
        userPtr->imageRect.origin.x = widthInterval;
    else if([postion isEqualToString: @"Middle"])
        userPtr->imageRect.origin.x = widthInterval + singleWidth + 2 * widthInterval;
    else if([postion isEqualToString: @"Right"])
        userPtr->imageRect.origin.x = widthInterval + singleWidth + 2 * widthInterval + singleWidth + 2 * widthInterval;

    userPtr->imageRect.origin.y = singleTop;
    userPtr->imageRect.size.width = singleWidth;
    userPtr->imageRect.size.height = singleHeight;
    
    //创建显示图像的Image;
    userPtr->imageView_ = [[UIImageView alloc] initWithFrame:userPtr->imageRect];
    userPtr->imageView_.image = [UIImage imageNamed:@"hideBackground"];
    userPtr->imageView_.userInteractionEnabled = YES;
    [userPtr->imageView_ setUserInteractionEnabled:YES];
    UITapGestureRecognizer *singleTap = nil;
    if([postion isEqualToString: @"Left"])
        singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(leftClickImage)];
    else if([postion isEqualToString: @"Middle"])
        singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(middleClickImage)];
    else if([postion isEqualToString: @"Right"])
        singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rightClickImage)];

    [userPtr->imageView_ addGestureRecognizer:singleTap];
    
    userPtr->imageView_.hidden = true;
    [backImage addSubview:userPtr->imageView_];
    
    //创建视频解码
    userPtr->userVideoDecoder_ = [[video_decoder alloc] init];
    userPtr->userVideoDecoder_.preView = self.view;
    userPtr->userVideoDecoder_.delegate = self;
    
    //创建音频解码
    userPtr->userAuioDecoder_ = [[audio_decoder alloc] init];
    [userPtr->userAuioDecoder_ initDecoder:self.audio_sample_rate
                                       :self.audio_channels
                                       :self.frame_size
                                       :dt_hardware];
    
    //创建播放
    userPtr->userPlayer_ = [[audioPlay alloc]init];
    [userPtr->userPlayer_ audioPlayer:self.audio_sample_rate
                                     :self.audio_channels
                                     :self.audio_perchannel
                                     :pt_speaker
                                     :self.audio_size];
    
    return userPtr;
}

//用户认证接口
-(bool)loginRoom:(NSString*)roomName
                :(NSString*)passWd
                :(NSString*)userName
{
    if(nullptr == _http_client_ptr)
        _http_client_ptr = [[http_client alloc] init];
    
    bool result = [_http_client_ptr loginRoom:roomName: passWd: userName];
    if(result)
    {
        //认证通过，获取详细的数据;
        if(_roomName == nil)
            _roomName = [[NSString alloc] init];

        _roomName = [_http_client_ptr.roomName mutableCopy];
        
        if(_passWd == nil)
            _passWd = [[NSString alloc] init];

        _passWd = [_http_client_ptr.passWd mutableCopy];
        
        if(_userName == nil)
            _userName = [[NSString alloc] init];

        _userName = [_http_client_ptr.userName mutableCopy];

        if(_media_remote_ip == nil)
            _media_remote_ip = [[NSString alloc]init];

        _media_remote_ip = [_http_client_ptr.media_remote_ip mutableCopy];
        _media_remote_port = _http_client_ptr.media_remote_port;
        _media_rate = _http_client_ptr.media_rate;
        
        _audio_sample_rate = _http_client_ptr.audio_sample_rate;
        _audio_channels = _http_client_ptr.audio_channels;
        _audio_perchannel = _http_client_ptr.audio_perchannel;
        _audio_buffer_size = _http_client_ptr.audio_buffer_size;
        _audio_size = _http_client_ptr.audio_size;
        
        _frame_size = _http_client_ptr.frame_size;
        _fps = _http_client_ptr.fps;
        
        NSLog(@"得到用户信息 roomName=%@ passWd=%@ _userName=%@ media_ip=%@ media_port=%d media_rate=%f",
              _roomName,
              _passWd,
              _userName,
              _media_remote_ip,
              (int)self.media_remote_port,
              _media_rate);
        return true;
    }
    NSLog(@"authService Failed roomName=%@ passWd=%@ userName=%@", roomName, passWd, userName);
    return false;
}

//用户获取流信息
-(bool)getStream:(NSString*)uid
                :(NSString*)session
                :(NSString*)destUid
                :(NSString*)key
{
    if(nullptr == _http_client_ptr)
        return false;
    
    bool result = [_http_client_ptr getStream:uid: session: destUid: key];
    if(result)
    {
        //认证通过，获取详细的数据;
        if(_media_remote_ip == nil)
            _media_remote_ip = [[NSString alloc]init];

        _media_remote_ip = [_http_client_ptr.media_remote_ip mutableCopy];
        _media_remote_ip =_http_client_ptr.media_remote_ip;
        _media_remote_port = _http_client_ptr.media_remote_port;
        _media_rate = _http_client_ptr.media_rate;
        
        _audio_sample_rate = _http_client_ptr.audio_sample_rate;
        _audio_channels = _http_client_ptr.audio_channels;
        _audio_perchannel = _http_client_ptr.audio_perchannel;
        _audio_buffer_size = _http_client_ptr.audio_buffer_size;
        _audio_size = _http_client_ptr.audio_size;
        
        _frame_size = _http_client_ptr.frame_size;
        _fps = _http_client_ptr.fps;
        return true;
    }
    return false;
}

//用户保活接口
-(void)keepAlive:(NSString*)uid
                :(NSString*)session
{
    if(nullptr == _http_client_ptr)
        return;
    
    [_http_client_ptr keepAlive:uid: session];
}

-(void)onClickUploadCameraImage{

    NSLog(@"点击切换摄像头按钮");
    if(_cur_position == back_camera)
    {
        [self.capture_session_ptr setVideoPosition:front_camera];
        _cur_position = front_camera;
    }
    else if(_cur_position == front_camera)
    {
        [self.capture_session_ptr setVideoPosition:back_camera];
        _cur_position = back_camera;
    }
}

-(void)closeLinker{
    
    uploadClosed_ = true;
    if(client_linker_handle_ != -1){
        [self.client_ptr closeLinker:client_linker_handle_];
        [self.capture_session_ptr stopCapture];
    }
    _rtoText.hidden = true;
    _wifiView.hidden = true;
    _rateText.hidden = true;
    _rateView.hidden = true;
    
    uploadImageView.image = [UIImage imageNamed:@"backgroundImage"];
    uploadImageView.userInteractionEnabled = YES;
}

-(void)onClickUploadCloseImage{

    NSLog(@"定义关闭按钮");
    [self closeLinker];
    uploadLogoView.hidden = false;
    uploadLoginButton.hidden = false;
    keyText.hidden = false;
    closeImageView.hidden = true;
    cameraImageView.hidden = true;
    videoPassWDButton.hidden = false;
    sessionIco.hidden = false;
    [self switchShowFrm:LOGIN];
}

//切换显示
-(void)switchShowFrm:(Mode)cur_mode
{
    switch(cur_mode)
    {
        case HOME:
        {
            homeView.hidden = false;
            loginView.hidden = true;
            uploadView.hidden = true;
            setView.hidden = true;
            titleView.hidden = false;
            
            [self setTitle:@"官 网"];
            [self showButtomButton:false];
            [self.view addSubview:homeView];
            _cur_mode = HOME;
            break;
        }
        case LOGIN:     //显示登录界面；
        {
            homeView.hidden = true;
            loginView.hidden = false;
            uploadView.hidden = true;
            setView.hidden = true;
            titleView.hidden = true;
            
            [self setTitle:@""];
            [self showButtomButton:true];
            [self.view addSubview:loginView];
            _cur_mode = LOGIN;
            break;
        }
        case UPLOAD:    //显示上传界面；
        {
            homeView.hidden = true;
            loginView.hidden = true;
            uploadView.hidden = false;
            setView.hidden = true;
            titleView.hidden = false;
            CaptureButton.hidden = false;
            cameraImageView.hidden = true;
            closeImageView.hidden = true;
            uploadLogoView.hidden = false;
            
            [self setTitle:@"采 集"];
            [self showButtomButton:false];
            [self.view addSubview:uploadView];
            [self.view addSubview:titleView];
            
            _cur_mode = UPLOAD;
            break;
        }
        case SET:       //显示设置界面；
        {
            homeView.hidden = true;
            loginView.hidden = true;
            uploadView.hidden = true;
            setView.hidden = false;
            titleView.hidden = false;
            
            [self setTitle:@"信 息"];
            [self showButtomButton:false];
            [self.view addSubview:setView];
            [self.view addSubview:titleView];
            
            //设置当前的信息
            setAccountText.text = _userName;
            setIpText.text = _media_remote_ip;
            setPortText.text = [NSString stringWithFormat: @"%d", (int)_media_remote_port];
            setRateText.text = [NSString stringWithFormat: @"%.1f MB", _media_rate];
            _cur_mode = SET;
            break;
        }
    }
}

-(void)createTitle
{
    CGRect allRect = [ [UIScreen mainScreen]bounds];
    
    //设置整体view
    CGRect titleRect;
    titleRect.origin.x = 0;
    titleRect.origin.y = 0;
    titleRect.size.width = allRect.size.width;
    titleRect.size.height = TOP;
    titleView = [[UIView alloc] initWithFrame:titleRect];

    //加载背景
    UIImageView *titleFrmImageView = [[UIImageView alloc] initWithFrame:titleRect];
    titleFrmImageView.image = [UIImage imageNamed:@"TitleImage"];
    titleFrmImageView.userInteractionEnabled = YES;
    [titleView addSubview:titleFrmImageView];
    
    //设置抬头文字
    NSString *caption = @"测试";
    UInt32 titleTop = ((TOP - 20) - titleFontSize) / 2;
    CGRect titleLabelRect = CGRectMake(0, titleTop + 20, allRect.size.width, titleFontSize);
    titleLab = [[UILabel alloc] initWithFrame:titleLabelRect];
    titleLab.text = caption;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:caption];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [paragraphStyle setLineSpacing:12];
    [attributedString addAttribute:NSParagraphStyleAttributeName
                             value:paragraphStyle
                             range:NSMakeRange(0, [caption length])];
    [attributedString addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:titleFontSize]
                             range:NSMakeRange(0, [caption length])];
    UIColor *TitleColor = [UIColor colorWithRed:255.0/255
                                          green:255.0/255
                                           blue:255.0/255
                                          alpha:1.0];
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:TitleColor
                             range:NSMakeRange(0, [caption length])];
    titleLab.attributedText = attributedString;
    [titleFrmImageView addSubview:titleLab];
    
    //rto显示效果;
    UIImage *wifiWidthImage = [UIImage imageNamed:@"Wifi"];
    CGRect wifiRect;
    wifiRect.size.width = wifiWidthImage.size.width * 0.8;
    wifiRect.size.height = wifiWidthImage.size.height * 0.8;
    wifiRect.origin.x = 10;
    wifiRect.origin.y = 25 + (((TOP - 20) - wifiRect.size.height) / 2);
    _wifiView = [[UIImageView alloc] initWithFrame:wifiRect];
    _wifiView.image = [UIImage imageNamed:@"Wifi"];
    _wifiView.hidden = true;
    [titleFrmImageView addSubview:_wifiView];
    
    NSString *rto = @"";
    CGRect rtoRect = CGRectMake(32, wifiRect.origin.y + ((wifiRect.size.height - wifiSize) / 2) + 2, 50, wifiSize);
    _rtoText = [[UITextField alloc] initWithFrame:rtoRect];
    _rtoText.text = rto;
    NSMutableAttributedString *rtoAttributedString = [[NSMutableAttributedString alloc] initWithString:rto];
    NSMutableParagraphStyle *rtoParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    rtoParagraphStyle.alignment = NSTextAlignmentLeft;
    [rtoParagraphStyle setLineSpacing:10];
        
    [rtoAttributedString addAttribute:NSParagraphStyleAttributeName
                             value:rtoParagraphStyle
                             range:NSMakeRange(0, [rto length])];
    [rtoAttributedString addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:wifiSize]
                             range:NSMakeRange(0, [rto length])];
    UIColor *rtoColor = [UIColor colorWithRed:22.0/255
                                        green:131.0/255
                                         blue:6.0/255
                                        alpha:1.0];
    [rtoAttributedString addAttribute:NSForegroundColorAttributeName
                             value:rtoColor
                             range:NSMakeRange(0, [rto length])];
    _rtoText.attributedText = rtoAttributedString;
    _rtoText.hidden = true;
    [titleFrmImageView addSubview:_rtoText];
    
    //带宽显示效果;
    UIImage *rateWidthImage = [UIImage imageNamed:@"Rate"];
    CGRect rateImageRect;
    rateImageRect.size.width = rateWidthImage.size.width * 0.8;
    rateImageRect.size.height = rateWidthImage.size.height * 0.6;
    rateImageRect.origin.x = titleRect.size.width - 80;
    rateImageRect.origin.y = wifiRect.origin.y;
    _rateView = [[UIImageView alloc] initWithFrame:rateImageRect];
    _rateView.image = [UIImage imageNamed:@"Rate"];
    _rateView.hidden = true;
    [titleFrmImageView addSubview:_rateView];
    
    NSString *rateCpation = @"200KB407";
    CGRect rateRect = CGRectMake(titleRect.size.width - 57,
                                 wifiRect.origin.y + ((wifiRect.size.height - wifiSize) / 2) + 2,
                                 50,
                                 wifiSize);
    _rateText = [[UITextField alloc] initWithFrame:rateRect];
    _rateText.text = rateCpation;
    NSMutableAttributedString *rateAttributedString = [[NSMutableAttributedString alloc] initWithString:rateCpation];
    NSMutableParagraphStyle *rateParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    rateParagraphStyle.alignment = NSTextAlignmentCenter;
    [rateParagraphStyle setLineSpacing:10];
    [rateAttributedString addAttribute:NSParagraphStyleAttributeName
                                 value:rateParagraphStyle
                                 range:NSMakeRange(0, [rateCpation length])];
    [rateAttributedString addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:wifiSize]
                             range:NSMakeRange(0, [rateCpation length])];
    UIColor *rateColor = [UIColor colorWithRed:255.0/255
                                         green:255.0/255
                                          blue:255.0/255
                                         alpha:1.0];
    [rateAttributedString addAttribute:NSForegroundColorAttributeName
                                 value:rateColor
                                 range:NSMakeRange(0, [rateCpation length])];
    _rateText.attributedText = rateAttributedString;
    _rateText.hidden = true;
    [titleFrmImageView addSubview:_rateText];
    
//    //设置分享按钮
//    UIButton *buyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    buyBtn.frame = CGRectMake(10, 35, bottomW, bottomH);
//    [buyBtn setImage:[UIImage imageNamed:@"Buy"] forState:UIControlStateNormal];
//    [self setButtonContentCenter:buyBtn];
//    [buyBtn addTarget:self action:@selector(WatchSwitchClick:) forControlEvents:UIControlEventTouchUpInside];
//    [titleFrmImageView addSubview:buyBtn];
}

-(void)setTitle:(NSString*)title
{
    titleLab.text = title;
}

-(void)setRto:(NSString*)rtoString :(NSInteger)rtoInteger
{
    // 回到主线程更新UI
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        _rtoText.text = rtoString;
        NSMutableAttributedString *rtoAttributedString = [[NSMutableAttributedString alloc] initWithString:_rtoText.text];
        NSMutableParagraphStyle *rtoParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        rtoParagraphStyle.alignment = NSTextAlignmentLeft;
        [rtoParagraphStyle setLineSpacing:10];
        [rtoAttributedString addAttribute:NSParagraphStyleAttributeName
                                    value:rtoParagraphStyle
                                    range:NSMakeRange(0, [_rtoText.text length])];
        [rtoAttributedString addAttribute:NSFontAttributeName
                                    value:[UIFont systemFontOfSize:wifiSize]
                                    range:NSMakeRange(0, [_rtoText.text length])];
        UIColor *rtoColor;
        if(rtoInteger >=0 && rtoInteger <= 100){
            rtoColor = [UIColor colorWithRed:87.0/255 green:255.0/255 blue:59.0/255 alpha:1.0];
        }else if(rtoInteger > 100 && rtoInteger < 300){
            rtoColor = [UIColor colorWithRed:241.0/255 green:255.0/255 blue:59.0/255 alpha:1.0];
        }else{
            rtoColor = [UIColor colorWithRed:255.0/255 green:59.0/255 blue:59.0/255 alpha:1.0];
        }
        [rtoAttributedString addAttribute:NSForegroundColorAttributeName
                                    value:rtoColor
                                    range:NSMakeRange(0, [_rtoText.text length])];
        _rtoText.attributedText = rtoAttributedString;
    });
}

-(void)setRate:(NSString*)rate
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        _rateText.text = rate;
        NSMutableAttributedString *rtoAttributedString = [[NSMutableAttributedString alloc] initWithString:_rateText.text];
        NSMutableParagraphStyle *rtoParagraphStyle = [[NSMutableParagraphStyle alloc] init];
        rtoParagraphStyle.alignment = NSTextAlignmentLeft;
        [rtoParagraphStyle setLineSpacing:10];
        [rtoAttributedString addAttribute:NSParagraphStyleAttributeName
                                    value:rtoParagraphStyle
                                    range:NSMakeRange(0, [_rateText.text length])];
        [rtoAttributedString addAttribute:NSFontAttributeName
                                    value:[UIFont systemFontOfSize:wifiSize]
                                    range:NSMakeRange(0, [_rateText.text length])];
        UIColor *rtoColor = [UIColor colorWithRed:255.0/255
                                            green:255.0/255
                                             blue:255.0/255
                                            alpha:1.0];
        [rtoAttributedString addAttribute:NSForegroundColorAttributeName
                                    value:rtoColor
                                    range:NSMakeRange(0, [_rateText.text length])];
        _rateText.attributedText = rtoAttributedString;
    });
}

-(void)setButtonContentCenter:(UIButton *)button
{
    CGSize imgViewSize,titleSize,btnSize;
    UIEdgeInsets imageViewEdge,titleEdge;
    CGFloat heightSpace = 10.0f;
      
    //设置按钮内边距
    imgViewSize = button.imageView.bounds.size;
    titleSize = button.titleLabel.bounds.size;
    btnSize = button.bounds.size;
      
    imageViewEdge = UIEdgeInsetsMake(heightSpace,0.0, btnSize.height -imgViewSize.height - heightSpace, - titleSize.width);
    [button setImageEdgeInsets:imageViewEdge];
    titleEdge = UIEdgeInsetsMake(imgViewSize.height +heightSpace, - imgViewSize.width, 0.0, 0.0);
    [button setTitleEdgeInsets:titleEdge];
}

//****底部按钮
//创建底部按钮
-(void)createButtomButton
{
    CGRect allRect = [ [UIScreen mainScreen]bounds];
    UIImage *butImage = [UIImage imageNamed:@"HomeButNormal"];
    int but_w = butImage.size.width;
        
    int one_x = bottomX;
    int two_x = one_x + but_w + bottomOffset;
    int three_x = two_x + but_w + bottomOffset;
    int four_x = three_x + but_w + bottomOffset;
    int five_x = four_x + but_w + bottomOffset;

    //Video按钮;
    videoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    videoBtn.frame = CGRectMake(one_x, (allRect.size.height - butImage.size.height - bottomY) , bottomW, bottomH);
    [videoBtn setImage:[UIImage imageNamed:@"VideoButNormal"] forState:UIControlStateNormal];
    [videoBtn setImage:[UIImage imageNamed:@"VideoButHot"] forState:UIControlStateHighlighted];
    [videoBtn setImage:[UIImage imageNamed:@"VideoButDisable"] forState:UIControlStateSelected];
    videoBtn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [videoBtn setTitle:@"画 面" forState:UIControlStateNormal];
    [videoBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self setButtonContentCenter:videoBtn];
    [videoBtn addTarget:self action:@selector(videoClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:videoBtn];
        
    //音频按钮;
    audioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    audioBtn.frame = CGRectMake(two_x, (allRect.size.height - butImage.size.height - bottomY), bottomW, bottomH);
    [audioBtn setImage:[UIImage imageNamed:@"AudioButNormal"] forState:UIControlStateNormal];
    [audioBtn setImage:[UIImage imageNamed:@"AudioButHot"] forState:UIControlStateHighlighted];
    [audioBtn setImage:[UIImage imageNamed:@"AudioButDisable"] forState:UIControlStateSelected];
    audioBtn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [audioBtn setTitle:@"声 音" forState:UIControlStateNormal];
    [audioBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self setButtonContentCenter:audioBtn];
    [audioBtn addTarget:self action:@selector(audioClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:audioBtn];
        
    //上传按钮;
    uploadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    uploadBtn.frame = CGRectMake(three_x, (allRect.size.height - butImage.size.height - bottomY), bottomW, bottomH);
    [uploadBtn setImage:[UIImage imageNamed:@"CameraButNormal"] forState:UIControlStateNormal];
    [uploadBtn setImage:[UIImage imageNamed:@"CameraButHot"] forState:UIControlStateHighlighted];
    uploadBtn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [uploadBtn setTitle:@"上 传" forState:UIControlStateNormal];
    [uploadBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self setButtonContentCenter:uploadBtn];
    [uploadBtn addTarget:self action:@selector(UploadSwitchClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:uploadBtn];
        
    //简介按钮;
    homeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    homeBtn.frame = CGRectMake(four_x, (allRect.size.height - butImage.size.height - bottomY), bottomW, bottomH);
    [homeBtn setImage:[UIImage imageNamed:@"HomeButNormal"] forState:UIControlStateNormal];
    [homeBtn setImage:[UIImage imageNamed:@"HomeButHot"] forState:UIControlStateHighlighted];
    homeBtn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [homeBtn setTitle:@"简 介" forState:UIControlStateNormal];
    [homeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self setButtonContentCenter:homeBtn];
    [homeBtn addTarget:self action:@selector(HomeSwitchClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:homeBtn];
        
    //设置按钮;
    setBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    setBtn.frame = CGRectMake(five_x, (allRect.size.height - butImage.size.height - bottomY), bottomW, bottomH);
    [setBtn setImage:[UIImage imageNamed:@"SetButNormal"] forState:UIControlStateNormal];
    [setBtn setImage:[UIImage imageNamed:@"SetButHot"] forState:UIControlStateHighlighted];
    setBtn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [setBtn setTitle:@"信 息" forState:UIControlStateNormal];
    [setBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self setButtonContentCenter:setBtn];
    [setBtn addTarget:self action:@selector(SetSwitchClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:setBtn];
        
    [self showButtomButton:true];
}

-(void)showButtomButton:(bool)hidden
{
    homeBtn.hidden = hidden;
    videoBtn.hidden = hidden;
    uploadBtn.hidden = hidden;
    audioBtn.hidden = hidden;
    setBtn.hidden = hidden;
}

//****创建登陆界面
//创建登录输出元素;

-(void)createLoginFrm
{
    CGRect allRect = [ [UIScreen mainScreen]bounds];
    
    //设置整体view
    CGRect loginRect;
    loginRect.origin.x = 0;
    loginRect.origin.y = 0;
    loginRect.size.width = allRect.size.width;
    loginRect.size.height = allRect.size.height;
    loginView = [[UIView alloc] initWithFrame:loginRect];

    //加载背景
    UIImageView *loginFrmImageView = [[UIImageView alloc] initWithFrame:loginRect];
    loginFrmImageView.image = [UIImage imageNamed:@"backgroundImage"];
    loginFrmImageView.userInteractionEnabled = YES;
    [loginView addSubview:loginFrmImageView];
    
    //Logo
    UIImage *logoWidthImage = [UIImage imageNamed:@"Logo"];
    int logo_w = logoWidthImage.size.width;
    CGRect logoRect;
    logoRect.origin.x = (allRect.size.width - logo_w) / 2;
    logoRect.origin.y = logoY;
    logoRect.size = logoWidthImage.size;
    UIImageView *logoView = [[UIImageView alloc] initWithFrame:logoRect];
    logoView.image = [UIImage imageNamed:@"Logo"];
    [loginFrmImageView addSubview:logoView];
    
    //****账号输入框****
    //创建并设置输入框;
    CGRect accountRect;
    accountRect.origin.x = accountTextX + 24;
    accountRect.origin.y = accountTextY;
    accountRect.size.width = allRect.size.width - (2 * accountRect.origin.x);
    accountRect.size.height = textH;
    
    roomNameText = [[UITextField alloc] initWithFrame:accountRect];
    roomNameText.font =  [UIFont systemFontOfSize: fontSize];
    roomNameText.placeholder = @"请输入房间名称";
    roomNameText.clearButtonMode = UITextFieldViewModeAlways;
    [loginFrmImageView addSubview: roomNameText];
    
    //创建账号图标
    CGRect accoutIcoRect;
    accoutIcoRect.origin.x = accountTextX;
    accoutIcoRect.origin.y = accountTextY;
    accoutIcoRect.size.width = 20;
    accoutIcoRect.size.height = 20;
    UIImageView *accoutIco = [[UIImageView alloc] initWithFrame: accoutIcoRect];
    accoutIco.image = [UIImage imageNamed:@"AccoutIco"];
    accoutIco.contentMode = UIViewContentModeCenter;
    [loginFrmImageView addSubview: accoutIco];
    UIView *accountLine=[[UIView alloc]initWithFrame:CGRectMake(0,
                                                                accoutIcoRect.size.height + 4,
                                                                editWidth,
                                                                1)];
    accountLine.backgroundColor=[UIColor darkGrayColor];
    [roomNameText addSubview: accountLine];
    
    //****密码输入框****
    //创建并设置输入框;
    CGRect passwordRect = accountRect;
    passwordRect.origin.y = accountRect.origin.y + textInterval;
    
    passwordText = [[UITextField alloc] initWithFrame:passwordRect];
    passwordText.font =  [UIFont systemFontOfSize: fontSize];
    passwordText.placeholder = @"请输入房间密码";
    passwordText.clearButtonMode = UITextFieldViewModeAlways;
    [loginFrmImageView addSubview: passwordText];
    
    //创建图标
    CGRect passwordIcoRect;
    passwordIcoRect.origin.x = accountTextX;
    passwordIcoRect.origin.y = accountTextY + textInterval;
    passwordIcoRect.size.width = 20;
    passwordIcoRect.size.height = 20;
    UIImageView *passwordIco = [[UIImageView alloc] initWithFrame: passwordIcoRect];
    passwordIco.image = [UIImage imageNamed:@"PasswordIco"];
    passwordIco.contentMode = UIViewContentModeCenter;
    [loginFrmImageView addSubview: passwordIco];
    UIView *passwordLine = [[UIView alloc]initWithFrame:CGRectMake(0,
                                                                passwordIcoRect.size.height + 4,
                                                                editWidth,
                                                                1)];
    passwordLine.backgroundColor=[UIColor darkGrayColor];
    [passwordText addSubview: passwordLine];
    
    //传输加密按钮
    UIImage *encryptionWidthImage = [UIImage imageNamed:@"EncryptionUnSelected"];
    int encryption_w = encryptionWidthImage.size.width;
    UIButton *encryptionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [encryptionButton setBackgroundImage:[UIImage imageNamed:@"EncryptionUnSelected"] forState:UIControlStateNormal];
    [encryptionButton setBackgroundImage:[UIImage imageNamed:@"EncryptionSelected"] forState:UIControlStateSelected];
    CGRect encryptionButtonRect;
    encryptionButtonRect.origin.x = passwordRect.origin.x + passwordRect.size.width - encryption_w - 10;
    encryptionButtonRect.origin.y = passwordRect.origin.y + passwordRect.size.height + 10;
    encryptionButtonRect.size = encryptionWidthImage.size;
    [encryptionButton setFrame: encryptionButtonRect];
    [encryptionButton addTarget:self action:@selector(EncryptionCheckBoxClick:) forControlEvents:UIControlEventTouchUpInside];
    [loginFrmImageView addSubview:encryptionButton];
    
    //记住密码按钮
//    UIImage *rememWidthImage = [UIImage imageNamed:@"RememPassword_UnSelect"];
//    int remem_w = rememWidthImage.size.width;
//    UIButton *rememButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [rememButton setBackgroundImage:[UIImage imageNamed:@"RememPassword_UnSelect"] forState:UIControlStateNormal];
//    [rememButton setBackgroundImage:[UIImage imageNamed:@"RememPassword_Select"] forState:UIControlStateSelected];
//    CGRect rememButtonRect;
//    rememButtonRect.origin.x = passwordRect.origin.x + passwordRect.size.width - remem_w - 10;
//    rememButtonRect.origin.y = passwordRect.origin.y + passwordRect.size.height + 10;
//    rememButtonRect.size = rememWidthImage.size;
//    [rememButton setFrame: rememButtonRect];
//    [rememButton addTarget:self action:@selector(RememCheckBoxClick:) forControlEvents:UIControlEventTouchUpInside];
//    [loginFrmImageView addSubview:rememButton];
    
    //****登录按钮处理****
    //登录按钮
    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [loginButton setBackgroundImage:[UIImage imageNamed:@"LoginButNormal"] forState:UIControlStateNormal];
    [loginButton setBackgroundImage:[UIImage imageNamed:@"LoginButHot"] forState:UIControlStateHighlighted];
    
    CGRect loginButtonRect;
    loginButtonRect.origin.x = passwordRect.origin.x + (passwordRect.size.width - loginButton.currentBackgroundImage.size.width) / 2;
    loginButtonRect.origin.y = passwordRect.origin.y + passwordRect.size.height + controlInterval;
    loginButtonRect.size = loginButton.currentBackgroundImage.size;
    [loginButton setFrame: loginButtonRect];
    [loginButton addTarget:self action:@selector(LoginClick:) forControlEvents:UIControlEventTouchUpInside];
    [loginFrmImageView addSubview:loginButton];
    
    //Welcome欢迎词;
    NSString *caption = @"为您提供最好的实时互动产品";
    CGRect welcomeRect;
    welcomeRect.origin.x = 0;
    welcomeRect.origin.y = allRect.size.height - 30 - TOP;
    welcomeRect.size.width = allRect.size.width;
    welcomeRect.size.height = TOP;
    UILabel *welcomeText = [[UILabel alloc] initWithFrame:welcomeRect];
    welcomeText.text = caption;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:caption];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    [paragraphStyle setLineSpacing:12];
        
    [attributedString addAttribute:NSParagraphStyleAttributeName
                             value:paragraphStyle
                             range:NSMakeRange(0, [caption length])];
    [attributedString addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:welComeSize]
                             range:NSMakeRange(0, [caption length])];
    
    UIColor *TitleColor = [UIColor colorWithRed:255.0/255
                                          green:255.0/255
                                           blue:255.0/255
                                          alpha:1.0];
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:TitleColor
                             range:NSMakeRange(0, [caption length])];
    
    welcomeText.attributedText = attributedString;
    [loginFrmImageView addSubview:welcomeText];
    
    
    //版本号;
    NSString *version = [NSString stringWithFormat:@"版本：%@", appVersion];
    CGRect versionRect;
    versionRect.origin.x = 0;
    versionRect.origin.y = allRect.size.height - 10 - TOP;
    versionRect.size.width = allRect.size.width;
    versionRect.size.height = TOP;
    UILabel *versionText = [[UILabel alloc] initWithFrame:versionRect];
    versionText.text = version;
    NSMutableAttributedString *versionAttributedString = [[NSMutableAttributedString alloc] initWithString:version];
    NSMutableParagraphStyle *versionParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    versionParagraphStyle.alignment = NSTextAlignmentCenter;
    [versionParagraphStyle setLineSpacing:12];
        
    [versionAttributedString addAttribute:NSParagraphStyleAttributeName
                             value:versionParagraphStyle
                             range:NSMakeRange(0, [version length])];
    [versionAttributedString addAttribute:NSFontAttributeName
                             value:[UIFont systemFontOfSize:welComeSize]
                             range:NSMakeRange(0, [version length])];
    
    UIColor *versionTitleColor = [UIColor colorWithRed:255.0/255
                                          green:255.0/255
                                           blue:255.0/255
                                          alpha:1.0];
    [versionAttributedString addAttribute:NSForegroundColorAttributeName
                             value:versionTitleColor
                             range:NSMakeRange(0, [version length])];
    
    versionText.attributedText = versionAttributedString;
    [loginFrmImageView addSubview:versionText];
    
    
    //加载保存的账号和密码
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    accountText.text = [defaults objectForKey:AccountKey];
//    self.rmbPwdSwitch.on = [[defaults objectForKey:RmbPwdKey] boolValue];
//    self.autoLoginSwitch.on = [[defaults objectForKey:AutoLoginKey] boolValue];
//    //处理密码
//    if (self.rmbPwdSwitch.isOn) {
//        self.passwordText.text = [defaults objectForKey:PwdKey];
//    }
}

//****创建首页
-(void)createHomeFrm
{
    CGRect allRect = [ [UIScreen mainScreen]bounds];
    
    //设置首页view
    CGRect homeRect;
    homeRect.origin.x = 0;
    homeRect.origin.y = TOP;
    homeRect.size.width = allRect.size.width;
    homeRect.size.height = allRect.size.height - bottomSpace - homeRect.origin.y;
    homeView = [[UIView alloc] initWithFrame:homeRect];
    
    CGRect homeImageRect;
    homeImageRect.origin.x = 0;
    homeImageRect.origin.y = 0;
    homeImageRect.size.width = homeRect.size.width;
    homeImageRect.size.height = homeRect.size.height;

    //创建首页展现view
    _home_WebView = [[WKWebView alloc]initWithFrame:homeImageRect];
    [homeView addSubview:self.home_WebView];
}

//加载页面;
- (IBAction)loadHome {
    NSURL *url = [NSURL URLWithString:@"https://m.dexpress.com.cn/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.home_WebView loadRequest:request];
}

//****创建上传界面
//创建视频输出元素;
-(void)createUploadFrm
{
    CGRect allRect = [ [UIScreen mainScreen]bounds];
    
    //设置整体view
    CGRect uploadRect;
    uploadRect.origin.x = 0;
    uploadRect.origin.y = TOP;
    uploadRect.size.width = allRect.size.width;
    uploadRect.size.height = allRect.size.height - bottomSpace - uploadRect.origin.y;
    uploadView = [[UIView alloc] initWithFrame:uploadRect];
    
    CGRect uploadImageRect;
    uploadImageRect.origin.x = 0;
    uploadImageRect.origin.y = 0;
    uploadImageRect.size.width = uploadRect.size.width;
    uploadImageRect.size.height = uploadRect.size.height;

    //设置背景view
    uploadImageView = [[UIImageView alloc] initWithFrame:uploadImageRect];
    uploadImageView.image = [UIImage imageNamed:@"backgroundImage"];
    uploadImageView.userInteractionEnabled = YES;
    [uploadView addSubview:uploadImageView];
    
    //Logo
    UIImage *logoWidthImage = [UIImage imageNamed:@"Logo"];
    int logo_w = logoWidthImage.size.width;
    CGRect logoRect;
    logoRect.origin.x = (allRect.size.width - logo_w) / 2;
    logoRect.origin.y = logoY - uploadRect.origin.y;
    logoRect.size = logoWidthImage.size;
    uploadLogoView = [[UIImageView alloc] initWithFrame:logoRect];
    uploadLogoView.image = [UIImage imageNamed:@"Logo"];
    [uploadImageView addSubview:uploadLogoView];
    
    //****采集按钮处理****
    //采集按钮
    CaptureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [CaptureButton setBackgroundImage:[UIImage imageNamed:@"CaptureBut"] forState:UIControlStateNormal];
    
    CGRect CaptureButtonRect;
    CaptureButtonRect.origin.x = logoRect.origin.x + (logoRect.size.width - CaptureButton.currentBackgroundImage.size.width) / 2;
    CaptureButtonRect.origin.y = logoRect.origin.y + logoRect.size.height + captureInterval;
    CaptureButtonRect.size = CaptureButton.currentBackgroundImage.size;
    [CaptureButton setFrame: CaptureButtonRect];
    [CaptureButton addTarget:self action:@selector(CaptureClick:) forControlEvents:UIControlEventTouchUpInside];
    [uploadImageView addSubview:CaptureButton];
    
    //创建关闭
    UIImage *closeWidthImage = [UIImage imageNamed:@"Close"];
    CGRect closeRect;
    closeRect.origin.x = 20;
    closeRect.origin.y = 10;
    closeRect.size = closeWidthImage.size;
    closeImageView = [[UIImageView alloc] initWithFrame:closeRect];
    closeImageView.image = [UIImage imageNamed:@"Close"];
    closeImageView.hidden = true;
    closeImageView.userInteractionEnabled=YES;
    UITapGestureRecognizer *singleTap =[[UITapGestureRecognizer alloc]initWithTarget:self
                                                                              action:@selector(onClickUploadCloseImage)];
    [closeImageView addGestureRecognizer:singleTap];
    [uploadImageView addSubview:closeImageView];
    
    //创建摄像头
    UIImage *cameraWidthImage = [UIImage imageNamed:@"Camera"];
    CGRect cameraRect;
    cameraRect.origin.x = uploadRect.size.width - 20 - cameraWidthImage.size.width;
    cameraRect.origin.y = closeRect.origin.y;
    cameraRect.size = cameraWidthImage.size;
    
    cameraImageView = [[UIImageView alloc] initWithFrame:cameraRect];
    cameraImageView.image = [UIImage imageNamed:@"Camera"];
    cameraImageView.hidden =  true;
    cameraImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *singleCameraTap =[[UITapGestureRecognizer alloc]initWithTarget:self
                                                                                    action:@selector(onClickUploadCameraImage)];
    [cameraImageView addGestureRecognizer:singleCameraTap];
    [uploadImageView addSubview:cameraImageView];
}

//****创建信息界面
//创建信息界面元素;
-(void)createSetFrm
{
    CGRect allRect = [ [UIScreen mainScreen]bounds];
    
    //设置整体view
    CGRect setRect;
    setRect.origin.x = 0;
    setRect.origin.y = TOP;
    setRect.size.width = allRect.size.width;
    setRect.size.height = allRect.size.height - bottomSpace - setRect.origin.y;
    setView = [[UIView alloc] initWithFrame:setRect];
    
    CGRect setImageRect;
    setImageRect.origin.x = 0;
    setImageRect.origin.y = 0;
    setImageRect.size.width = setRect.size.width;
    setImageRect.size.height = setRect.size.height;
    setImageView = [[UIImageView alloc] initWithFrame:setImageRect];
    setImageView.image = [UIImage imageNamed:@"backgroundImage"];
    setImageView.userInteractionEnabled = YES;
    [setView addSubview:setImageView];
    
    //Logo
    UIImage *watchLogoImage = [UIImage imageNamed:@"Logo"];
    int logo_w = watchLogoImage.size.width;
    CGRect logoRect;
    logoRect.origin.x = (allRect.size.width - logo_w) / 2;
    logoRect.origin.y = logoY  - setRect.origin.y;
    logoRect.size = watchLogoImage.size;
    setLogoView = [[UIImageView alloc] initWithFrame:logoRect];
    setLogoView.image = [UIImage imageNamed:@"Logo"];
    [setImageView addSubview:setLogoView];
    
    //****创建账号输入框****
    //创建账号并设置输入框;
    CGRect setAccountRect;
    setAccountRect.origin.x = accountTextX + 24;
    setAccountRect.origin.y = accountTextY - setRect.origin.y;
    setAccountRect.size.width = allRect.size.width - (2 * setAccountRect.origin.x);
    setAccountRect.size.height = textH;

    setAccountText = [[UITextField alloc] initWithFrame:setAccountRect];
    setAccountText.font =  [UIFont systemFontOfSize: fontSize];
//    setAccountText.clearButtonMode = UITextFieldViewModeAlways;
    [setImageView addSubview: setAccountText];
    
    CGRect accoutIcoRect;
    accoutIcoRect.origin.x = accountTextX;
    accoutIcoRect.origin.y = accountTextY - TOP;
    accoutIcoRect.size.width = 20;
    accoutIcoRect.size.height = 20;
    setAccoutIco = [[UIImageView alloc] initWithFrame: accoutIcoRect];
    setAccoutIco.image = [UIImage imageNamed:@"AccoutIco"];
    setAccoutIco.contentMode = UIViewContentModeCenter;
    [setImageView addSubview: setAccoutIco];
    UIView *accountLine=[[UIView alloc]initWithFrame:CGRectMake(0,
                                                                accoutIcoRect.size.height + 4,
                                                                editWidth,
                                                                1)];
    accountLine.backgroundColor=[UIColor darkGrayColor];
    [setAccountText addSubview: accountLine];
    
    //****Ip输入框****
    CGRect IpRect = setAccountRect;
    IpRect.origin.y = setAccountRect.origin.y + textInterval;

    setIpText = [[UITextField alloc] initWithFrame:IpRect];
    setIpText.font =  [UIFont systemFontOfSize: fontSize];
    [setView addSubview: setIpText];

    CGRect ipIcoRect;
    ipIcoRect.origin.x = accountTextX;
    ipIcoRect.origin.y = setAccountRect.origin.y + textInterval;
    ipIcoRect.size.width = 20;
    ipIcoRect.size.height = 20;
    setIpIco = [[UIImageView alloc] initWithFrame: ipIcoRect];
    setIpIco.image = [UIImage imageNamed:@"PasswordIco"];
    setIpIco.contentMode = UIViewContentModeCenter;
    [setView addSubview: setIpIco];
    UIView *ipLine = [[UIView alloc]initWithFrame:CGRectMake(0, ipIcoRect.size.height + 4, editWidth, 1)];
    ipLine.backgroundColor=[UIColor darkGrayColor];
    [setIpText addSubview: ipLine];
    
    //****端口输入框****
    CGRect portRect = IpRect;
    portRect.origin.y = IpRect.origin.y + textInterval;

    setPortText = [[UITextField alloc] initWithFrame:portRect];
    setPortText.font =  [UIFont systemFontOfSize: fontSize];
    [setView addSubview: setPortText];

    CGRect portIcoRect;
    portIcoRect.origin.x = accountTextX;
    portIcoRect.origin.y = ipIcoRect.origin.y + textInterval;
    portIcoRect.size.width = 20;
    portIcoRect.size.height = 20;
    setPortIco = [[UIImageView alloc] initWithFrame: portIcoRect];
    setPortIco.image = [UIImage imageNamed:@"PasswordIco"];
    setPortIco.contentMode = UIViewContentModeCenter;
    [setView addSubview: setPortIco];
    UIView *portLine = [[UIView alloc]initWithFrame:CGRectMake(0, portIcoRect.size.height + 4, editWidth, 1)];
    portLine.backgroundColor=[UIColor darkGrayColor];
    [setPortText addSubview: portLine];
    
    //****码率输入框****
    CGRect rateRect = portRect;
    rateRect.origin.y = portRect.origin.y + textInterval;

    setRateText = [[UITextField alloc] initWithFrame:rateRect];
    setRateText.font =  [UIFont systemFontOfSize: fontSize];
    [setView addSubview: setRateText];

    CGRect rateIcoRect;
    rateIcoRect.origin.x = accountTextX;
    rateIcoRect.origin.y = portIcoRect.origin.y + textInterval;
    rateIcoRect.size.width = 20;
    rateIcoRect.size.height = 20;
    setRateIco = [[UIImageView alloc] initWithFrame: rateIcoRect];
    setRateIco.image = [UIImage imageNamed:@"PasswordIco"];
    setRateIco.contentMode = UIViewContentModeCenter;
    [setView addSubview: setRateIco];
    UIView *rateLine = [[UIView alloc]initWithFrame:CGRectMake(0, rateIcoRect.size.height + 4, editWidth, 1)];
    rateLine.backgroundColor=[UIColor darkGrayColor];
    [setRateText addSubview: rateLine];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self mathScale];
    
    initPlayed_ = false;
    sourceDown_ = false;
    _cur_position = back_camera;
        
    [self createTitle];
    [self createHomeFrm];
    [self createLoginFrm];
    [self createUploadFrm];
    [self createSetFrm];
    [self createButtomButton];

    //创建用户
    _leftUser = [self createUser:@"Left" :uploadImageView];
    _middleUser = [self createUser:@"Middle" :uploadImageView];
    _rightUser = [self createUser:@"Right" :uploadImageView];

    initPlayed_ = true;

    [self switchShowFrm:LOGIN];

    //启动保活时钟
    _aliveTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                   target:self
                                                 selector:@selector(aliveTimed:)
                                                 userInfo:nil
                                                  repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_aliveTimer forMode:NSRunLoopCommonModes];
}

- (void)aliveTimed:(NSTimer*)timer {

    //需要使用保活时钟;
    [self keepAlive:self.roomName :self.userName];
}

//停止保活定时器
-(void)aliveTimed{
    [_aliveTimer invalidate];
}

-(void)initMedia
{
    //这里将编码放到了后面，便于进行设置;
    NSLog(@"初始化数据长度");
    g_inputByteSize  = self.frame_size * self.audio_channels  * sizeof(AudioSampleType);
    g_outputByteSize = self.frame_size * self.audio_channels * sizeof(AudioSampleType);
    
    NSLog(@"初始化输入数据");
    g_inputBuffer.mNumberChannels = self.audio_channels;
    g_inputBuffer.mDataByteSize   = g_inputByteSize;
    g_inputBuffer.mData           = malloc(sizeof(unsigned char) * g_inputByteSize);
    memset(g_inputBuffer.mData, 0, g_inputByteSize);
    
    NSLog(@"初始化输出数据");
    g_outputBuffer.mNumberChannels = self.audio_channels;
    g_outputBuffer.mDataByteSize   = g_outputByteSize;
    g_outputBuffer.mData           = malloc(sizeof(unsigned char) * g_outputByteSize);
    memset(g_outputBuffer.mData, 0, g_outputByteSize);
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //收起键盘
    [self.view endEditing:YES];
}

//点击视频限制按钮
- (IBAction)videoClick:(UIButton *)sender
{
    sender.selected = not sender.selected;
    _hideVideo = sender.selected;
    if(nullptr != self.client_ptr)
    {
        NSLog(@"视频隐藏点击 %d", _hideVideo);
        [self.client_ptr sendHide:(char*)[self.userName UTF8String] :VIDEO_HIDE :_hideVideo];
    }
}

//点击音频限制按钮
- (IBAction)audioClick:(UIButton *)sender
{
    sender.selected = not sender.selected;
    _hideAudio = sender.selected;
    if(nullptr != self.client_ptr)
    {
        NSLog(@"音频隐藏点击 %d", _hideVideo);
        [self.client_ptr sendHide:(char*)[self.userName UTF8String] :AUDIO_HIDE :_hideAudio];
    }
}

//点击简介按钮
- (IBAction)HomeSwitchClick:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
    if (sender.selected)
    {
        sender.selected = false;
        [self closeLinker];
        [self switchShowFrm:HOME];
        [self loadHome];
    }
}

//点击上传按钮
- (IBAction)UploadSwitchClick:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
    if (sender.selected)
    {
        sender.selected = false;
        [self switchShowFrm:UPLOAD];
    }
}

//点击设置按钮
- (IBAction)SetSwitchClick:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
    if (sender.selected)
    {
        sender.selected = false;
        [self closeLinker];
        [self switchShowFrm:SET];
    }
}

//点击记住密码
- (IBAction)EncryptionCheckBoxClick:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
    _encryption = sender.selected;
}

//点击记住密码
- (IBAction)videoPassWDCheckBoxClick:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
}

//点击登录按钮
- (IBAction)LoginClick:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
    if (sender.selected)
    {
        sender.selected = false;
        [self LoginRequest];
    }
}

//点击采集按钮
- (IBAction)CaptureClick:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
    sender.hidden = true;
    if (sender.selected)
    {
        sender.selected = false;
        [self UploadRequest];
    }
}

-(void) LoginRequest
{
    //发送一个http的认证请求;
//    bool authed = [self loginRoom: roomNameText.text: passwordText.text: userNameText.text];
    bool authed = [self loginRoom: roomNameText.text: passwordText.text: @""];
    if(authed)
    {
        [self initMedia];
        [self switchShowFrm:UPLOAD];
    }
}

//点击上传按钮;
- (bool)UploadRequest
{
    //隐藏上传界面上的其它元素;
    uploadLogoView.hidden = true;
    uploadLoginButton.hidden = true;
    keyText.hidden = true;
    closeImageView.hidden = false;
    cameraImageView.hidden = false;
    videoPassWDButton.hidden = true;
    sessionIco.hidden = true;
    
//    const char *key = [keyText.text UTF8String];
    bool delay = true;
    int timeOut = 5;
    int delayTimer = 50;
    
    //得到屏幕大小（不包含状态栏的Rect）
    CGRect allRect = [ [UIScreen mainScreen]bounds];
    int width = allRect.size.width;
    int height = allRect.size.height;
    
    NSLog(@"启动音频编码设置");
    if(nullptr == self.audio_encoder_ptr)
    {
        self.audio_encoder_ptr = [[audio_encoder alloc] init];
        [self.audio_encoder_ptr initEncoder :self.audio_sample_rate :self.audio_channels :self.frame_size :64000 :et_hardware];
    }
    
    NSLog(@"启动视频编码设置\n");
    if(nullptr == self.video_encoder_ptr)
    {
        self.video_encoder_ptr = [[video_encoder alloc] init];
        self.video_encoder_ptr.delegate = self;
        BOOL ret = [self.video_encoder_ptr initEncoder:width height:height fps:self.fps bite:0.7 * MB];
//        BOOL ret = [self.video_encoder_ptr initEncoder:width height:height fps:self.fps bite:self.media_rate * MB];
        if(ret == NO)
        {
            NSLog(@"Error: video_encoder_ptr Failed");
            return false;
        }
    }
    
    NSLog(@"启动网络通信");
    if(nullptr == self.client_ptr)
    {
        NSLog(@"启动网络通信");
        self.client_ptr = [[ios_rudp_linker alloc] init];
        self.client_ptr.delegate = self;
        NSLog(@"检测网络通信权限");
        [self.client_ptr checkNetWorkAuth];
    }
    
//    NSString *testIp = @"192.168.3.148";
//    int client_linker_handle = [self.client_ptr beginClient :(char*)[testIp UTF8String]
//                                                            :(int)self.media_remote_port
//                                                            :timeOut
//                                                            :delay
//                                                            :delayTimer
//                                                            :false];
    
    int client_linker_handle = [self.client_ptr beginClient :(char*)[self.media_remote_ip UTF8String]
                                                            :(int)self.media_remote_port
                                                            :timeOut
                                                            :delay
                                                            :delayTimer
                                                            :_encryption];
    if(client_linker_handle > 0)
    {
        client_linker_handle_ = client_linker_handle;
        //链接成功，可以发送登陆消息;
        bool logined = [self.client_ptr Login:(char*)[self.roomName UTF8String]
                                             :(char*)[self.passWd UTF8String]
                                             :(char*)[self.userName UTF8String]
                                             :timeOut];
        if(logined)
        {
            self.mainShowUser = self.userName;
            NSLog(@"客户端登陆成功，可以继续处理!");
        }
        else
        {
            NSLog(@"客户端登陆失败，无法进行传输，直接退出！");
            return false;
        }
    }
    else
    {
        NSLog(@"客户端链接失败，无法进行传输，直接退出！");
        return false;
    }
    
    //开始采集;
    if(nullptr == self.capture_session_ptr)
    {
        self.capture_session_ptr = [[capture_beautiful alloc] init];
        self.capture_session_ptr.delegate = self;
        if(!self.capture_session_ptr.checkAudioAuth)
        {
            NSLog(@"检测声音认证失败");
            return false;
        }
    }
    
    if(nullptr == self.capture_session_ptr)
    {
        NSLog(@"采集对象为nil，直接退出！");
        return false;
    }
    uploadClosed_ = false;
    
    //初始化;
    bool ret = [self.capture_session_ptr initVideoCapture:back_camera :capture_window_1280x720 :TRUE :self.audio_sample_rate :self.audio_channels :self.audio_perchannel :self.audio_buffer_size];
    if(!ret)
    {
        NSLog(@"Error: 初始化视频采集设备失败");
        return false;
    }
    
    [self.capture_session_ptr startCapture];    // 开始采集
    _rtoText.hidden = false;
    _wifiView.hidden = false;
    _rateText.hidden = false;
    _rateView.hidden = false;
    return true;
}

//****按钮处理函数****/
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

//****采集透出的回调函数****//
#define kBitsPerComponent (8)
#define kBitsPerPixel (32)
#define kPixelChannelCount (4)//每一行的像素点占用的字节数，每个像素点的ARGB四个通道各占8个bit

//视频取样数据回调
- (void)videoOutput:(CVPixelBufferRef)pixelBuffer
{
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    //获取相应的信息;
    void * baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    size_t bufferSize = CVPixelBufferGetDataSize(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    
    // 创建一个CGImageRef对象
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       kBitsPerComponent,
                                       kBitsPerPixel,
                                       bytesPerRow,
                                       rgbColorSpace,
                                       kCGImageAlphaPremultipliedFirst|kCGBitmapByteOrder32Little,
                                       provider,
                                       NULL,
                                       true,
                                       kCGRenderingIntentDefault);
    
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    
    // 回到主线程更新UI
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        if(!sourceDown_)
        {
            if(!uploadClosed_)
            {
                if([self.mainShowUser isEqual: self.userName])
                {
                    uploadImageView.image = image;
                }
                else if([self.leftUser->showUser_ isEqual: self.userName])
                {
                    if(!self.leftUser->video_hide_)
                        self.leftUser->imageView_.image = image;
                }
                else if([self.middleUser->showUser_ isEqual: self.userName])
                {
                    if(!self.middleUser->video_hide_)
                        self.middleUser->imageView_.image = image;
                }
                else if([self.rightUser->showUser_ isEqual: self.userName])
                {
                    if(!self.rightUser->video_hide_)
                        self.rightUser->imageView_.image = image;
                }
            }
        }
        else
        {
            if(!uploadClosed_)
            {
                if([self.mainShowUser isEqual: self.userName])
                {
                    uploadImageView.image = image;
                }
                else if([self.leftUser->showUser_ isEqual: self.userName])
                {
                    if(!self.leftUser->video_hide_)
                        self.leftUser->imageView_.image = image;
                }
                else if([self.middleUser->showUser_ isEqual: self.userName])
                {
                    if(!self.middleUser->video_hide_)
                        self.middleUser->imageView_.image = image;
                }
                else if([self.rightUser->showUser_ isEqual: self.userName])
                {
                    if(!self.rightUser->video_hide_)
                        self.rightUser->imageView_.image = image;
                }
            }
        }
        
    });
    CFRelease(cgImage);
    CFRelease(provider);
    CGColorSpaceRelease(rgbColorSpace);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    //进行视频编码;
    if(nullptr != self.video_encoder_ptr)
    {
        [self.video_encoder_ptr videoEncoderBeautify:pixelBuffer];
    }
}

- (void)audioOutput:(AudioQueueBufferRef)sampleBuffer :(int64_t)currPts
{
    //音频编码;
    EncodedAudioBuffer encodedAU;
    memcpy(g_inputBuffer.mData, sampleBuffer->mAudioData, sampleBuffer->mAudioDataByteSize);
    [self.audio_encoder_ptr EncodeAACELD:g_inputBuffer :&encodedAU];

    //发送音频;
//    if(nullptr != self.client_ptr && !self.hideAudio)
//    {
//        [self.client_ptr sendAudio:(char*)[self.userName UTF8String] :0 :encodedAU.mDataBytesSize :(char*)encodedAU.data];
//    }
}

- (NSData*) AdtsDataForPacketLength:(NSUInteger)packetLength
{
    //定义长度;
    const int ADTS_Length = 7;
    NSUInteger fullLength = ADTS_Length + packetLength;
    
    //申请adts的头空间;
    char *packet = (char*)malloc(sizeof(char) * ADTS_Length);
    
    //使用的协议;
    uint8_t profile = kMPEG4Object_AAC_Main;
    //采样率;
    uint8_t sampleRate = 4;
    //频道信息;
    uint8_t chanCfg = 2;
    
    // fill in ADTS data
    packet[0] = (char)0xFF; // 11111111     = syncword
    packet[1] = (char)0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1) << 6) + (sampleRate << 2) +(chanCfg >> 2));
    packet[3] = (char)(((chanCfg&3) << 6) + (fullLength >> 11));
    packet[4] = (char)((fullLength & 0x7FF) >> 3);
    packet[5] = (char)(((fullLength &7) << 5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:ADTS_Length freeWhenDone:YES];
    return data;
}

//****解码透出的回调函数****//

-(void)set_video_encode:(uint8_t *)frame withSize:(uint32_t)frameSize
{
    
}

//视频编码后得到的数据;
-(void)video_encodeing:(uint8_t *)frame
              withSize:(uint32_t)frameSize
             keyFrames:(bool)keyFrames
             spsHeader:(int)spsHeader
            videoWidth:(int)width
           videoHeigth:(int)heigth
              videoPts:(int64_t)pts;
{
    //发送视频;
    if(nullptr != self.client_ptr && !self.hideVideo)
    {
        [self.client_ptr sendVideo:(char*)[self.userName UTF8String] :0 :keyFrames :spsHeader :frameSize :(char*)frame];
    }
}

//透出的视频解码数据;
- (void)video_decoded_buffer:(NSString*)userName :(CVImageBufferRef )imageBuffer
{
    dispatch_sync(dispatch_get_main_queue(), ^{

        if([userName isEqual: _mainShowUser])
        {
            // 转换为CIImage
            CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
            // 转换UIImage
            uploadImageView.image = [UIImage imageWithCIImage:ciImage];
        }
        else if([userName isEqual: _leftUser->showUser_])
        {
            if(_leftUser->imageView_.hidden)
                _leftUser->imageView_.hidden = false;
            
            if(!_leftUser->video_hide_)
            {
                CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
                _leftUser->imageView_.image = [UIImage imageWithCIImage:ciImage];
            }
        }
        else if([userName isEqual: _middleUser->showUser_])
        {
            if(_middleUser->imageView_.hidden)
                _middleUser->imageView_.hidden = false;
            
            if(!_leftUser->video_hide_)
            {
                CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
                _leftUser->imageView_.image = [UIImage imageWithCIImage:ciImage];
            }
        }
        else if([userName isEqual: _rightUser->showUser_])
        {
            if(_rightUser->imageView_.hidden)
                _rightUser->imageView_.hidden = false;
            
            if(!_rightUser->video_hide_)
            {
                CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
                _rightUser->imageView_.image = [UIImage imageWithCIImage:ciImage];
            }
        }
    });
}

//****传输透出的回调函数****//
#pragma mark - CallBack

//传输使用的RTO;
-(void)onRto: (char*)remote_ip :(int)remote_port :(int)local_rto :(int)remote_rto
{
    if(self.cur_mode == UPLOAD)
    {
        NSString *rto = [@(local_rto) stringValue];
        NSString* strRto = [NSString stringWithFormat:@"%@ms", rto];
        [self setRto:strRto :local_rto];
    }
}

//传输使用的RTO;
-(void)onRate: (char*)remote_ip :(int)remote_port :(unsigned int)send_rate :(unsigned int)recv_rate
{
    if(self.cur_mode == UPLOAD)
    {
        NSString* strRate = [self rateString:send_rate];
        [self setRate:strRate];
    }
}

//推送用户登录消息
- (void)onResponseLogin
{
    _leftUser->decoderUser_ = @"";
    _leftUser->showUser_ = @"";
    
    _middleUser->decoderUser_ = @"";
    _middleUser->showUser_ = @"";
    
    _rightUser->decoderUser_ = @"";
    _rightUser->showUser_ = @"";
}

#pragma mark - Notify

//推送用户登录消息
- (void)onNotifyUser:(char*)userName
{
    char logoutBuffer[1024] = {0};
    NSString *currName = [NSString stringWithUTF8String: userName];
    
    NSLog(@"onNotifyUser --->>> userName=%s", userName);
    
    if([_leftUser->decoderUser_ isEqual: @""])
    {
        _leftUser->decoderUser_ = currName;
        _leftUser->showUser_ = currName;
        [self.leftUser->userVideoDecoder_ setUserName:_leftUser->decoderUser_];
        
        sprintf(logoutBuffer, "用户 %s 进入房间，安排在最左边", userName);
        NSLog(@"%s", logoutBuffer);
    }
    else if([_middleUser->decoderUser_ isEqual: @""])
    {
        _middleUser->decoderUser_ = currName;
        _middleUser->showUser_ = currName;
        [self.middleUser->userVideoDecoder_ setUserName:_middleUser->decoderUser_];
        
        sprintf(logoutBuffer, "用户 %s 进入房间，安排在中间", userName);
        NSLog(@"%s", logoutBuffer);
    }
    else if([_rightUser->decoderUser_ isEqual: @""])
    {
        _rightUser->decoderUser_ = currName;
        _rightUser->showUser_ = currName;
        [self.rightUser->userVideoDecoder_ setUserName:_rightUser->decoderUser_];
        
        sprintf(logoutBuffer, "用户 %s 进入房间，安排在最右边", userName);
        NSLog(@"%s", logoutBuffer);
    }
}

//用户断开消息
-(void)onLoginout:(int)linkerHandle :(char*)remote_ip :(int)remote_port
{
    
}

//推送用户断开消息
- (void)onNotifyLogout:(char*)userName
{
    NSString *currName = [NSString stringWithUTF8String: userName];
    
    if([currName isEqual: _leftUser->showUser_])
    {
        _leftUser->imageView_.hidden = true;
    }
    else if([currName isEqual: _middleUser->showUser_])
    {
        _middleUser->imageView_.hidden = true;
    }
    else if([currName isEqual: _rightUser->showUser_])
    {
        _rightUser->imageView_.hidden = true;
    }
    
    char logoutBuffer[1024] = {0};
    sprintf(logoutBuffer, "用户 %s 退出房间", userName);
    NSLog(@"%s", logoutBuffer);
}

//传输视频的回调函数;
- (void)onNotifyVideo:(char*)userName
                     :(int)pts
                     :(bool)keyframe
                     :(int)sps_pps_size
                     :(int)size
                     :(char*)buffer
                     :(int)linker_handle
                     :(char*)remote_ip
                     :(int)remote_port
                     :(int)consume_timer
{
    NSString* currentUserName = [NSString stringWithUTF8String:userName];
    
    if(keyframe)
    {
        //得到sps和pps的设置;
        UInt32 headerSize = sps_pps_size;
        if([currentUserName isEqual: _leftUser->decoderUser_])
        {
            if(nullptr != _leftUser->userVideoDecoder_ && !_leftUser->video_hide_)
            {
                [_leftUser->userVideoDecoder_ setDecode:(uint8_t *)buffer withSize:headerSize];
                [_leftUser->userVideoDecoder_ decodeing:(uint8_t *)buffer + headerSize withSize:size - headerSize];
            }
        }
        else if([currentUserName isEqual: _middleUser->decoderUser_])
        {
            if(nullptr != _middleUser->userVideoDecoder_ && !_middleUser->video_hide_)
            {
                [_middleUser->userVideoDecoder_ setDecode:(uint8_t *)buffer withSize:headerSize];
                [_middleUser->userVideoDecoder_ decodeing:(uint8_t *)buffer + headerSize withSize:size - headerSize];
            }
        }
        else if([currentUserName isEqual: _rightUser->decoderUser_])
        {
            if(nullptr != _rightUser->userVideoDecoder_ && !_rightUser->video_hide_)
            {
                [_rightUser->userVideoDecoder_ setDecode:(uint8_t *)buffer withSize:headerSize];
                [_rightUser->userVideoDecoder_ decodeing:(uint8_t *)buffer + headerSize withSize:size - headerSize];
            }
        }
    }
    else
    {
        //非关键帧，直接进行解码;
        if([currentUserName isEqual: _leftUser->decoderUser_])
        {
            if(nullptr != _leftUser->userVideoDecoder_ && !_leftUser->video_hide_)
            {
                [_leftUser->userVideoDecoder_ decodeing:(uint8_t *)buffer withSize:size];
            }
        }
        else if([currentUserName isEqual: _middleUser->decoderUser_])
        {
            if(nullptr != _middleUser->userVideoDecoder_ && !_middleUser->video_hide_)
            {
                [_middleUser->userVideoDecoder_ decodeing:(uint8_t *)buffer withSize:size];
            }
        }
        else if([currentUserName isEqual: _rightUser->decoderUser_])
        {
            if(nullptr != _rightUser->userVideoDecoder_ && !_rightUser->video_hide_)
            {
                [_rightUser->userVideoDecoder_ decodeing:(uint8_t *)buffer withSize:size];
            }
        }
    }
}

//传输音频的回调函数;
- (void)onNotifyAudio:(char*)userName
                     :(int)pts
                     :(int)size
                     :(char*)buffer
                     :(int)linker_handle
                     :(char*)remote_ip
                     :(int)remote_port
                     :(int)consume_timer
{
    //开始音频解码;
    g_outputBuffer.mDataByteSize = g_outputByteSize;
    
    NSString* currentUserName = [NSString stringWithUTF8String:userName];
    if([currentUserName isEqual: _leftUser->decoderUser_])
    {
        if(nullptr != _leftUser->userAuioDecoder_)
        {
            [_leftUser->userAuioDecoder_ DecodeAACELD:buffer :size :&g_outputBuffer];
            [_leftUser->userAuioDecoder_ addBuffer:g_outputBuffer.mData :g_outputBuffer.mDataByteSize];
        }
    }
    else if([currentUserName isEqual: _middleUser->decoderUser_])
    {
        if(nullptr != _middleUser->userAuioDecoder_)
        {
            [_middleUser->userAuioDecoder_ DecodeAACELD:buffer :size :&g_outputBuffer];
            [_middleUser->userAuioDecoder_ addBuffer:g_outputBuffer.mData :g_outputBuffer.mDataByteSize];
        }
    }
    else if([currentUserName isEqual: _rightUser->decoderUser_])
    {
        if(nullptr != _rightUser->userAuioDecoder_)
        {
            [_rightUser->userAuioDecoder_ DecodeAACELD:buffer :size :&g_outputBuffer];
            [_rightUser->userAuioDecoder_ addBuffer:g_outputBuffer.mData :g_outputBuffer.mDataByteSize];
        }
    }
}

//传输音频的回调函数;
- (void)onNotifyHide:(char*)userName
                    :(MediaHide)mode
                    :(bool)hide
{
    NSString* currentUserName = [NSString stringWithUTF8String:userName];
    if([currentUserName isEqual: _leftUser->decoderUser_])
    {
        if(VIDEO_HIDE == mode)
        {
            if(nullptr != _leftUser->userVideoDecoder_)
            {
                _leftUser->video_hide_ = hide;
                if(_leftUser->video_hide_)
                {
                    //切换到主线程进行绘制
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        _leftUser->imageView_.image = [UIImage imageNamed:@"hideBackground"];
                    });
                }
            }
        }
        
    }
    else if([currentUserName isEqual: _middleUser->decoderUser_])
    {
        if(VIDEO_HIDE == mode)
        {
            if(nullptr != _middleUser->userVideoDecoder_)
            {
                _middleUser->video_hide_ = hide;
                if(_middleUser->video_hide_)
                {
                    //切换到主线程进行绘制
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        _middleUser->imageView_.image = [UIImage imageNamed:@"hideBackground"];
                    });
                }
            }
        }
    }
    else if([currentUserName isEqual: _rightUser->decoderUser_])
    {
        if(VIDEO_HIDE == mode)
        {
            if(nullptr != _rightUser->userVideoDecoder_)
            {
                _rightUser->video_hide_ = hide;
                if(_rightUser->video_hide_)
                {
                    //切换到主线程进行绘制
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        _rightUser->imageView_.image = [UIImage imageNamed:@"hideBackground"];
                    });
                }
            }
        }
    }
}

@end

