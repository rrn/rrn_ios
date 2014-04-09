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

#import "WebViewController.h"

@interface RRNChatHead ()

@property (strong, nonatomic) NSString *url;
@property (strong, nonatomic) CHDraggableView *draggableView;
@property (strong, nonatomic) CHDraggingCoordinator *draggingCoordinator;

@end

@implementation RRNChatHead

- (id)initWithMajor:(NSNumber *)major minor:(NSNumber *)minor image:(UIImage *)image url:(NSString *)urlAsString
{
    self = [super init];
    if (self) {
        self.major = major;
        self.minor = minor;
        self.url = urlAsString;
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

- (UIViewController *)draggingCoordinator:(CHDraggingCoordinator *)coordinator viewControllerForDraggableView:(CHDraggableView *)chathead
{
    WebViewController *webView = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"WebViewController"];
    webView.defaultUrl = self.url; // Set the web view's default url so it displays when the view opens
    return webView;
}

- (CGSize)size
{
    return self.draggableView.frame.size;
}
@end
