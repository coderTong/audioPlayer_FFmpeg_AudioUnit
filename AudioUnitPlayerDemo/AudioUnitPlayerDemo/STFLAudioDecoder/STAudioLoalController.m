//
//  STAudioLoalController.m
//  01AudioPlayerMe
//
//  Created by codew on 2018/8/2.
//  Copyright © 2018年 codew. All rights reserved.
//

#import "STAudioLoalController.h"
#import "STMediaCache.h"

#define CHANNEL_PER_FRAME    2
#define BITS_PER_CHANNEL        16
#define BITS_PER_BYTE        8

@interface STAudioLoalController()
{
    STFFmpegLocalAudioDecoder * _deCoder;
    STAudioLocalPacket *_currentAccompanyPacket;
    int _currentAccompanyPacketCursor;

}

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) float playPosition;

/** 采样率和每个packet的大小 */
@property (nonatomic, assign) int audioSampleRate;
@property (nonatomic, assign) int packetBufferSize;

@property (nonatomic, strong) STMediaCache * audioCache;

@end

@implementation STAudioLoalController


- (instancetype)initWith:(NSString *)filePath packetBufferTimePercent:(float)packetBufferTimePercent
{
    self = [super init];
    
    if (self) {
        
        _filePath = filePath;
        _playPosition = 0.0f;
        
        _deCoder = [[STFFmpegLocalAudioDecoder alloc] initWithAudioFile:filePath];
        STBSRateObjc * bsObj = [_deCoder getMusicMeta];
        
        _audioSampleRate = bsObj.sampleRate;
        
        int audioByteCountPerSec = _audioSampleRate * CHANNEL_PER_FRAME * BITS_PER_CHANNEL / BITS_PER_BYTE;
        _packetBufferSize = (int) ( ( audioByteCountPerSec / 2 ) * packetBufferTimePercent);
        
        _deCoder.packetBufferSize = _packetBufferSize;
        
        [self doStartDecoder];
        
    }
    return self;
}


- (NSInteger)getChannels
{
    return [_deCoder getChannels];
}

- (NSInteger)getAudioSampleRate
{
    return [_deCoder getAudioSampleRate];
}


+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        NSLog(@".....pp[[[");
        [[NSThread currentThread] setName:@"AFNetworking"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}


- (void)doStartDecoder
{
    
    [self performSelector:@selector(startDecoder) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
}


- (void)startDecoder
{
    while (self.audioCache.getQueueCount < self.audioCache.capacity) {
        // 解码线程.....
        STAudioLocalPacket *packet = [_deCoder decodePacket];
        [self.audioCache publish:packet];
//        NSLog(@"🐲---------%d", self.audioCache.getQueueCount);
    }
    
}

- (int)readSamples:(short *)samples size:(int)size
{
    int result = -1;
    int fillCuror = 0;
    int sampleCursor = 0;
    
    while (fillCuror < size) {
        
        int samplePacketSize = 0;
        
        if (_currentAccompanyPacket && _currentAccompanyPacketCursor == _currentAccompanyPacket->_size) {
            
            _currentAccompanyPacket = nil;
        }
        
        if (_currentAccompanyPacket  && _currentAccompanyPacketCursor < _currentAccompanyPacket->_size) {
        
            int subSize = size - fillCuror;
            samplePacketSize = MIN(_currentAccompanyPacket->_size - _currentAccompanyPacketCursor, subSize);
            
            memcpy(samples + fillCuror, _currentAccompanyPacket->_buffer + _currentAccompanyPacketCursor, samplePacketSize * 2);
        }else{
            
            _currentAccompanyPacket = [self.audioCache consume];
            _currentAccompanyPacketCursor = 0;
            
            if (NULL != _currentAccompanyPacket && _currentAccompanyPacket->_size > 0) {
                
                samplePacketSize = size - fillCuror;
                memcpy(samples + fillCuror, _currentAccompanyPacket->_buffer + _currentAccompanyPacketCursor, samplePacketSize * 2);
            }else{
                
                result = -2;
                break;
            }
        }
        
        _currentAccompanyPacketCursor += samplePacketSize;
        fillCuror += samplePacketSize;
        
    }
    
    if (self.audioCache.getQueueCount < 20) {
        
//        NSLog(@"快没音频数据了去加货,,,,,,🐲");
        
        [self doStartDecoder];
    }
    
    
    return result;
    
}

- (STMediaCache *)audioCache
{
    if (!_audioCache) {
        NSInteger packetsPerSecond = self.audioSampleRate / 1024;// 1 aac frame usually have 1024 pcm samples.
        
        _audioCache = [[STMediaCache alloc] initWithCap:packetsPerSecond markCap:0 timeout:1.0];
    }
    
    return _audioCache;
}

@end


































