//
//  RRNViewController.m
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-03-25.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import "RRNViewController.h"
#import "WebViewController.h"

#import "CHDraggableView.h"
#import "CHDraggableView+Avatar.h"

#import "ESTBeaconManager.h"

@interface RRNViewController () <ESTBeaconManagerDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion *region;
@property (strong, nonatomic) NSMutableDictionary *beaconData;

@property (strong, nonatomic) NSMutableArray *chatheads;
@property (strong, nonatomic) NSMutableArray *draggingCoordinators;
@end

@implementation RRNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self goToUrl: @"http://m.rrnpilot.org"];
    
    [self startBeaconManager];
    
    // Fetch the Beacon JSON
    [self fetchJSONFrom:@"http://192.168.0.101:3000/holding_institutions/22/beacons.json" withCallback:^(NSMutableDictionary* beaconData){
        NSLog(@"Retrieved Beacon Data");
        self.beaconData = [self sanitizeBeaconData: beaconData];
        
//        self.beaconData = [self sanitizeBeaconData:[
//            @{
//              @"1": [@{@"notification" : @"You are near Raven and the First Man",
//                    @"thumbnail_url" : @"http://www.billreidfoundation.org/banknote/images/raven.jpg",
//                    @"url"           : @"http://www.google.com",
//                    @"major"         : @"27260",
//                    @"minor"         : @"55917"} mutableCopy]
//             } mutableCopy]];
    }];
    
    // Observe Notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:@"goToUrl"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification) {
                                                      [self goToUrl: notification.userInfo[@"url"]];
                                                  }];
    
    // Keep track of Chatheads and dragging coordinators
    _chatheads = [[NSMutableArray alloc] init];
    _draggingCoordinators = [[NSMutableArray alloc] init];
}

// Fetch json from the url and parse it
- (void)fetchJSONFrom:(NSString*)urlAsString withCallback:(void (^)(NSMutableDictionary*))callback
{
    NSURL *url = [[NSURL alloc] initWithString:urlAsString];
    NSLog(@"%@", urlAsString);
    
    [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSLog(@"%@", response);
        NSMutableDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        callback(parsedObject);
    }];
}

// Ensure that the values returned in the JSON conform to an expected type
- (NSMutableDictionary *)sanitizeBeaconData:(NSMutableDictionary *)beaconData
{
    for(id key in beaconData){
        beaconData[key][@"major"] = [NSNumber numberWithInt:[beaconData[key][@"major"] intValue]];
        beaconData[key][@"minor"] = [NSNumber numberWithInt:[beaconData[key][@"minor"] intValue]];
    }
    
    return beaconData;
}

// load URL into webView
- (void)goToUrl:(NSString*)urlAsString
{
    NSURL *url = [[NSURL alloc] initWithString:urlAsString];
    NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest: urlRequest];
}

- (CHDraggableView*)chatHeadForBeacon:(ESTBeacon*)beacon
{
    for (CHDraggableView *chathead in self.chatheads) {
        NSDictionary *beaconData = [self beaconDataForChatHead:chathead];
        if ([beaconData[@"major"] isEqualToNumber:beacon.major] && [beaconData[@"minor"] isEqualToNumber:beacon.minor]){
            return chathead;
        }
    }
    return nil;
}

- (NSDictionary*)beaconDataForChatHead:(CHDraggableView*)chathead
 {
     return self.beaconData[[@(chathead.tag) stringValue]];
 }

- (NSDictionary*)beaconDataForMajor:(NSNumber*)major minor:(NSNumber*)minor
{
    return self.beaconData[[self beaconDataKeyForMajor:major minor:minor]];
}

- (NSNumber *)beaconDataKeyForMajor:(NSNumber*)major minor:(NSNumber*)minor
{
    for(id key in self.beaconData){
        if ([self.beaconData[key][@"major"] isEqualToNumber:major] && [self.beaconData[key][@"minor"] isEqualToNumber:minor]){
            return key;
        }
    }
    return nil;
}


