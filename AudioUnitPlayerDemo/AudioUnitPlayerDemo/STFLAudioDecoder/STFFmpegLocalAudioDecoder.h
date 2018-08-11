//
//  STFFmpegLocalAudioDecoder.h
//  01AudioPlayerMe
//
//  Created by codew on 2018/7/31.
//  Copyright © 2018年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WTFFmpegProtocol.h"
#import "STBSRateObjc.h"
#import "STAudioLocalPacket.h"

@interface STFFmpegLocalAudioDecoder : NSObject <WTFFmpegProtocol>

@property (nonatomic, assign)int packetBufferSize;

- (instancetype)initWithAudioFile:(NSString *)audioFileStr;

- (STBSRateObjc *)getMusicMeta;

- (NSInteger)getChannels;
- (NSInteger)getAudioSampleRate;

- (STAudioLocalPacket *)decodePacket;
@end
