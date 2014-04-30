//
//  RRNViewController.m
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-03-25.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import "RRNViewController.h"
#import "RRNBeaconButton.h"
#import "ESTBeaconManager.h"

@interface RRNViewController () <ESTBeaconManagerDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion *region;
@property (strong, nonatomic) NSMutableDictionary *beaconData;
@property (strong, nonatomic) NSMutableArray *beaconButtons;
@end

@implementation RRNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.beaconButtons = [[NSMutableArray alloc] init];
    
    [self goToUrl: @"http://m.rrnpilot.org"];
    
    [self startBeaconManager];
    
    // Fetch the Beacon JSON
    [self fetchJSONFrom:@"http://www.rrncommunity.org/holding_institutions/1/beacons.json" withCallback:^(NSMutableDictionary* beaconData){
        NSLog(@"Retrieved Beacon Data");
        self.beaconData = [self sanitizeBeaconData: beaconData];
    }];
    
    // Observe Notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:@"goToUrl"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification) {
                                                      [self goToUrl: notification.userInfo[@"url"]];
                                                  }];
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

- (NSDictionary*)beaconDataForTag:(int)tag
{
    return self.beaconData[[@(tag) stringValue]];
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
- (RRNBeaconButton *)beaconButtonForBeacon:(ESTBeacon *)beacon
{
    for(RRNBeaconButton *beaconButton in self.beaconButtons){
        if ([beaconButton.major isEqualToNumber:beacon.major] && [beaconButton.minor isEqualToNumber:beacon.minor]){
            return beaconButton;
        }
    }
    return nil;
}

- (void)addBeaconButton:(ESTBeacon *)beacon
{
    if ([self beaconButtonForBeacon:beacon]){ return; }
    
    NSDictionary *beaconData = [self beaconDataForMajor:beacon.major minor:beacon.minor];
    
    if (!beaconData){ return; }
    
    [self imageFromUrl: beaconData[@"thumbnail_url"] withCallback:^(UIImage *image) {
        if ([self beaconButtonForBeacon:beacon]){ return; } // If we've already created a button for this beacon while we were fetching the image, don't make another

        RRNBeaconButton *beaconButton = [[RRNBeaconButton alloc] initWithMajor:beaconData[@"major"] minor:beaconData[@"minor"] image:image url:beaconData[@"url"]];
        [self.beaconButtons addObject:beaconButton];

        [beaconButton addToView:self.view atX:(self.view.frame.size.width - [beaconButton size].width)/2  Y:(self.view.frame.size.height - [beaconButton size].height * 0.9)];
        
        [beaconButton addTarget:self action:@selector(beaconButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
    }];
}

- (void)removeBeaconButton:(RRNBeaconButton *)beaconButton
{
    [self.beaconButtons removeObject:beaconButton];
    [beaconButton removeFromView];
}

- (void)beaconButtonPressed:(RRNBeaconButton *)beaconButton
{
    NSLog(@"Pressed");
    
    NSDictionary *beaconData = [self beaconDataForMajor:beaconButton.major minor:beaconButton.minor];
    [self goToUrl:beaconData[@"url"]];
    
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
    NSLog(@"Ranged Beacons");
    
    RRNBeaconButton *currentBeaconButton = [self.beaconButtons firstObject];
    ESTBeacon *currentBeacon;
    ESTBeacon *closestBeacon;
    
    for (ESTBeacon *beacon in beacons) {
        NSLog(@"%@:%@ %@m, %@", beacon.major, beacon.minor, beacon.distance, beacon.measuredPower);
        if (0 < [beacon.distance floatValue] && [beacon.distance floatValue] < 17){
            if (!closestBeacon || [beacon.distance floatValue] < [closestBeacon.distance floatValue]) {
                closestBeacon = beacon;
            }
        }
        if (currentBeaconButton && currentBeaconButton.major == beacon.major && currentBeaconButton.minor == beacon.minor){
            currentBeacon = beacon;
        }
    }
    
    if (closestBeacon) {
        if ( currentBeacon && [currentBeacon.distance floatValue] - [closestBeacon.distance floatValue] < 2) { return; }
        if (currentBeaconButton && currentBeaconButton != [self beaconButtonForBeacon:closestBeacon]){
            [self removeBeaconButton:currentBeaconButton];
        }
        [self addBeaconButton:closestBeacon];
    } else {
        [self removeBeaconButton:currentBeaconButton];
    }
}
@end
