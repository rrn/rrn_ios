//
//  RRNChatHead.h
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-04-09.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHDraggingCoordinator.h"

@interface RRNChatHead : NSObject  <CHDraggingCoordinatorDelegate>
@property (strong, nonatomic) NSNumber *major;
@property (strong, nonatomic) NSNumber *minor;
@property (strong, nonatomic) NSString *url;

- (id)initWithMajor:(NSNumber *)major minor:(NSNumber *)minor image:(UIImage *)image url:(NSString *)urlAsString callback:(void (^)(RRNChatHead *chatHead))callback;
- (void)addToView:(UIView *)view atX:(float)x Y:(float)y;
- (void)removeFromView;
- (CGSize)size;
- (bool)isOpen;
- (bool)isClosed;
@end

