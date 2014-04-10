//
//  RRNChatHead.m
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-04-09.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import "RRNChatHead.h"

#import "CHDraggableView.h"
#import "CHDraggableView+Avatar.h"

#import "RRNViewController.h"

@interface RRNChatHead ()
@property (nonatomic, copy) void (^callback)(RRNChatHead *chatHead);
@property (strong, nonatomic) CHDraggableView *draggableView;
@property (strong, nonatomic) CHDraggingCoordinator *draggingCoordinator;

@end

@implementation RRNChatHead

- (id)initWithMajor:(NSNumber *)major minor:(NSNumber *)minor image:(UIImage *)image url:(NSString *)urlAsString callback:(void (^)(RRNChatHead *chatHead))callback
{
    self = [super init];
    if (self) {
        self.major = major;
        self.minor = minor;
        self.url = urlAsString;
        self.callback = callback;
        self.draggableView = [CHDraggableView draggableViewWithImage: image];
    }
    return self;
}

-(void)addToView:(UIView *)view atX:(float)x Y:(float)y
{
    NSLog(@"Adding chathead %@ %@", self.major, self.minor);

    self.draggableView.frame = CGRectMake(x, y, self.draggableView.frame.size.width, self.draggableView.frame.size.height);
    
    self.draggingCoordinator = [[CHDraggingCoordinator alloc] initWithWindow:view.window draggableViewBounds:self.draggableView.bounds];
    self.draggingCoordinator.snappingEdge = CHSnappingEdgeLeft;

    self.draggingCoordinator.delegate = self;
    self.draggableView.delegate = self.draggingCoordinator;
    
    [view.window addSubview:self.draggableView];
}

-(void)removeFromView
{
    NSLog(@"Removing chathead %@ %@", self.major, self.minor);
    
    self.draggableView.delegate = nil;
    self.draggingCoordinator = nil;
    [self.draggableView removeFromSuperview];
}

- (void)draggableViewTouched
{
    self.callback(self);
}

- (CGSize)size
{
    return self.draggableView.frame.size;
}

- (bool)isOpen
{
    return false;
//    return [self.draggingCoordinator isInConversation];
}
- (bool)isClosed
{
    return true;
//    return ![self.draggingCoordinator isInConversation];
}
@end
