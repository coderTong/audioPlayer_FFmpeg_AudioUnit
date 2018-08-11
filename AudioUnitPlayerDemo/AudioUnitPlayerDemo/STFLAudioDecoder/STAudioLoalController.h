//
//  STAudioLoalController.h
//  01AudioPlayerMe
//
//  Created by codew on 2018/8/2.
//  Copyright © 2018年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STFFmpegLocalAudioDecoder.h"

@interface STAudioLoalController : NSObject

- (instancetype)initWith:(NSString *)filePath packetBufferTimePercent:(float)packetBufferTimePercent;

- (NSInteger)getChannels;
- (NSInteger)getAudioSampleRate;

- (int)readSamples:(short *)samples size:(int)size;
@end
