//
//  RRNBeaconAudioPlayer.m
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-04-30.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import "RRNBeaconAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface RRNBeaconAudioPlayer()
@property (nonatomic) BOOL enabled;
@property (strong, nonatomic) AVPlayer *player;
@end

@implementation RRNBeaconAudioPlayer

- (void)setEnabled:(BOOL)newState
{
    _enabled = newState;
    
    if (self.enabled) {
        [self.player play];
    } else {
        [self.player pause];
    }
}

- (void)playUrl:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    self.player = [AVPlayer playerWithURL:url];
    
    if (self.enabled) {
        [self.player play];
    }
}

@end
