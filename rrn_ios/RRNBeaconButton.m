//
//  RRNBeaconButton.m
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-04-10.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import "RRNBeaconButton.h"
#import <AudioToolbox/AudioToolbox.h>

@interface RRNBeaconButton ()

@property (strong, nonatomic) UIView *buttonShadow;
@end

@implementation RRNBeaconButton
- (id)initWithMajor:(NSNumber *)major minor:(NSNumber *)minor image:(UIImage *)image url:(NSString *)urlAsString
{
    self = [super init];
    
    if (self){
        self.major = major;
        self.minor = minor;
        self.url = urlAsString;
        
        // Init button style
        self.frame = CGRectMake(0,0,100,100);
        self.clipsToBounds = YES;
        self.layer.cornerRadius = self.frame.size.height / 2;
        self.layer.masksToBounds = YES;
        
        [self setHidden:false];
        [self setImage:image forState:UIControlStateNormal];
        
        // Shadow Style
        self.buttonShadow = [UIView new];
        self.buttonShadow.layer.cornerRadius = self.layer.cornerRadius;
        
        self.buttonShadow.layer.backgroundColor = [UIColor whiteColor].CGColor;
        self.buttonShadow.layer.opacity = 1;
        self.buttonShadow.layer.shadowColor = [UIColor blackColor].CGColor;
        self.buttonShadow.layer.shadowOpacity = 0.6;
        self.buttonShadow.layer.shadowOffset = CGSizeMake(1,1);
        self.buttonShadow.layer.shadowRadius = 3;
    }
    
    return self;
}

-(void)addToView:(UIView *)view atX:(float)x Y:(float)y
{
    NSLog(@"Adding Beacon Button %@ %@", self.major, self.minor);

    self.frame = CGRectMake(x,view.frame.size.height,self.frame.size.width,self.frame.size.height);
    self.buttonShadow.frame = self.frame;
    
    [view addSubview:self.buttonShadow];
    [view addSubview:self];
    [self playSound];
    [UIView animateWithDuration:0.25
                          delay:0.125
         usingSpringWithDamping:0.4
          initialSpringVelocity:1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.frame = CGRectMake(x,y,self.frame.size.width,self.frame.size.height);
                         self.buttonShadow.frame = CGRectMake(x,y,self.frame.size.width,self.frame.size.height);
                     }
                     completion:NULL];
}

-(void)removeFromView
{
    NSLog(@"Removing Beacon Button %@ %@", self.major, self.minor);

    [UIView animateWithDuration:0.125
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.frame = CGRectMake(self.frame.origin.x,[self superview].frame.size.height,self.frame.size.width,self.frame.size.height);
                         self.buttonShadow.frame = CGRectMake(self.frame.origin.x,[self superview].frame.size.height,self.frame.size.width,self.frame.size.height);
                     }
                     completion:^(BOOL fin){
                         [self removeFromSuperview];
                         [self.buttonShadow removeFromSuperview];
                     }];
}

-(void)playSound
{
    AudioServicesPlaySystemSound(1103); // Tink Sound
}

- (CGSize)size
{
    return self.frame.size;
}
@end
