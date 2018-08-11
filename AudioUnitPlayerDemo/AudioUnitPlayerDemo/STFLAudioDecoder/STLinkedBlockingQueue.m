//
//  STLinkedBlockingQueue.m
//  01AudioPlayerMe
//
//  Created by codew on 2018/8/2.
//  Copyright © 2018年 codew. All rights reserved.
//

#import "STLinkedBlockingQueue.h"

@interface STLinkedNode : NSObject

@property(nonatomic, strong) id data;
@property(nonatomic, strong) STLinkedNode *next;
@property(nonatomic, assign) BOOL mark;

-(instancetype) initWithData:(id) data andMark:(BOOL) mark;

@end

@implementation STLinkedNode
@synthesize data, next;

-(instancetype)init {
    self = [super init];
    if(self) {
        self.mark = NO;
    }
    
    return self;
}

-(instancetype)initWithData:(id)aData andMark:(BOOL)aMark {
    self = [super init];
    if(self) {
        self.data = aData;
        self.mark = aMark;
    }
    
    return self;
}

@end


@interface STLinkedBlockingQueue ()
{
    STLinkedNode *_first;
    STLinkedNode *_last;
    NSConditionLock *_lock;
    NSUInteger _nodeCount;
    NSUInteger _markCount;
}

@end

#define LIST_EMPTY 1
#define LIST_HASELE 2


@implementation STLinkedBlockingQueue


-(instancetype)init {
    self = [super init];
    if(self) {
        _first = nil;
        _last = nil;
        _lock = [[NSConditionLock alloc] initWithCondition:LIST_EMPTY];
        _nodeCount = 0;
        _markCount = 0;
    }
    
    return self;
}

-(void)put:(id)data {
    [_lock lock];
    
    [self unblockedPut:data withMark:YES];
    
    [_lock unlockWithCondition:LIST_HASELE];
}

-(id)takeWithTimeout:(NSTimeInterval)timeout {
    if([_lock lockWhenCondition:LIST_HASELE beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]]) {
        
        id ret = [self unblockedTake];
        [_lock unlockWithCondition:(_first ? LIST_HASELE : LIST_EMPTY)];
        
        return ret;
    }
    
    return nil;
}

-(void)put:(id)data withMark:(BOOL)mark {
    [_lock lock];
    
    [self unblockedPut:data withMark:mark];
    
    [_lock unlockWithCondition:LIST_HASELE];
}

-(void)poll {
    [_lock lockWhenCondition:LIST_HASELE];
    
    if(_first) {
        if(_first.mark) {
            _markCount--;
        }
        _first = _first.next;
        if(!_first) {
            _last = nil;
        }
        _nodeCount--;
    }
    
    [_lock unlockWithCondition:(_first ? LIST_HASELE : LIST_EMPTY)];
}

-(void)removeAll {
    [_lock lock];
    
    [self unblockedRemoveAll];
    
    [_lock unlockWithCondition:LIST_EMPTY];
}

-(NSUInteger)count {
    return _nodeCount;
}

-(NSUInteger)markCount {
    return _markCount;
}

-(id)peek {
    
    [_lock lock];
    
    id ret = [self unblockPeek];
    
    [_lock unlockWithCondition:LIST_HASELE];
    
    return ret;
    
}

-(id)unblockPeek {
    
    if(_first) {
        return _first.data;
    } else {
        return nil;
    }
    
}


-(void)unblockedPut:(id)data withMark:(BOOL)mark {
    
    [self addNode:[[STLinkedNode alloc] initWithData:data andMark:mark]];
    
    if(mark) {
        _markCount++;
    }
}

-(id)unblockedTake {
    if(_first) {
        id ret = _first.data;
        if(_first.mark) {
            _markCount--;
        }
        _first = _first.next;
        if(!_first) {
            _last = nil;
        }
        _nodeCount--;
        
        return ret;
    }
    
    return nil;
}

-(void)unblockedRemoveAll {
    _first = nil;
    _last = nil;
    _nodeCount = 0;
    _markCount = 0;
}

#pragma mark - Private Function

-(void) addNode:(STLinkedNode *) node {
    if(_last) {
        _last.next = node;
    }
    if(!_first) {
        _first = node;
    }
    _last = node;
    _nodeCount++;
}


@end
