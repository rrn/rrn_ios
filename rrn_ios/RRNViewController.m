//
//  RRNViewController.m
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-03-25.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import "RRNViewController.h"
#import "ESTBeaconManager.h"

@interface RRNViewController () <ESTBeaconManagerDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@property (weak, nonatomic) IBOutlet UIButton *beaconButton;

@property (strong, nonatomic) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion *region;
@property (strong, nonatomic) NSMutableDictionary *beaconData;
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
    }];
    
    // Observe Notifications
    [[NSNotificationCenter defaultCenter] addObserverForName:@"goToUrl"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *notification) {
                                                      [self goToUrl: notification.userInfo[@"url"]];
                                                  }];
    // Init button style
    self.beaconButton.clipsToBounds = YES;
    
    CALayer *layer = self.beaconButton.layer;
    layer.cornerRadius = 35;
    layer.masksToBounds = YES;
    
    CALayer *shadowLayer = [CALayer new];
    shadowLayer.frame = self.beaconButton.frame;
    
    shadowLayer.cornerRadius = 35;
    
    shadowLayer.backgroundColor = [UIColor whiteColor].CGColor;
    shadowLayer.opacity = 0.5;
    shadowLayer.shadowColor = [UIColor blackColor].CGColor;
    shadowLayer.shadowOpacity = 0.6;
    shadowLayer.shadowOffset = CGSizeMake(1,1);
    shadowLayer.shadowRadius = 3;
    
    UIView* parent = self.beaconButton.superview;
    [parent.layer insertSublayer:shadowLayer below:self.beaconButton.layer];
}

- (IBAction)goToBeaconContent:(UIButton *)sender
{
    NSDictionary *beaconData = [self beaconDataForTag:sender.tag];
    [self goToUrl:beaconData[@"url"]];
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
    
    // Add chatheads for all beacons that are now in the region
    ESTBeacon *closestBeacon;
    for (ESTBeacon *beacon in beacons) {
        NSLog(@"%@:%@ %@m, %@", beacon.major, beacon.minor, beacon.distance, beacon.measuredPower);
        if (0 < [beacon.distance floatValue] && [beacon.distance floatValue] < 17){
            if (!closestBeacon || [beacon.distance floatValue] < [closestBeacon.distance floatValue]) {
                closestBeacon = beacon;
            }
        }
    }
    
    if (closestBeacon) {
        int beaconTag = [[self beaconDataKeyForMajor:closestBeacon.major minor:closestBeacon.minor] intValue];
        NSDictionary *beaconData = [self beaconDataForMajor:closestBeacon.major minor:closestBeacon.minor];
        
        [self.beaconButton setHidden:false];
        [self.beaconButton setTag:beaconTag];
        [self imageFromUrl: beaconData[@"thumbnail_url"] withCallback:^(UIImage *image) {
            [self.beaconButton setImage:image forState:UIControlStateNormal];
        }];

    } else {
        [self.beaconButton setHidden:true];
    }
}
@end
