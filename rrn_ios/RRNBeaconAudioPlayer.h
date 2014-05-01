//
//  RRNBeaconAudioPlayer.h
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-04-30.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RRNBeaconAudioPlayer : NSObject
- (void)setEnabled:(BOOL)enabled;
- (void)playUrl:(NSString *)url;
@end
