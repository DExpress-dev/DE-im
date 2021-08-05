//
//  VCallHeader.h
//  VCall
//
//  Created by fxh7622 on 2021/8/5.
//  Copyright © 2021 Jessonliu. All rights reserved.
//

#ifndef VCallHeader_h
#define VCallHeader_h

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

//**********
enum Mode{HOME, LOGIN, UPLOAD, SET};
enum State{NONE, UPLOADING, WATCHING};

@interface vcall_header : NSObject
{
}

-(NSString *)rateString: (unsigned int)rate;
-(BOOL)saveAccFile : (NSString *) filePath : (char*) data;

@end

#endif /* VCallHeader_h */
