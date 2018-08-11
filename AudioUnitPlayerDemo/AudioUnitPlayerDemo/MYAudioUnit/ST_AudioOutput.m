//
//  ST_AudioOutput.m
//  01AudioPlayerMe
//
//  Created by codew on 2018/7/26.
//  Copyright © 2018年 codew. All rights reserved.
//

#import "ST_AudioOutput.h"

#import <AudioToolbox/AudioToolbox.h>
//#import <Accelerate/Accelerate.h>
#import "ST_AudioSession.h"
#import "CommonUtil.h"


static const AudioUnitElement inputElement = 1;

static OSStatus STInputRenderCallback(void * inRefCon,
                                      AudioUnitRenderActionFlags *    ioActionFlags,
                                      const AudioTimeStamp *            inTimeStamp,
                                      UInt32                            inBusNumber,
                                      UInt32                            inNumberFrames,
                                      AudioBufferList * __nullable    ioData);
static void CheckStatus(OSStatus status, NSString *message, BOOL fatal);

@interface ST_AudioOutput(){
    
    SInt16 *_outData;
}

@property (nonatomic, assign) AUGraph auGraph;
@property (nonatomic, assign) AUNode ioNNode;
@property (nonatomic, assign) AudioUnit ioUnit;
@property (nonatomic, assign) AUNode convertNote;
@property (nonatomic, assign) AudioUnit convertUnit;

@property (nonatomic, weak) id <FillDataOutputDelegate> delegate;
@end



@implementation ST_AudioOutput

- (id)initWithChannels:(NSInteger)channels
            sampleRate:(NSInteger)sampleRate
        bytesPerSample:(NSInteger)bytePerSample
      fileDataDelegate:(id<FillDataOutputDelegate>)fileDataDelegate

{
    self = [super init];
    
    if (self) {
        
        [[ST_AudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback];
        [[ST_AudioSession sharedInstance] setPreferredSampleRate:sampleRate];
        [[ST_AudioSession sharedInstance] setPreferredLatency:1*1024.0/sampleRate];
        [[ST_AudioSession sharedInstance] setActive:YES];
        
        
        [[ST_AudioSession sharedInstance] addRouteChangeListener];
        
        [self addAudioSessionInterruptedObserver];
        
//        int sizet = sizeof(SInt16);
        _outData = (SInt16 *)calloc(8*1024, sizeof(SInt16));
        _delegate = fileDataDelegate;
        _sampleRate = sampleRate;
        _channels = channels;
        
        [self createAudioUnitGrap];
    }
    
    return self;
}


- (void)createAudioUnitGrap
{
    
    OSStatus status = noErr;
    
    status = NewAUGraph(&_auGraph);
    CheckStatus(status, @"NewAUGraph create Error", YES);
    

    [self addAudioUnitNodes];
    
    // 必须在获取AudioUnit 之前打开整个_auGraph
    status = AUGraphOpen(_auGraph);
    CheckStatus(status, @"AUGraphOpen open Error", YES);
    
    [self getUnitsFromNodes];
    
    [self setAudioUnitProPerties];
    
    [self makeNodeConnections];
    
    CAShow(_auGraph);
    status = AUGraphInitialize(_auGraph);
    CheckStatus(status, @"Could not initialize AUGraph", YES);
}

- (void)addAudioUnitNodes
{
    OSStatus status = noErr;
    
    AudioComponentDescription ioDescription;
    bzero(&ioDescription, sizeof(ioDescription));
    
    ioDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioDescription.componentType = kAudioUnitType_Output;
    ioDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    
    status = AUGraphAddNode(_auGraph,
                            &ioDescription,
                            &_ioNNode);
    CheckStatus(status, @"AUGraphAddNode create error", YES);
    
    AudioComponentDescription converDescription;
    bzero(&converDescription, sizeof(converDescription));
    converDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    converDescription.componentType = kAudioUnitType_FormatConverter;
    converDescription.componentSubType = kAudioUnitSubType_AUConverter;
    status = AUGraphAddNode(_auGraph,
                            &converDescription,
                            &_convertNote);
    CheckStatus(status, @"AUGraphAddNode _convertNote create error", YES);
    
}


- (void)getUnitsFromNodes
{
    
    OSStatus status = noErr;
    
    status = AUGraphNodeInfo(_auGraph, _ioNNode, NULL, &_ioUnit);
    CheckStatus(status, @"AUGraphNodeInfo _ioUnit Error", YES);
    
    status = AUGraphNodeInfo(_auGraph, _convertNote, NULL, &_convertUnit);
    CheckStatus(status, @"AUGraphNodeInfo _convertUnit Error", YES);
}

- (void)setAudioUnitProPerties
{
    
    OSStatus status = noErr;
    AudioStreamBasicDescription streamFormat = [self nonInterleavedPCMFormatWithChannels:_channels];

    status = AudioUnitSetProperty(_ioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  inputElement,
                                  &streamFormat,
                                  sizeof(streamFormat));
    CheckStatus(status, @"Could not set stream format on I/O unit output scope", YES);

    
    AudioStreamBasicDescription _clientFormat16int;
    UInt32 bytesPersample = sizeof(SInt16);
    bzero(&_clientFormat16int, sizeof(_clientFormat16int));
    _clientFormat16int.mFormatID = kAudioFormatLinearPCM;
    _clientFormat16int.mSampleRate = _sampleRate;
    _clientFormat16int.mChannelsPerFrame = _channels;
    
    _clientFormat16int.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    _clientFormat16int.mFramesPerPacket = 1;
    _clientFormat16int.mBytesPerPacket = bytesPersample * _channels;
    _clientFormat16int.mBytesPerFrame = bytesPersample * _channels;
    
    _clientFormat16int.mBitsPerChannel = 8 * bytesPersample;
    
    
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &streamFormat, sizeof(streamFormat));
    CheckStatus(status, @"augraph recorder normal unit set client format error", YES);
    
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &_clientFormat16int, sizeof(_clientFormat16int));
    CheckStatus(status, @"augraph recorder normal unit set client format error", YES);
}

