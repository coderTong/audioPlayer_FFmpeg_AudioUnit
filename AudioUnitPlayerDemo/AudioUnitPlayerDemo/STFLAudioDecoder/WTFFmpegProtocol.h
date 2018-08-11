//
//  WTFFmpegProtocol.h
//  ffmpegtesOne
//
//  Created by codew on 2018/5/24.
//  Copyright © 2018年 codew. All rights reserved.
//

#import <VideoToolbox/VideoToolbox.h>
#import <AudioToolbox/AudioToolbox.h>
#include <libavformat/avformat.h>
#include <libavutil/avassert.h>
#include <libavutil/channel_layout.h>
#include <libavutil/opt.h>
#include <libavutil/mathematics.h>
#include <libavutil/timestamp.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>
#include <libavutil/imgutils.h>

@protocol WTFFmpegProtocol <NSObject>

@optional

//
- (void)regiterFFmpeg;

/**
 
 生成一个测试封装格式文件
 */
- (BOOL)createTestMediaFileWithPath:(NSString *)path;

/*
 
 解封装, 将封装格式转成pcm和yuv, 然后使用ffplay播放
 */
- (BOOL)demuxingDecodingFormatSourceFilePath:(NSString *)sourceFilePath
                                   audioPath:(NSString *)audioPath
                                   videoPath:(NSString *)videoPath;

/**
 转封装,将一个封装格式文件转成另一种封装格式
 */
- (BOOL)remuxingWithInputFilePath:(NSString *)inputFilePath outputFilePath:(NSString *)outputFilePath;


/**
 视频截取
 
 */
- (BOOL)cutingDurtion:(int64_t)durtion
       sourceFilePath:(NSString *)sourceFilePath
       outputFilePath:(NSString *)outputFilePath;

/**
 利用本地编码数据封装成封装数据
 
 h264 + aac = MP4, flv, avi
 */

- (BOOL)muxingWithAudioEncodeFile:(NSString *)audioEncodeFile
                  videoEncodeFile:(NSString *)videoEncodeFile
                       formatFile:(NSString *)formatFile;

/**
 解码音视频然后吐出PCM给外界
 
 */

@end
