//
//  ST_AudioSession.h
//  01AudioPlayerMe
//
//  Created by codew on 2018/7/26.
//  Copyright © 2018年 codew. All rights reserved.
/**
 
 音视频开发中, 使用具体API之前需要先创建一个会话
 AVAudioSession * audioSession = [AVAudioSession  sharedInstance];
 
 音频这里一般做一下步骤
 1. 根据我们需要硬件设备提供的能力来设置别
 [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord  error:nil];
 
 
 2. 设置 I/O的buffer , Buffer越小则说明延迟越低
 NSTimeInterval bufferDuration = 0.002;
 [audioSession setPreferredIOBufferDuration:bufferDuration error:nil];

 
 
 3. 设置采样频率, 让硬件设备按照设置的采样频率来采集或者播放音频
 double hwSampleRate = 44100.0;
 [audioSession setPreferredSampleRate:hwSampleRate error:nil];
 
 
 4. 当设置完毕所有的参数之后就可以激活AudioSession了
 [audioSession setActive:YES error:nil];
 _audioSession = audioSession;
 
 
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface ST_AudioSession : NSObject

+ (ST_AudioSession *)sharedInstance;

@property(nonatomic, strong) AVAudioSession *audioSession; // Underlying system audio session
@property(nonatomic, assign) Float64 preferredSampleRate;
@property(nonatomic, assign, readonly) Float64 currentSampleRate;
@property(nonatomic, assign) NSTimeInterval preferredLatency;
@property(nonatomic, assign) BOOL active;
@property(nonatomic, strong) NSString *category;

- (void)addRouteChangeListener;

@end




















