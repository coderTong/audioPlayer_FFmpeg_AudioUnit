//
//  STMediaCache.m
//  01AudioPlayerMe
//
//  Created by codew on 2018/8/2.
//  Copyright © 2018年 codew. All rights reserved.
//

#import "STMediaCache.h"


@interface STMediaCache ()

@property(nonatomic, strong) STLinkedBlockingQueue *queue;

@end

@implementation STMediaCache


-(instancetype)init {
    
    return [self initWithCap:DEFAULT_ST_MEDIACACHE_CAP markCap:DEFAULT_ST_MEDIACACHE_MARK_CAP timeout:DEFAULT_ST_MEDIACACHE_TIMEOUT];
}

-(instancetype)initWithCap:(NSInteger)cap markCap:(NSInteger)markCap timeout:(NSTimeInterval)aTimeout{
    self = [super init];
    if(self) {
        self.capacity = cap;
        self.markCapacity = markCap;
        self.queue = [[STLinkedBlockingQueue alloc] init];
    }
    
    return self;
}


-(void)publish:(STAudioLocalPacket *)frame {
    
    [self.queue put:frame withMark:NO];
}

-(STAudioLocalPacket *)consume {
    
    return [self.queue takeWithTimeout:DEFAULT_ST_MEDIACACHE_TIMEOUT];
}

- (STAudioLocalPacket *)peek {
    
    return [self.queue peek];
    
}


- (void)removeAll {
    
     [self.queue removeAll];
}


-(NSUInteger) getQueueCount {
    return self.queue.count;
}

@end

