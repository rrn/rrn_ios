//
//  RRNViewController.m
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-03-25.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import "RRNViewController.h"
#import "RRNChatHead.h"
#import "ESTBeaconManager.h"

@interface RRNViewController () <ESTBeaconManagerDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion *region;
@property (strong, nonatomic) NSMutableDictionary *beaconData;

@property (strong, nonatomic) NSMutableArray *chatHeads;
@end

@implementation RRNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self goToUrl: @"http://m.rrnpilot.org"];
    
    [self startBeaconManager];
    
    // Fetch the Beacon JSON
    [self fetchJSONFrom:@"http://www.rrncommunity.org/holding_institutions/1/beacons.json" withCallback:^(NSMutableDictionary* beaconData){
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
    self.chatHeads = [[NSMutableArray alloc] init];
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

- (RRNChatHead*)chatHeadForBeacon:(ESTBeacon*)beacon
{
    for (RRNChatHead *chatHead in self.chatHeads) {
        NSDictionary *beaconData = [self beaconDataForChatHead:chatHead];
        if ([beaconData[@"major"] isEqualToNumber:beacon.major] && [beaconData[@"minor"] isEqualToNumber:beacon.minor]){
            return chatHead;
        }
    }
    return nil;
}

- (NSDictionary*)beaconDataForChatHead:(RRNChatHead*)chatHead
{
    for(id key in self.beaconData){
        if ([self.beaconData[key][@"major"] isEqualToNumber:chatHead.major] && [self.beaconData[key][@"minor"] isEqualToNumber:chatHead.minor]){
            return self.beaconData[key];
        }
    }
    return nil;
}

- (NSDictionary*)beaconDataForMajor:(NSNumber*)major minor:(NSNumber*)minor
{
    return self.beaconData[[self beaconDataKeyForMajor:major minor:minor]];
}

- (NSString *)beaconDataKeyForMajor:(NSNumber*)major minor:(NSNumber*)minor
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

    
    [self imageFromUrl:beaconData[@"thumbnail_url"] withCallback:^(UIImage *image) {
        if ([self chatHeadForBeacon:beacon]) { return; } // Check for the beacon again in case we've added it since we sent out this callback
        RRNChatHead *chatHead = [[RRNChatHead alloc] initWithMajor:beaconData[@"major"] minor:beaconData[@"minor"] image:image url:beaconData[@"url"] callback:^(RRNChatHead *chatHead)
        {
            if (chatHead.url){
                [self goToUrl:chatHead.url];
            }
        }];
        [self.chatHeads addObject:chatHead];
        [chatHead addToView:self.view atX:0 Y:(chatHead.size.height + 10) * [self.chatHeads count]];
    }];
}

- (void)removeChatHead:(RRNChatHead *)chatHead
{
    [self.chatHeads removeObject:chatHead];
    [chatHead removeFromView];
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
//    float maxDistance = 3;
    NSLog(@"Ranged Beacons");
    ESTBeacon *beaconForChathead;
    // Remove Chatheads when beacons are no longer in the region, UNLESS they are currently active
    // NOTE: Don't use an iterator because we're modifying the actual array
    for (long i = [self.chatHeads count] - 1; i >= 0; i--) {
        beaconForChathead = nil;
        RRNChatHead *chatHead = [self.chatHeads objectAtIndex:i];
        NSDictionary *beaconData = [self beaconDataForChatHead:chatHead];

        for (ESTBeacon *beacon in beacons) {
            if ([beaconData[@"major"] isEqualToNumber:beacon.major] && [beaconData[@"minor"] isEqualToNumber:beacon.minor]){
                beaconForChathead = beacon;
                break;
            }
        }
        if (!beaconForChathead || [beaconForChathead.distance floatValue] > 20){
            if ([chatHead isClosed]) {
                [self removeChatHead:chatHead];
            }
        }
    }
    
    // Add chatheads for all beacons that are now in the region
    for (ESTBeacon *beacon in beacons) {
        NSLog(@"%@:%@ %@m, %@, %li, %d", beacon.major, beacon.minor, beacon.distance, beacon.measuredPower, (long)beacon.rssi, beacon.proximity);
        if (0 < [beacon.distance floatValue] && [beacon.distance floatValue] < 17){
            [self addChatHead:beacon];
        }
    }
}
@end
