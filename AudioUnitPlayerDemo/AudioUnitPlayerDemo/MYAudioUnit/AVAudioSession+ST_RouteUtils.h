//
//  AVAudioSession+ST_RouteUtils.h
//  01AudioPlayerMe
//
//  Created by codew on 2018/7/28.
//  Copyright © 2018年 codew. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVAudioSession (ST_RouteUtils)

- (BOOL)usingBlueTooth;

- (BOOL)usingWiredMicrophone;

- (BOOL)shouldShowEarphoneAlert;

@end
