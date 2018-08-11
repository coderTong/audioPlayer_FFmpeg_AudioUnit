//
//  STFFmpegLocalAudioDecoder.m
//  01AudioPlayerMe
//
//  Created by codew on 2018/7/31.
//  Copyright © 2018年 codew. All rights reserved.
//

#import "STFFmpegLocalAudioDecoder.h"
#define OUT_PUT_CHANNELS 2
#define STMAX(a, b)  (((a) > (b)) ? (a) : (b))
#define STMIN(a, b)  (((a) < (b)) ? (a) : (b))

@interface STFFmpegLocalAudioDecoder()
{
    
    AVFormatContext* _avFormatContext;
    AVCodecContext * _avCodecContext;
    short* _audioBuffer;
    SwrContext *_swrContext;
    void * _swrBuffer;
    AVFrame *_pAudioFrame;
    
    int _stream_index;
    float _timeBase;
    int _swrBufferSize;
    AVPacket _packet;
    int _audioBufferCursor;
    int _audioBufferSize;
    


}

@property (nonatomic, copy) NSString * audioFileStr;

@end

@implementation STFFmpegLocalAudioDecoder

- (instancetype)initWithAudioFile:(NSString *)audioFileStr
{
    
    self = [super init];
    if (self) {
        
        _audioFileStr = audioFileStr;
        [self ffmpegInitWithAudioFile:audioFileStr];
        
    }
    
    
    return self;
}

- (void)ffmpegInitWithAudioFile:(NSString *)audioFileStr
{
    avcodec_register_all();
    av_register_all();
    
    _avFormatContext = avformat_alloc_context();
    
    int result = avformat_open_input(&_avFormatContext,
                                     [audioFileStr UTF8String],
                                     NULL,
                                     NULL);
    if (result != 0) {
        
        NSLog(@"[error 💣](avformat_open_input)打开文件出错, 文件:%@, 结果:%d", audioFileStr, result);
        
        return;
    }else{
        
        NSLog(@"[success 🎉](avformat_open_input )打开文件成功, 文件:%@, 结果:%d", audioFileStr, result);
    }
    
    // TODO:不知道这句干嘛...最大持续shi'j
    _avFormatContext->max_analyze_duration = 50000;
    
    
    result = avformat_find_stream_info(_avFormatContext, NULL);
    if (result < 0) {
        
        NSLog(@"[error 💣]fail avformat_find_stream_info result is %d", result);
        return;
    }else{
        
        NSLog(@"sucess avformat_find_stream_info result is %d", result);
    }
    
    _stream_index = av_find_best_stream(_avFormatContext,
                                        AVMEDIA_TYPE_AUDIO,
                                        -1,
                                        -1,
                                        NULL,
                                        0);
    if (_stream_index == -1) {
        
        NSLog(@"没有音频流...");
        return;
    }
    
    // 音频流
    AVStream *audioStream = _avFormatContext->streams[_stream_index];
    if (audioStream->time_base.den && audioStream->time_base.num) {
        
        _timeBase = av_q2d(audioStream->time_base);
    }else if (audioStream->codec->time_base.den && audioStream->codec){
        
        _timeBase = av_q2d(audioStream->codec->time_base);
    }
    
    // 获得音频流的解码器上下文
    _avCodecContext = audioStream->codec;
    // 根据解码器上下文找到解码器
    AVCodec *avCodec = avcodec_find_decoder(_avCodecContext->codec_id);
    
    if (avCodec == NULL) {
        NSLog(@"[error 💣]找不到解码器, avcodec_find_decoder");
        return;
    }
    
    
    // 打开解码器
    result = avcodec_open2(_avCodecContext, avCodec, NULL);
    
    if (result < 0) {
        
        NSLog(@"打开解码器失败...., %d", result);
        return;
        
    }else{
        
        NSLog(@"成功打开解码器...., %d", result);
    }
    
    
    // 4.判断是否需要重新采样 resampler
    if ( ![self audioCodecIsSupported] ) {
        
        NSLog(@"because of audio Codec Is Not Supported so we will init swresampler...");
        
        
        _swrContext = swr_alloc_set_opts(NULL,
                                         av_get_default_channel_layout(OUT_PUT_CHANNELS),
                                         AV_SAMPLE_FMT_S16,
                                         _avCodecContext->sample_rate,
                                         av_get_default_channel_layout(_avCodecContext->channels),
                                         _avCodecContext->sample_fmt,
                                         _avCodecContext->sample_rate,
                                         0,
                                         NULL);
        
        if (!_swrContext || swr_init(_swrContext)) {
            
            if (_swrContext) {
                swr_free(&_swrContext);
            }
            
            avcodec_close(_avCodecContext);
            NSLog(@"初始化重采样失败");
            return;
        }
    }
    
    NSLog(@"channels is %d sampleRate is %d", _avCodecContext->channels, _avCodecContext->sample_rate);
    
    _pAudioFrame = av_frame_alloc();
    
    
}

- (BOOL)audioCodecIsSupported
{
    
    if (_avCodecContext->sample_fmt == AV_SAMPLE_FMT_S16) {
        
        return YES;
    }else{
        return NO;
    }
}

