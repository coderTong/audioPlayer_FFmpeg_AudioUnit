//
//  STLinkedBlockingQueue.h
//  01AudioPlayerMe
//
//  Created by codew on 2018/8/2.
//  Copyright © 2018年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STLinkedBlockingQueue : NSObject

#pragma mark - Blocked Opt
-(void)put:(id)data;
-(id) takeWithTimeout:(NSTimeInterval)timeout;
-(void)put:(id)data withMark:(BOOL)mark;
-(void)poll;
-(void)removeAll;

#pragma mark - Unblocked Opt
-(NSUInteger)count;
-(NSUInteger)markCount;
-(id)peek;
-(id)unblockPeek;

-(void)unblockedPut:(id)data withMark:(BOOL) mark;
-(id)unblockedTake;
-(void)unblockedRemoveAll;

@end
