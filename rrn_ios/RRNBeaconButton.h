//
//  RRNBeaconButton.h
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-04-10.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RRNBeaconButton : UIButton
@property (strong, nonatomic) NSNumber *major;
@property (strong, nonatomic) NSNumber *minor;
@property (strong, nonatomic) NSString *url;

- (id)initWithMajor:(NSNumber *)major minor:(NSNumber *)minor image:(UIImage *)image url:(NSString *)urlAsString;
- (void)addToView:(UIView *)view atX:(float)x Y:(float)y;
- (void)removeFromView;
- (CGSize)size;
@end
