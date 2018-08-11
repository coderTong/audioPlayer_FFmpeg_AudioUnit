//
//  ST_AudioPlayer.h
//  01AudioPlayerMe
//
//  Created by codew on 2018/7/25.
//  Copyright © 2018年 codew. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ST_AudioPlayer : NSObject

- (id)initWithFilePath:(NSString *)filePath;

- (void)start;

- (void)stop;

@end
