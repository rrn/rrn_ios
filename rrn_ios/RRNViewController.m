//
//  RRNViewController.m
//  rrn_ios
//
//  Created by Nicholas Jakobsen on 2014-03-25.
//  Copyright (c) 2014 Culture Code. All rights reserved.
//

#import "RRNViewController.h"
#import "RRNBeaconButton.h"
#import "RRNBeaconAudioPlayer.h"
#import "ESTBeaconManager.h"

@interface RRNViewController () <ESTBeaconManagerDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UIButton *audioButton;

@property (strong, nonatomic) RRNBeaconAudioPlayer *audioPlayer;
@property (strong, nonatomic) ESTBeaconManager *beaconManager;
@property (nonatomic, strong) ESTBeaconRegion *region;
@property (strong, nonatomic) NSArray *beaconData;
@property (strong, nonatomic) NSMutableArray *beaconButtons;
@property (nonatomic)         CFTimeInterval lastBeaconButtonSwap;
@end

@implementation RRNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.beaconButtons = [[NSMutableArray alloc] init];
    self.lastBeaconButtonSwap = 0;
    self.audioPlayer = [[RRNBeaconAudioPlayer alloc] init];
    [self.audioPlayer setEnabled:self.audioButton.selected];
    
    [self goToUrl: @"http://m.rrnpilot.org"];
    
    [self startBeaconManager];
    
    // Fetch the Beacon JSON
    [self fetchJSONFrom:@"http://192.168.0.199:3000/holding_institutions/1/point_of_interests.json" withCallback:^(NSMutableDictionary* beaconData){
        NSLog(@"Retrieved Beacon Data %@", beaconData);
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
- (NSMutableArray *)sanitizeBeaconData:(NSMutableDictionary *)beaconData
{
    NSMutableArray *output = [[NSMutableArray alloc] init];
    for(NSMutableDictionary *data in beaconData){
        data[@"major"] = [NSNumber numberWithInt:[data[@"major"] intValue]];
        data[@"minor"] = [NSNumber numberWithInt:[data[@"minor"] intValue]];
        [output addObject:data];
    }
    
    return output;
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

- (NSDictionary*)beaconDataForMajor:(NSNumber*)major minor:(NSNumber*)minor
{
    for(NSDictionary *beaconData in self.beaconData){
        if ([beaconData[@"major"] isEqualToNumber:major] && [beaconData[@"minor"] isEqualToNumber:minor]){
            return beaconData;
        }
    }
    return NULL;
}

- (RRNBeaconButton *)beaconButtonForBeacon:(ESTBeacon *)beacon
{
    for(RRNBeaconButton *beaconButton in self.beaconButtons){
        if ([beaconButton.major isEqualToNumber:beacon.major] && [beaconButton.minor isEqualToNumber:beacon.minor]){
            return beaconButton;
        }
    }
    return NULL;
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
    
    [self.audioPlayer playUrl:@"https://archive.org/download/testmp3testfile/mpthreetest.mp3"];
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

- (IBAction)toggleAudio:(id)sender {
    self.audioButton.selected = !self.audioButton.selected;
    [self.audioPlayer setEnabled:self.audioButton.selected];
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
    NSLog(@"%f", CACurrentMediaTime() - self.lastBeaconButtonSwap);

    NSLog(@"Ranged Beacons");
    
    RRNBeaconButton *currentBeaconButton = [self.beaconButtons firstObject];
    ESTBeacon *currentBeacon;
    ESTBeacon *closestBeacon;
    
    for (ESTBeacon *beacon in beacons) {
        NSLog(@"%@:%@ %@m", beacon.major, beacon.minor, beacon.distance);
        if (0 < [beacon.distance floatValue] && [beacon.distance floatValue] < 17){
            if (!closestBeacon || [beacon.distance floatValue] < [closestBeacon.distance floatValue]) {
                closestBeacon = beacon;
            }
        }
        if (currentBeaconButton && [currentBeaconButton.major floatValue] == [beacon.major floatValue] && [currentBeaconButton.minor floatValue] == [beacon.minor floatValue]){
            currentBeacon = beacon;
        }
    }
    
    if (closestBeacon) {

        // Only replace the current beacon if we're more than 4 meters closer (prevents flipflopping between beacons due to distance inaccuracy)
        if ( currentBeacon && [currentBeacon.distance floatValue] < [closestBeacon.distance floatValue] + 2.5) { return; }

        BOOL willSwap = currentBeaconButton && currentBeaconButton != [self beaconButtonForBeacon:closestBeacon];

        // Don't swap the beacons more than once every 5 seconds
        if (willSwap && CACurrentMediaTime() - self.lastBeaconButtonSwap < 5){ return; }
        
        // If the current beacon isn't the closest beacon, remove it
        if (willSwap){
            self.lastBeaconButtonSwap = CACurrentMediaTime();
            [self removeBeaconButton:currentBeaconButton];
        }

        [self addBeaconButton:closestBeacon];
    } else {
        [self removeBeaconButton:currentBeaconButton];
    }
}
@end
