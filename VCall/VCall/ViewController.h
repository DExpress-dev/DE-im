//
//  ViewController.h
//  Demo
//
//  Created by Jessonliu iOS on 2017/2/9.
//  Copyright © 2017年 Jessonliu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "audio.h"
#import "video.h"
#import "audio_play.h"
#import "capture_beautiful.h"
#include "rudp_ios.h"

@interface WatchViewController : UIViewController<capture_beautiful_impl_delegate,
                                                video_encoder_impl_delegate,
                                                video_decoder_impl_delegate,
                                                ios_rudp_impl_delegate>

@end

