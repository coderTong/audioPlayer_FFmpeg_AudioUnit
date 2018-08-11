//
//  STBSRateObjc.h
//  01AudioPlayerMe
//
//  Created by codew on 2018/8/2.
//  Copyright © 2018年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 码率 采样率 对象
 */

@interface STBSRateObjc : NSObject

@property (nonatomic, assign) long long bitRate;
@property (nonatomic, assign) int sampleRate;

@end
