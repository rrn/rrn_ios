//
//  CHDraggingCoordinator.m
//  ChatHeads
//
//  Created by Matthias Hochgatterer on 4/19/13.
//  Copyright (c) 2013 Matthias Hochgatterer. All rights reserved.
//

#import "CHDraggingCoordinator.h"
#import <QuartzCore/QuartzCore.h>
#import "CHDraggableView.h"

typedef enum {
    CHInteractionStateNormal,
    CHInteractionStateConversation
} CHInteractionState;

@interface CHDraggingCoordinator ()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) NSMutableDictionary *edgePointDictionary;;
@property (nonatomic, assign) CGRect draggableViewBounds;
@property (nonatomic, assign) CHInteractionState state;
@property (nonatomic, strong) UIViewController *presentedNavigationController;
@property (nonatomic, strong) UIView *backgroundView;

@end

@implementation CHDraggingCoordinator

- (id)initWithWindow:(UIWindow *)window draggableViewBounds:(CGRect)bounds
{
    self = [super init];
    if (self) {
        _window = window;
        _draggableViewBounds = bounds;
        _state = CHInteractionStateNormal;
        _edgePointDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (bool)isInConversation
{
    return _state == CHInteractionStateConversation;
}

#pragma mark - Geometry

- (CGRect)_dropArea
{
    return CGRectInset([self.window.screen applicationFrame], -(int)(CGRectGetWidth(_draggableViewBounds)/6), 0);
}

- (CGRect)_conversationArea
{
    CGRect slice;
    CGRect remainder;
    CGRectDivide([self.window.screen applicationFrame], &slice, &remainder, CGRectGetHeight(CGRectInset(_draggableViewBounds, -10, 0)), CGRectMinYEdge);
    return slice;
}

- (CGRectEdge)_destinationEdgeForReleasePointInCurrentState:(CGPoint)releasePoint
{
    if (_state == CHInteractionStateConversation) {
        return CGRectMinYEdge;
    } else if(_state == CHInteractionStateNormal) {
        return releasePoint.x < CGRectGetMidX([self _dropArea]) ? CGRectMinXEdge : CGRectMaxXEdge;
    }
    NSAssert(false, @"State not supported");
    return CGRectMinYEdge;
}

- (CGPoint)_destinationPointForReleasePoint:(CGPoint)releasePoint
{
    CGRect dropArea = [self _dropArea];
    
    CGFloat midXDragView = CGRectGetMidX(_draggableViewBounds);
    CGRectEdge destinationEdge = [self _destinationEdgeForReleasePointInCurrentState:releasePoint];
    CGFloat destinationY;
    CGFloat destinationX;
 
    CGFloat topYConstraint = CGRectGetMinY(dropArea) + CGRectGetMidY(_draggableViewBounds);
    CGFloat bottomYConstraint = CGRectGetMaxY(dropArea) - CGRectGetMidY(_draggableViewBounds);
    if (releasePoint.y < topYConstraint) { // Align ChatHead vertically
        destinationY = topYConstraint;
    }else if (releasePoint.y > bottomYConstraint) {
        destinationY = bottomYConstraint;
    }else {
        destinationY = releasePoint.y;
    }

    if (self.snappingEdge == CHSnappingEdgeBoth){   //ChatHead will snap to both edges
        if (destinationEdge == CGRectMinXEdge) {
            destinationX = CGRectGetMinX(dropArea) + midXDragView;
        } else {
            destinationX = CGRectGetMaxX(dropArea) - midXDragView;
        }
        
    }else if(self.snappingEdge == CHSnappingEdgeLeft){  //ChatHead will snap only to left edge
        destinationX = CGRectGetMinX(dropArea) + midXDragView;
        
    }else{  //ChatHead will snap only to right edge
        destinationX = CGRectGetMaxX(dropArea) - midXDragView;
    }

    return CGPointMake(destinationX, destinationY);
}

#pragma mark - Dragging

- (void)draggableViewHold:(CHDraggableView *)view
{
    
}

- (void)draggableView:(CHDraggableView *)view didMoveToPoint:(CGPoint)point
{

}

- (void)draggableViewReleased:(CHDraggableView *)view
{
    if (_state == CHInteractionStateNormal) {
        [self _animateViewToEdges:view];
    }
}

- (void)draggableViewTouched:(CHDraggableView *)view
{
    if (_state == CHInteractionStateNormal) {
        [self.delegate draggableViewTouched];
    }
}


#pragma mark - Alignment

- (void)draggableViewNeedsAlignment:(CHDraggableView *)view
{
    [self _animateViewToEdges:view];
}

#pragma mark Dragging Helper

- (void)_animateViewToEdges:(CHDraggableView *)view
{
    CGPoint destinationPoint = [self _destinationPointForReleasePoint:view.center];    
    [self _animateView:view toEdgePoint:destinationPoint];
}

- (void)_animateView:(CHDraggableView *)view toEdgePoint:(CGPoint)point
{
    [_edgePointDictionary setObject:[NSValue valueWithCGPoint:point] forKey:@(view.tag)];
    [view snapViewCenterToPoint:point edge:[self _destinationEdgeForReleasePointInCurrentState:view.center]];
}

- (void)_animateViewToConversationArea:(CHDraggableView *)view
{
    CGRect conversationArea = [self _conversationArea];
    CGPoint center = CGPointMake(CGRectGetMidX(conversationArea), CGRectGetMidY(conversationArea));
    [view snapViewCenterToPoint:center edge:[self _destinationEdgeForReleasePointInCurrentState:view.center]];
}

@end
