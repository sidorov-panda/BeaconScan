//
//  BSAppDelegate.m
//  BeaconScan
//
//  Created by Edouard FISCHER on 10/08/2014.
//  Copyright (c) 2014 Edouard FISCHER. All rights reserved.
//

#import "MPAppDelegate.h"
@import AVFoundation;
@import CoreLocation;

@interface MPAppDelegate () <CLLocationManagerDelegate, AVSpeechSynthesizerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVSpeechSynthesizer *synthe;
@property (nonatomic) BOOL canLoop;

@end

@implementation MPAppDelegate

#pragma mark - UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // setup location manager and start monitoring for beacon
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    NSUUID *proximity = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID: proximity identifier:@"beaconTestRegion"];
    beaconRegion.notifyEntryStateOnDisplay = YES;
    [self.locationManager startMonitoringForRegion:beaconRegion];
    
    // setup background audio session and voice synthesizer
    self.audioSession = [AVAudioSession sharedInstance];
    [self.audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    
    self.synthe = [[AVSpeechSynthesizer alloc] init];
    [self.synthe setDelegate:self];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSLog(@"did enter background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    NSLog(@"will enter foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSLog(@"did become active");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        
        self.canLoop = NO;
        NSLog(@"exit region");
        [self speakMessageWithString:@"Au revoir"];
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
        NSLog(@"monitored regions= %@", self.locationManager.monitoredRegions );
        [self.locationManager stopMonitoringForRegion:region];
        [self.locationManager startMonitoringForRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"authorization status = %d", status);
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"start monitoring %@",region);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"monitoring failed for region %@ error %@",region, error);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        
        NSLog(@"enter region");
        [self speakMessageWithString:@"Bienvenue"];
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    
    NSLog(@"determined state: %d", state);
    
    if (state == CLRegionStateInside) {
        self.canLoop = YES;
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
        
        // request extra running time in background for ranging
        __block UIBackgroundTaskIdentifier background_task;
        UIApplication *application = [UIApplication sharedApplication];
        
        background_task = [application beginBackgroundTaskWithExpirationHandler:^ {
            NSLog(@"cleanup code for end of background allowed running time");
            [application endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid;
            
        }];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (self.canLoop)
            {
                NSTimeInterval remaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
                //get extra time
                if (remaining < 150) {
                    [self speakMessageWithString:@"en approche"];
                }
                [NSThread sleepForTimeInterval:1]; //wait for 1 sec
            }
            
            NSLog(@"end of loop");
            [application endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid;
        });
        
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    
    long back = 0, front = 0;
    CLBeacon *beacon;
    
    for (beacon in beacons) {
        if ([beacon.minor isEqual: @1]) back = beacon.rssi;
        if ([beacon.minor isEqual: @0]) front = beacon.rssi;
    }
    
    if (beacons.count >0)
    {
        NSTimeInterval remaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
        NSLog(@"time %f #%lu delta %ld",(remaining < 10000)?remaining:10000, (unsigned long)beacons.count, front - back);
        
        //[self speakMessageWithString:[NSString stringWithFormat:@"%lu %ld",(unsigned long)beacons.count, front-back]];
    }
    
}

#pragma mark - AVSpeechSynthesizer & AVSpeechSynthesizerDelegate methods

- (void)speakMessageWithString:(NSString *)string
{
    
    NSError *error = nil;
    [self.audioSession setActive:YES error:&error];
    
    AVSpeechUtterance *message = [[AVSpeechUtterance alloc] initWithString:string];
    [self.synthe speakUtterance:message];
    
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSError *error = nil;
    [self.audioSession setActive:NO error:&error];
}

@end
