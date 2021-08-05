//
//  VCallHeader.m
//  VCall
//
//  Created by fxh7622 on 2021/8/5.
//  Copyright © 2021 Jessonliu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VCallHeader.h"

static vcall_header *header_instance_ = nil;

@implementation vcall_header

//单例(这里注意单例的写法);
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        header_instance_ = [[self alloc] init];
    });
    return header_instance_;
}

-(instancetype)init
{
    self = [super init];
    return self;
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

@end
