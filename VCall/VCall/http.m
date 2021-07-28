//
//  http.m
//  Demo
//
//  Created by fxh7622 on 2020/9/6.
//  Copyright © 2020 Jessonliu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "http.h"

static NSString *uri = @"61.160.212.59";
static NSString *uri_port = @":8085";

static http_client *instance_ = nil;

@implementation http_client

//单例(这里注意单例的写法);
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance_ = [[self alloc] init];
    });
    return instance_;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance_ = [super allocWithZone:zone];
        if (self)
        {
            NSLog(@"allocWithZone 创建了对象");
        }
    });
    return instance_;
}

-(instancetype)init
{
    self = [super init];
    _roomName = [[NSString alloc] init];
    _passWd = [[NSString alloc] init];
    _userName = [[NSString alloc] init];
    _media_remote_ip = [[NSString alloc] init];
    
    return self;
}

//返回的json格式为：
/*
 
 {
     "result": 200,
     "body": {
         "user": {
             "uid": "12999",
             "session": "adsfadsf"
         },
         "media": {
             "media_ip": "10.10.50.98",
             "media_port": 41002,
             "media_rate": 1.3
         },
         "audio": {
             "sample_rate": 44100,
             "channels": 1,
             "perchannel": 16,
             "buffer_size": 2048,
             "audio_size": 1024
         },
         "video": {
             "frame_size": 1024,
             "fps": 30
         }
     }
 }
 
 */
-(bool)loginRoom :(NSString*)roomName :(NSString*)passWd: (NSString*)userName
{
    self.auth_result_ = false;
    dispatch_semaphore_t authSemaphore = dispatch_semaphore_create(0);
    
    NSString* authRequest;
    
    if([passWd isEqualToString:@""]){
        
        authRequest = [NSString stringWithFormat:@"http://%@%@/loginRoom?roomName=%@&passWd=%@&userName=%@",
                       uri,
                       uri_port,
                       roomName,
                       passWd,
                       userName];
    }else{
        
        authRequest = [NSString stringWithFormat:@"http://%@%@/loginRoom?roomName=%@&&userName=%@",
                       uri,
                       uri_port,
                       roomName,
                       userName];
    }
    
    //产生Url请求
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:authRequest]
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:5.0];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable connectionError)
    {
        //判断链接是否失败
        if (connectionError)
        {
            NSLog(@"连接错误 %@", connectionError);
            self.auth_result_ = false;
        }
        else
        {
            //拿到返回内容
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (200 == httpResponse.statusCode ||304 == httpResponse.statusCode)
            {
                // 序列化json格式
                NSError *error = nil;
                NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                            options:NSJSONReadingMutableContainers
                                                                              error:&error];
                
                if (error == nil)
                {
                    //可以进行json解析，开始得到解析后的数据
                    self.response_result = [[jsonDict valueForKey:@"result"] intValue];

                    //没有失败，可以获取数据
                    if(200 == self.response_result)
                    {
                        //开始获取所有信息;
                        self.roomName = [jsonDict[@"body"][@"room"][@"roomName"] mutableCopy];
                        self.passWd = [jsonDict[@"body"][@"room"][@"passWd"] mutableCopy];
                        
                        self.userName =[jsonDict[@"body"][@"user"][@"userName"] mutableCopy];
                        self.user_ip =[jsonDict[@"body"][@"user"][@"userIp"] mutableCopy];
                        
                        self.media_remote_ip = [jsonDict[@"body"][@"media"][@"media_ip"] mutableCopy];
                        if(jsonDict[@"body"][@"media"][@"media_port"] != nil)
                            self.media_remote_port = [jsonDict[@"body"][@"media"][@"media_port"] intValue];
                        
                        if(jsonDict[@"body"][@"media"][@"media_rate"] != nil)
                            self.media_rate = [jsonDict[@"body"][@"media"][@"media_rate"] floatValue];
                        
                        if(jsonDict[@"body"][@"audio"][@"sample_rate"] != nil)
                            self.audio_sample_rate = [jsonDict[@"body"][@"audio"][@"sample_rate"] intValue];
                        
                        if(jsonDict[@"body"][@"audio"][@"channels"] != nil)
                            self.audio_channels = [jsonDict[@"body"][@"audio"][@"channels"] intValue];
                        
                        if(jsonDict[@"body"][@"audio"][@"perchannel"] != nil)
                            self.audio_perchannel = [jsonDict[@"body"][@"audio"][@"perchannel"] intValue];
                        
                        if(jsonDict[@"body"][@"audio"][@"buffer_size"] != nil)
                            self.audio_buffer_size = [jsonDict[@"body"][@"audio"][@"buffer_size"] intValue];
                        
                        if(jsonDict[@"body"][@"audio"][@"audio_size"] != nil)
                            self.audio_size = [jsonDict[@"body"][@"audio"][@"audio_size"] floatValue];
                        
                        if(jsonDict[@"body"][@"video"][@"frame_size"] != nil)
                            self.frame_size = [jsonDict[@"body"][@"video"][@"frame_size"] intValue];
                        
                        if(jsonDict[@"body"][@"video"][@"fps"] != nil)
                            self.fps = [jsonDict[@"body"][@"video"][@"fps"] intValue];

                        self.auth_result_ = true;
                    }
                    else
                    {
                        self.auth_result_ = false;
                    }
                }
                else
                {
                    self.auth_result_ = false;
                }
            }
            else
            {
                NSLog(@"userAuth interface Failed statusCode=%d", (int)httpResponse.statusCode);
                self.auth_result_ = false;
            }
        }
        dispatch_semaphore_signal(authSemaphore);
     }];
    
    [task resume];
    dispatch_semaphore_wait(authSemaphore, DISPATCH_TIME_FOREVER);
    
    return _auth_result_;
}

