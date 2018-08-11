//
//  ST_AudioOutput.h
//  01AudioPlayerMe
//
//  Created by codew on 2018/7/26.
//  Copyright © 2018年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>

// 数据填充, 喂数据
@protocol FillDataOutputDelegate <NSObject>

@optional
- (NSInteger) fillAudioData:(SInt16*) sampleBuffer numFrames:(NSInteger)frameNum numChannels:(NSInteger)channels;


@end

@interface ST_AudioOutput : NSObject


@property (nonatomic, assign) Float64 sampleRate;
@property (nonatomic, assign) Float64 channels;

- (id)initWithChannels:(NSInteger)channels
            sampleRate:(NSInteger)sampleRate
        bytesPerSample:(NSInteger)bytePerSample
      fileDataDelegate:(id<FillDataOutputDelegate>)fileDataDelegate;

- (BOOL)play;
- (void)stop;


@end
