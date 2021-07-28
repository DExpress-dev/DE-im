//
//  tcp_ios.h
//  tcp_ios
//
//  Created by debug on 17/3/22.
//  Copyright © 2017年 张大圣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdio.h>

@protocol ios_tcp_impl_delegate <NSObject>

-(bool)on_read:(char*)buffer :(int)size :(int)linker_handle;
-(void)on_disconnect:(int)linker_handle;
-(void)on_error:(int)error_id :(int)linker_handle;

@end

//ios的tcp网络通信类;
@interface ios_linker : NSObject
{
    
}

//定义对象;
@property (nonatomic, assign) id <ios_tcp_impl_delegate> delegate;

//透出函数;
-(int)begin_client:(char*)remote_ip :(int)remote_port :(int)timeout;
-(int)send_buffer:(char*)buffer :(int)size :(int)linker_handle;
-(void)close_linker:(int)linker_handle;

//单例;
+(instancetype)get_instance;

@end
