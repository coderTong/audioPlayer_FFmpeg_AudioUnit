//
//  STAudioLocalPacket.m
//  01AudioPlayerMe
//
//  Created by codew on 2018/8/2.
//  Copyright © 2018年 codew. All rights reserved.
//

#import "STAudioLocalPacket.h"

@implementation STAudioLocalPacket

- (instancetype)init
{
    self = [super init];
    if (self) {
        _buffer = NULL;
        _size = 0;
    }
    return self;
}


- (void)dealloc
{
//    NSLog(@"%s", __func__);
    free(_buffer);
}

@end