-(bool)setStream :(NSString*)uid
                 :(NSString*)session
                 :(NSString*)key
{
    _setStream_result_ = false;
    dispatch_semaphore_t setSemaphore = dispatch_semaphore_create(0);
    
    //设置访问的url地址
    NSString* setRequest = [NSString stringWithFormat:@"http://%@%@/setStream?uid=%@&session=%@&key=%@",
                            uri,
                            uri_port,
                            uid,
                            session,
                            key];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:setRequest]
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:5.0];
        
    NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable connectionError)
    {
        //判断链接是否失败
        if (connectionError)
        {
            NSLog(@"连接错误 %@", connectionError);
            self.setStream_result_ = false;
        }
        else
        {
            //拿到返回内容
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (200 == httpResponse.statusCode ||304 == httpResponse.statusCode)
            {
                // 序列化json格式
                NSError *error = nil;
                NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                            options:NSJSONReadingMutableContainers
                                                                              error:&error];
                if (error == nil)
                {
                    //可以进行json解析，开始得到解析后的数据
                    self.response_result = [[jsonDict valueForKey:@"result"] intValue];

                    //没有失败，可以获取数据
                    if(200 == self.response_result)
                        self.setStream_result_ = true;
                    else
                        self.setStream_result_ = false;
                }
                else
                {
                    self.setStream_result_ = false;
                }
            }
            else
            {
                NSLog(@"userAuth interface Failed statusCode=%d", (int)httpResponse.statusCode);
                self.setStream_result_ = false;
            }
        }
        
        dispatch_semaphore_signal(setSemaphore);
     }];
    [task resume];
    dispatch_semaphore_wait(setSemaphore, DISPATCH_TIME_FOREVER);
    
    return self.setStream_result_;
}


//返回的json格式为：
/*
 {
     "result": 200,
     "body": {
         "media": {
             "media_ip": "10.10.50.98",
             "media_port": 41002,
             "media_rate": 1.3
         },
         "audio": {
             "sample_rate": 44100,
             "channels": 1,
             "perchannel": 16,
             "buffer_size": 2048,
             "audio_size": 1024
         },
         "video": {
             "frame_size": 1024,
             "fps": 30
         }
     }
 }
 */
