//
//  ViewController.m
//  AudioUnitPlayerDemo
//
//  Created by codew on 2018/8/8.
//  Copyright © 2018年 codew. All rights reserved.
//

#import "ViewController.h"
#import "CommonUtil.h"
#import "ST_AudioPlayer.h"


@interface ViewController ()
{
    ST_AudioPlayer *_aduioPlayer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
}
- (IBAction)playBtnClick:(id)sender {
    
    NSLog(@"playBtnClick");
    
    NSString *filePath = [CommonUtil bundlePath:@"allTheWay.mp4"];
    _aduioPlayer = [[ST_AudioPlayer alloc] initWithFilePath:filePath];
    
    [_aduioPlayer start];
}
- (IBAction)stopBtnClick:(id)sender {
    
    NSLog(@"stopBtnClick");
    
    if (_aduioPlayer){
        
        [_aduioPlayer stop];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
