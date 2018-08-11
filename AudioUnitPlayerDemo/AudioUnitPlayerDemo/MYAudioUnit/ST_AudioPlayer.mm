//
//  ST_AudioPlayer.m
//  01AudioPlayerMe
//
//  Created by codew on 2018/7/25.
//  Copyright © 2018年 codew. All rights reserved.
//

#import "ST_AudioPlayer.h"
#import "ST_AudioOutput.h"
#import "STAudioLoalController.h"

@interface ST_AudioPlayer()<FillDataOutputDelegate>
{
    ST_AudioOutput* _audioOutput;
//    AccompanyDecoderController*             _decoderController;
    
    
    
    STAudioLoalController * _dec;
}

@end

@implementation ST_AudioPlayer

- (id)initWithFilePath:(NSString *)filePath
{
    self = [super init];
    
    if (self){
       
//        [self oldDe:filePath];
        
        _dec = [[STAudioLoalController alloc] initWith:filePath packetBufferTimePercent:0.2f];
        
        NSInteger channels = [_dec getChannels];
        NSInteger samleRate = [_dec getAudioSampleRate];
        // 采样深度
        NSInteger bytesPersample = 2;
        
        _audioOutput = [[ST_AudioOutput alloc] initWithChannels:channels
                                                     sampleRate:samleRate
                                                 bytesPerSample:bytesPersample
                                               fileDataDelegate:self];
    }
    
    return self;
}

- (void)oldDe:(NSString *)filePath{
    
//    // 初始化解码模块, 并且从解码模块中取出原始数据
//    _decoderController = new AccompanyDecoderController();
//    _decoderController->init([filePath cStringUsingEncoding:NSUTF8StringEncoding], 0.2f);
//
//    NSInteger channels = _decoderController->getChannels();
//    NSInteger samleRate = _decoderController->getAudioSampleRate();
//    // 采样深度
//    NSInteger bytesPersample = 2;
//
//    _audioOutput = [[ST_AudioOutput alloc] initWithChannels:channels
//                                                 sampleRate:samleRate
//                                             bytesPerSample:bytesPersample
//                                           fileDataDelegate:self];
}

- (void)start
{
    if (_audioOutput) {
        
        [_audioOutput play];
    }
}

- (void)stop
{
    // 停止AudioOutput
    if (_audioOutput) {
        [_audioOutput stop];
        _audioOutput = nil;
    }
    
//    // 停止解码模块
//    if (NULL != _decoderController) {
//        
//        _decoderController->destroy();
//        
//        delete _decoderController;
//        _decoderController = NULL;
//    }
}


- (NSInteger)fillAudioData:(SInt16 *)sampleBuffer numFrames:(NSInteger)frameNum numChannels:(NSInteger)channels

{
//    memset(sampleBuffer, 0, frameNum * channels * sizeof(SInt16));
//
//    if (_decoderController) {
//
//        NSLog(@"~~~,,%zd", frameNum);
//
//        _decoderController->readSamples(sampleBuffer, (int)(frameNum *channels));
//    }
    
//    NSLog(@"======>");
    
    memset(sampleBuffer, 0, frameNum * channels * sizeof(SInt16));
    
    if (_dec) {
        
        
        [_dec readSamples:sampleBuffer size:(int)(frameNum *channels)];
    }
    
    return 1;
}

@end