- (AudioStreamBasicDescription)nonInterleavedPCMFormatWithChannels:(UInt32)channels
{
    UInt32 bytesPerSample = sizeof(Float32);
    
    AudioStreamBasicDescription asbd;
    bzero(&asbd, sizeof(asbd));
    
    asbd.mSampleRate = _sampleRate;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    asbd.mBitsPerChannel = 8*bytesPerSample;
    asbd.mBytesPerFrame = bytesPerSample;
    asbd.mBytesPerPacket = bytesPerSample;
    asbd.mFramesPerPacket = 1;
    asbd.mChannelsPerFrame = channels;
    
    
    return asbd;
}

- (void)makeNodeConnections
{
    OSStatus status = noErr;
    
    status = AUGraphConnectNodeInput(_auGraph, _convertNote, 0, _ioNNode, 0);
    CheckStatus(status, @"Could not connect I/O node input to mixer node input", YES);
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = &STInputRenderCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    
    status = AudioUnitSetProperty(_convertUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callbackStruct, sizeof(callbackStruct));
    
    CheckStatus(status, @"Could not set render callback on mixer input scope, element 1", YES);
}

- (BOOL)play

{
    OSStatus status = AUGraphStart(_auGraph);
    CheckStatus(status, @"Could not start AUGraph", YES);

    
    return YES;
}

- (void)stop
{
    OSStatus status = AUGraphStop(_auGraph);
    CheckStatus(status, @"Could not stop AUGraph", YES);
}

// AudioSession 被打断的通知
- (void)addAudioSessionInterruptedObserver
{
    [self removeAudioSessionInterruptedObserver];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotificationAudioInterrupted:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:[AVAudioSession sharedInstance]];
}

- (void)onNotificationAudioInterrupted:(NSNotification *)sender {
    AVAudioSessionInterruptionType interruptionType = [[[sender userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    switch (interruptionType) {
        case AVAudioSessionInterruptionTypeBegan:
            [self stop];
            break;
        case AVAudioSessionInterruptionTypeEnded:
            [self play];
            break;
        default:
            break;
    }
}

- (void)removeAudioSessionInterruptedObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionInterruptionNotification
                                                  object:nil];
}


- (void)dealloc
{
    if (_outData) {
        
        free(_outData);
        _outData = NULL;
        
    }
    
    
    [self destroyAudioUnitGraph];
    [self removeAudioSessionInterruptedObserver];
}

- (void)destroyAudioUnitGraph
{
    AUGraphStop(_auGraph);
    AUGraphUninitialize(_auGraph);
    AUGraphClose(_auGraph);
    AUGraphRemoveNode(_auGraph, _ioNNode);
    DisposeAUGraph(_auGraph);
//    _ioUnit = NULL;
    _ioNNode = 0;
    _auGraph = NULL;
}

- (OSStatus)renderData:(AudioBufferList *)ioData
           atTimeStamp:(const AudioTimeStamp *)timeStamp
            forElement:(UInt32)element
          numberFrames:(UInt32)numFrames
                 flags:(AudioUnitRenderActionFlags *)flags
{
    
    NSLog(@"🙂%lf", [ST_AudioSession sharedInstance].audioSession.preferredIOBufferDuration);
    for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers; ++iBuffer) {
        
//        NSLog(@"🙂%u", ioData->mBuffers[iBuffer].mDataByteSize);
        memset(ioData->mBuffers[iBuffer].mData, 0, ioData->mBuffers[iBuffer].mDataByteSize);
    }
    
    
    if (_delegate) {
        [_delegate fillAudioData:_outData numFrames:numFrames numChannels:_channels];
        
        
        for (int iBuffer = 0; iBuffer < ioData->mNumberBuffers;  ++iBuffer) {

            memcpy((SInt16 *)ioData->mBuffers[iBuffer].mData, _outData, ioData->mBuffers[iBuffer].mDataByteSize);

        }
    }

    return noErr;
}



@end

static OSStatus STInputRenderCallback(void * inRefCon,
                                      AudioUnitRenderActionFlags *    ioActionFlags,
                                      const AudioTimeStamp *            inTimeStamp,
                                      UInt32                            inBusNumber,
                                      UInt32                            inNumberFrames,
                                      AudioBufferList * __nullable    ioData)
{
    
 
    
    ST_AudioOutput *audioOutput = (__bridge id)inRefCon;
    
    return [audioOutput renderData:ioData
                       atTimeStamp:inTimeStamp
                        forElement:inBusNumber
                      numberFrames:inNumberFrames
                             flags:ioActionFlags];
}

static void CheckStatus(OSStatus status, NSString *message, BOOL fatal)
{
    
    if(status != noErr)
    {
        char fourCC[16];
        *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
        fourCC[4] = '\0';
        
        if(isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3]))
            NSLog(@"%@: %s", message, fourCC);
        else
            NSLog(@"%@: %d", message, (int)status);
        
        if(fatal)
            exit(-1);
    }
}
