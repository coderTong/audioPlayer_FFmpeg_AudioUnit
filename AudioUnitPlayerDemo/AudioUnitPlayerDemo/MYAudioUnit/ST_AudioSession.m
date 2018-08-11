//
//  ST_AudioSession.m
//  01AudioPlayerMe
//
//  Created by codew on 2018/7/26.
//  Copyright © 2018年 codew. All rights reserved.
//

#import "ST_AudioSession.h"
#import "AVAudioSession+ST_RouteUtils.h"


@implementation ST_AudioSession

+ (ST_AudioSession *)sharedInstance
{
    
    static ST_AudioSession *instance = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       
        instance = [[ST_AudioSession alloc] init];
        
    });
    
    return instance;
    
}

- (instancetype)init{
    
    if ( (self = [super init]) ){
        
        _preferredSampleRate = _currentSampleRate = 44100.0;
        _audioSession = [AVAudioSession sharedInstance];
    }
    
    return self;
}


- (void)setCategory:(NSString *)category
{
    _category = category;
    
    NSError *error = nil;
    
    if ( ![self.audioSession setCategory:_category error:&error] ) {
        
        NSLog(@"Could note set category on audio session: %@ ", error.localizedDescription);
    }
}

- (void)setPreferredSampleRate:(Float64)preferredSampleRate
{
    _preferredSampleRate = preferredSampleRate;
}

- (void)setActive:(BOOL)active
{
    _active = active;
    
    NSError *error = nil;
    
    if ( ![self.audioSession setPreferredSampleRate:self.preferredSampleRate error:&error] ){
        
        NSLog(@"Error when setting sample rate on audio session: %@", error.localizedDescription);
    }
    
    
    if ( ![self.audioSession setActive:_active error:&error] ){
        NSLog(@"Error when setting active state of audio session: %@", error.localizedDescription);
    }
    
    _currentSampleRate = [self.audioSession sampleRate];
}



- (void)setPreferredLatency:(NSTimeInterval)preferredLatency
{
    
    _preferredLatency = preferredLatency;
    
    NSError *error = nil;
    
    if ( ![self.audioSession setPreferredIOBufferDuration:_preferredLatency error:&error] ){
        NSLog(@"Error when setting preferred I/O buffer duration");
    }
}

- (void)addRouteChangeListener
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNotificationAudioRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
}


- (void)onNotificationAudioRouteChange:(NSNotification *)sender {
    
    [self adjustOnRouteChange];
}


- (void)adjustOnRouteChange
{
    
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    if (currentRoute) {
        if ([[AVAudioSession sharedInstance] usingWiredMicrophone]) {
        } else {
            if (![[AVAudioSession sharedInstance] usingBlueTooth]) {
                [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            }
        }
    }
    
}


































@end
