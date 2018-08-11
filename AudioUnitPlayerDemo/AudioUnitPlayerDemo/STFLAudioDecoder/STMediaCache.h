//
//  STMediaCache.h
//  01AudioPlayerMe
//
//  Created by codew on 2018/8/2.
//  Copyright © 2018年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STAudioLocalPacket.h"
#import "STLinkedBlockingQueue.h"

#define DEFAULT_ST_MEDIACACHE_CAP_ZERO 0
#define DEFAULT_ST_MEDIACACHE_CAP 80
#define DEFAULT_ST_MEDIACACHE_MARK_CAP 2
#define DEFAULT_ST_MEDIACACHE_TIMEOUT 1.0

@class STMediaCache;

@protocol STMediaCacheDelegate <NSObject>

@optional
-(void) onDataAvaiable:(STMediaCache *) cache;

@end


@interface STMediaCache : NSObject

@property(nonatomic, assign) NSInteger capacity;
@property(nonatomic, assign) NSInteger markCapacity;

@property(nonatomic, weak) id<STMediaCacheDelegate> delegate;

/**
 * Use '0' to disable buffer clean on cap or markCap.
 */
-(instancetype) initWithCap:(NSInteger) cap markCap:(NSInteger) markCap timeout:(NSTimeInterval) timeout;


/** When this funciton is called on serialOperationQueue, it will trigge the delegate if new data pulled into the cache; otherwise, no delegate action will be trigged.
 */
-(void) publish:(STAudioLocalPacket *) frame;

/** When this function is called on serialOperationQueue, it will return nil immediately if the cache is empty; otherwise, it will block the current queue till the timeout if the cache is empty, or return data as soon as data avaiable in the cache.
 */
-(STAudioLocalPacket *) consume;


- (STAudioLocalPacket *)peek;


- (void)removeAll;


-(NSUInteger) getQueueCount;

@end