- (void)addChatHead:(ESTBeacon *)beacon {
    if ([self chatHeadForBeacon:beacon]) { return; }
    
    NSDictionary *beaconData = [self beaconDataForMajor:beacon.major minor:beacon.minor];
    
    if (!beaconData) { return; } // We may not have beacon data for every beacon we detect

    NSLog(@"Adding chathead %@ %@", beacon.major, beacon.minor);
    
    [self imageFromUrl:beaconData[@"thumbnail_url"] withCallback:^(UIImage *image) {
        CHDraggableView *chathead = [CHDraggableView draggableViewWithImage: image];
        chathead.tag = [[self beaconDataKeyForMajor:beacon.major minor:beacon.minor] intValue];
        chathead.frame = CGRectMake(0, (chathead.frame.size.height + 10) * [_draggingCoordinators count], chathead.frame.size.width, chathead.frame.size.height);
        
        CHDraggingCoordinator *draggingCoordinator = [[CHDraggingCoordinator alloc] initWithWindow:self.view.window draggableViewBounds:chathead.bounds];
        draggingCoordinator.delegate = self;
        draggingCoordinator.snappingEdge = CHSnappingEdgeLeft;
        chathead.delegate = draggingCoordinator;
        
        [self.chatheads addObject:chathead];
        [self.draggingCoordinators addObject:draggingCoordinator];
        
        [self.view.window addSubview:chathead];
    }];
}

- (void)removeChatHead:(CHDraggableView *)chathead
{
    NSDictionary *beaconData = [self beaconDataForChatHead:chathead];
    NSLog(@"Removing chathead %@ %@", beaconData[@"major"], beaconData[@"minor"]);

    CHDraggingCoordinator *draggingCoordinator = chathead.delegate;
    chathead.delegate = nil;
    
    [self.chatheads removeObject:chathead];
    [self.draggingCoordinators removeObject:draggingCoordinator];
    [chathead removeFromSuperview];
}

- (UIViewController *)draggingCoordinator:(CHDraggingCoordinator *)coordinator viewControllerForDraggableView:(CHDraggableView *)chathead
{
    WebViewController *webView = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"WebViewController"];
    webView.defaultUrl = [self beaconDataForChatHead:chathead][@"url"];
    return webView;
}

- (void)notifyLocally:(NSString*)message withURLAsString:(NSString*)url
{
    UILocalNotification *notification = [UILocalNotification new];
    notification.alertBody = message;
    notification.userInfo = @{@"url": url};
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)imageFromUrl:(NSString*)urlAsString withCallback:(void(^)(UIImage *image))callback
{
    NSURL *url = [NSURL URLWithString:urlAsString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
       if ( !error )
       {
           UIImage *image = [[UIImage alloc] initWithData:data];
           callback(image);
       } else {
           NSLog(@"%@", error);
       }
   }];
}

- (void)startBeaconManager
{
   // Set up the beacon manager
   self.beaconManager = [[ESTBeaconManager alloc] init];
   self.beaconManager.delegate = self;
   self.region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID identifier:@"EstimoteSampleRegion"];
   
   /*
    * Starts looking for Estimote beacons.
    * All callbacks will be delivered to beaconManager delegate.
    */
   [self.beaconManager startRangingBeaconsInRegion:self.region];
}

#pragma mark - ESTBeaconManager delegate

- (void)beaconManager:(ESTBeaconManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(ESTBeaconRegion *)region
{
    float maxDistance = 5;
    NSLog(@"Ranged Beacons");
    ESTBeacon *beaconForChathead;
    // Remove Chatheads when beacons are no longer in the region
    // NOTE: Don't use an iterator because we're modifying the actual
    for (int i = [self.chatheads count] - 1; i >= 0; i--) {
        beaconForChathead = nil;
        CHDraggableView *chathead = [self.chatheads objectAtIndex:i];
        NSDictionary *beaconData = [self beaconDataForChatHead:chathead];

        for (ESTBeacon *beacon in beacons) {
            if ([beaconData[@"major"] isEqualToNumber:beacon.major] && [beaconData[@"minor"] isEqualToNumber:beacon.minor]){
                beaconForChathead = beacon;
                break;
            }
        }
        if (!beaconForChathead || [beaconForChathead.distance floatValue] > maxDistance){
            [self removeChatHead:chathead];
        }
    }
    
    // Add chatheads for all beacons that are now in the region
    for (ESTBeacon *beacon in beacons) {
        NSLog(@"Major %@ Minor %@ Distance %@", beacon.major, beacon.minor, beacon.distance);
        if (0 < [beacon.distance floatValue] && [beacon.distance floatValue] < maxDistance){
            [self addChatHead:beacon];
        }
    }
}
@end