-(bool)getStream :(NSString*)uid
                 :(NSString*)session
                 :(NSString*)destUid
                 :(NSString*)key
{
    _getStream_result_ = false;
    dispatch_semaphore_t getSemaphore = dispatch_semaphore_create(0);
    
    //设置访问的url地址
    NSString* getRequest = [NSString stringWithFormat:@"http://%@%@/getStream?uid=%@&session=%@&destUid=%@&key=%@",
                            uri,
                            uri_port,
                            uid,
                            session,
                            destUid,
                            key];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:getRequest]
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:5.0];
    
    NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable connectionError)
    {
        //判断链接是否失败
        if (connectionError)
        {
            NSLog(@"连接错误 %@", connectionError);
            self.getStream_result_ = false;
        }
        else
        {
            //拿到返回内容
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (200 == httpResponse.statusCode ||304 == httpResponse.statusCode)
            {
                // 序列化json格式
                NSError *error = nil;
                NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&error];
                
                if (error == nil)
                {
                    //可以进行json解析，开始得到解析后的数据
                    _response_result = [[jsonDict valueForKey:@"result"] intValue];

                    //没有失败，可以获取数据
                    if(200 == _response_result)
                    {
                        //开始获取所有信息;
                       _media_remote_ip = [jsonDict[@"body"][@"media"][@"media_ip"] mutableCopy];
                        if(jsonDict[@"body"][@"media"][@"media_port"] != nil)
                            _media_remote_port = [jsonDict[@"body"][@"media"][@"media_port"] intValue];
                        
                        if(jsonDict[@"body"][@"media"][@"media_rate"] != nil)
                            _media_rate = [jsonDict[@"body"][@"media"][@"media_rate"] floatValue];
                        
                        if(jsonDict[@"body"][@"audio"][@"sample_rate"] != nil)
                            _audio_sample_rate = [jsonDict[@"body"][@"audio"][@"sample_rate"] intValue];
                        
                        if(jsonDict[@"body"][@"audio"][@"channels"] != nil)
                            _audio_channels = [jsonDict[@"body"][@"audio"][@"channels"] intValue];
                        
                        if(jsonDict[@"body"][@"audio"][@"perchannel"] != nil)
                            _audio_perchannel = [jsonDict[@"body"][@"audio"][@"perchannel"] intValue];
                        
                        if(jsonDict[@"body"][@"audio"][@"buffer_size"] != nil)
                            _audio_buffer_size = [jsonDict[@"body"][@"audio"][@"buffer_size"] intValue];
                        
                        if(jsonDict[@"body"][@"audio"][@"audio_size"] != nil)
                            _audio_size = [jsonDict[@"body"][@"audio"][@"audio_size"] floatValue];
                        
                        if(jsonDict[@"body"][@"video"][@"frame_size"] != nil)
                            _frame_size = [jsonDict[@"body"][@"video"][@"frame_size"] intValue];
                        
                        if(jsonDict[@"body"][@"video"][@"fps"] != nil)
                            _fps = [jsonDict[@"body"][@"video"][@"fps"] intValue];

                        _getStream_result_ = true;
                    }
                    else
                    {
                        _getStream_result_ = false;
                    }
                }
                else
                {
                    _getStream_result_ = false;
                }
            }
            else
            {
                NSLog(@"userAuth interface Failed statusCode=%d", (int)httpResponse.statusCode);
                _auth_result_ = false;
            }
        }
        dispatch_semaphore_signal(getSemaphore);
        
     }];
    [task resume];
    dispatch_semaphore_wait(getSemaphore, DISPATCH_TIME_FOREVER);
    
    return _getStream_result_;
}

-(void)keepAlive:(NSString*)roomName
                :(NSString*)userName
{
    dispatch_semaphore_t aliveSemaphore = dispatch_semaphore_create(0);
    
    //设置访问的url地址
    NSString* aliveRequest = [NSString stringWithFormat:@"http://%@%@/keepAlive?roomName=%@&userName=%@",
                              uri,
                              uri_port,
                              roomName,
                              userName];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:aliveRequest]
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                         timeoutInterval:5.0];
    
    NSURLSessionDataTask * task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable connectionError)
    {
        //判断链接是否失败
        if (connectionError)
        {
            NSLog(@"连接错误 %@", connectionError);
        }
        else
        {
            //拿到返回内容
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (200 == httpResponse.statusCode ||304 == httpResponse.statusCode)
            {
                // 序列化json格式
                NSError *error = nil;
                NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&error];
                
                if (error == nil)
                {
                    //可以进行json解析，开始得到解析后的数据
                    _response_result = [[jsonDict valueForKey:@"result"] intValue];
                }
            }
            else
            {
                NSLog(@"keepAlive interface Failed statusCode=%d", (int)httpResponse.statusCode);
            }
        }
        dispatch_semaphore_signal(aliveSemaphore);
        
     }];
    [task resume];
    dispatch_semaphore_wait(aliveSemaphore, DISPATCH_TIME_FOREVER);
    
    return ;
}

@end