- (STBSRateObjc *)getMusicMeta
{
    STBSRateObjc * bsObj = [[STBSRateObjc alloc] init];
    bsObj.sampleRate = _avCodecContext->sample_rate;
    bsObj.bitRate = _avCodecContext->bit_rate;
    
    return bsObj;
}

- (STAudioLocalPacket *)decodePacket
{
    
    short *samples = (short *)malloc( _packetBufferSize*sizeof(short) );
    int stereoSampleSize = [self readSamples:samples size:_packetBufferSize];
    STAudioLocalPacket *samplePacket = [[STAudioLocalPacket alloc] init];
    
    if (stereoSampleSize > 0) {
        
        // 构造成一个packet
        samplePacket->_buffer = samples;
        samplePacket->_size = stereoSampleSize;
        
    }else{
        
        samplePacket->_size = -1;
        
    }
    
    return samplePacket;
}


- (int)readSamples:(short *)samples size:(int)size
{
    int samplesSize = size;
    
    while (size > 0) {
        
        if (_audioBufferCursor < _audioBufferSize) {
            
            int audioBufferDataSize = _audioBufferSize - _audioBufferCursor;
            int copySize = STMIN(size, audioBufferDataSize);
            
            memcpy(samples + (samplesSize - size), _audioBuffer + _audioBufferCursor, copySize * 2);
            
            size -= copySize;
            
            _audioBufferCursor += copySize;
        }else{
            
            if ([self readFrame] < 0) {
                break;
            }
            
        }
    }
    
    int fillSize = samplesSize - size;
    if (fillSize == 0) {
        return -1;
    }
    
    return fillSize;
}


- (int)readFrame{
    
    int ret = 1;
    
    av_init_packet(&_packet);
    int gotFrame = 0;
    int readFrameCode = -1;
    
    while (1) {
        readFrameCode = av_read_frame(_avFormatContext, &_packet);
        if (readFrameCode >= 0) {
            
            if (_packet.stream_index == _stream_index) {
                
                int len = avcodec_decode_audio4(_avCodecContext, _pAudioFrame, &gotFrame, &_packet);
                if (len < 0){
                    
                    NSLog(@"decode audio error, skip packet");
                }
                
                if (gotFrame) {
                    
                    int numChannels = OUT_PUT_CHANNELS;
                    int numFrames = 0;
                    void *audioData;
                    
                    if (_swrContext) {
                        
                        const int ratio = 2;
                        const int bufSize = av_samples_get_buffer_size(NULL,
                                                                       numChannels,
                                                                       _pAudioFrame->nb_samples * ratio,
                                                                       AV_SAMPLE_FMT_S16,
                                                                       1);
                        if (!_swrBuffer || _swrBufferSize < bufSize) {
                            
                            _swrBufferSize = bufSize;
                            _swrBuffer = realloc(_swrBuffer, _swrBufferSize);
                        }
                        
                        Byte *outbuf[2] = {(Byte *) _swrBuffer, NULL};
                        numFrames = swr_convert(_swrContext,
                                                outbuf,
                                                _pAudioFrame->nb_samples *ratio,
                                                (const uint8_t **)_pAudioFrame->data,
                                                _pAudioFrame->nb_samples);
                        if (numFrames < 0) {
                            
                            NSLog(@"fail resample audio");
                            ret = -1;
                            break;
                        }
                        audioData = _swrBuffer;
                    }else{
                        
                        if (_avCodecContext->sample_fmt != AV_SAMPLE_FMT_S16) {
                            
                            NSLog(@"bucheck, audio format is invalid");
                            ret = -1;
                            break;
                        }
                        
                        audioData = _pAudioFrame->data[0];
                        numFrames = _pAudioFrame->nb_samples;
                        
                    }
                    
                    _audioBufferSize = numFrames * numChannels;
                    _audioBuffer = (short *)audioData;
                    _audioBufferCursor = 0;
                    break;
                    
                    
                }
                
            }
            
        }else{
            
            ret = -1;
            break;
        }
    }
    
    av_free_packet(&_packet);
    return ret;
    
}


- (NSInteger)getChannels
{
    int channels = -1;
    if(_avCodecContext) {
        channels = _avCodecContext->channels;
    }
    return channels;
}
- (NSInteger)getAudioSampleRate
{
    int sampleRate = -1;
    if(_avCodecContext) {
        sampleRate = _avCodecContext->sample_rate;
    }
    return sampleRate;
}


- (void)dealloc
{
    if (_swrContext) {
        
        swr_free(&_swrContext);
        _swrContext = NULL;
    }
    
    if (_pAudioFrame) {
        
        av_free(_pAudioFrame);
        _pAudioFrame = NULL;
    }
    
    if (_avCodecContext) {
        
        avcodec_close(_avCodecContext);
        _avCodecContext = NULL;
    }
    
    if ( _avFormatContext) {
        
        avformat_close_input(&_avFormatContext);
        _avFormatContext = NULL;
    }
    
}

@end
