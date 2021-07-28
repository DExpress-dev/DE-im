//
//  video_decoder.h
//  video_decoder
//
//  Created by fxh7622 on 17/3/19.
//  Copyright © 2017年 张大圣. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

//音频编码;
typedef NS_ENUM(NSInteger, encoder_type)
{
    et_hardware = 0,    //硬编码;
    et_software = 1     //软编码;
};

//音频解码;
typedef NS_ENUM(NSInteger, decoder_type)
{
    dt_hardware = 0,    //硬解码;
    dt_software = 1     //软解码;
};

//音频编码后数据;
typedef struct
{
    void *data;
    UInt32 mChannels;
    UInt32 mDataBytesSize;
} EncodedAudioBuffer;

//音频编码类;
@interface audio_encoder : NSObject
{
}

-(void) initEncoder:(uint32_t)sampleRate :(uint32_t)channels :(uint32_t)frameSize :(uint32_t)bitRate :(encoder_type)encoderType;
-(int) EncodeAACELD :(AudioBuffer)inSamples :(EncodedAudioBuffer*)outData;
- (void) deleteEncoder;
@end

//音频解码类;
@interface audio_decoder : NSObject
{
}

-(void) initDecoder:(uint32_t)sampleRate :(uint32_t)channels :(uint32_t)frameSize :(decoder_type)decoderType;
-(int) DecodeAACELD :(EncodedAudioBuffer)inData :(AudioBuffer*)outSamples;
-(int) DecodeAACELD :(void*)inData :(int)inDataSize :(AudioBuffer*)outSamples;
- (void) deleteDecoder;
@end




