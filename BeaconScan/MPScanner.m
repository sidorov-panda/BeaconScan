//
//  MPScanner.m
//  BeaconScan
//
//  Created by Edouard FISCHER on 17/08/2014.
//  Copyright (c) 2014 Edouard FISCHER. All rights reserved.
//

#import "MPScanner.h"
@import  CoreLocation;
@import AVFoundation;

@interface MPScanner () <CLLocationManagerDelegate, AVSpeechSynthesizerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, strong) AVSpeechSynthesizer *synthe;
@property (nonatomic) BOOL canLoop;
@property (nonatomic) BOOL canConnect;

@end

@implementation MPScanner

- (id)initWithUuid:(NSString *)proximity
{
    self = [super init];
    
    if (self) {
        self.proximityUuid = proximity;
        self.delta = 9;
        self.threshold = -70;
        
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        // setup background audio session and voice synthesizer
        self.audioSession = [AVAudioSession sharedInstance];
        [self.audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
        
        self.synthe = [[AVSpeechSynthesizer alloc] init];
        [self.synthe setDelegate:self];
    }
    return self;
}

- (void)start
{
    NSUUID *proximityUuid = [[NSUUID alloc] initWithUUIDString:self.proximityUuid];
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID: proximityUuid identifier:@"beaconTestRegion"];
    self.canLoop = NO;
    
    [self.locationManager startMonitoringForRegion:beaconRegion];
}

- (void)stop
{
    self.canLoop = NO;
    NSUUID *proximityUuid = [[NSUUID alloc] initWithUUIDString:self.proximityUuid];
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID: proximityUuid identifier:@"beaconTestRegion"];
    [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
    [self.locationManager stopMonitoringForRegion:beaconRegion];
    
    NSError *error = nil;
    [self.audioSession setActive:NO error:&error];
}


#pragma mark - CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        NSLog(@"enter region");
        [self speakMessageWithString:@"Bienvenue"];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        self.canLoop = NO;
        self.canConnect = NO;
        NSLog(@"exit region");
        [self speakMessageWithString:@"Au revoir"];
        
        [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
        [self.locationManager stopMonitoringForRegion:region];
        [self.locationManager startMonitoringForRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusAuthorized:
            NSLog(@"authorization status = Authorized");
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"authorization status = Denied");
            break;
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"authorization status = Not Determined");
            break;
        case kCLAuthorizationStatusRestricted:
            NSLog(@"authorization status = Restricted");
            break;
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"start monitoring %@",region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"monitoring failed for region %@ error %@",region, error);
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside:
            NSLog(@"determined state: Inside");
            break;
        case CLRegionStateOutside:
            NSLog(@"determined state: Outside");
            break;
        case CLRegionStateUnknown:
            NSLog(@"determined state: Unknown");
            break;
        default:
            break;
    }
    
    if (state == CLRegionStateInside && !self.canLoop) {
        self.canLoop = YES;
        self.canConnect = YES;
        [self.locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
        
        // request extra running time in background for ranging
        __block UIBackgroundTaskIdentifier background_task;
        UIApplication *application = [UIApplication sharedApplication];
        
        background_task = [application beginBackgroundTaskWithExpirationHandler:^ {
            NSLog(@"cleanup code for end of background allowed running time");
            [application endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid;
        }];
        
        // run background loop in a separate process
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"start of background loop");
            while (self.canLoop)
            {
                NSTimeInterval remaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
                // background audio resets remaining time
                if (remaining < 150) {
                    [self speakMessageWithString:@"toujours en approche"];
                }
                [NSThread sleepForTimeInterval:1]; //wait for 1 sec
            }
            NSLog(@"end of background loop");
            [application endBackgroundTask: background_task];
            background_task = UIBackgroundTaskInvalid;
        });
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    long back = -128, front = -128;
    CLBeacon *beacon;
    
    unsigned int count = 0;
    long maxval = -128;
    
    for (beacon in beacons) {
        if ([beacon.minor isEqual: @1]) back = beacon.rssi;
        if ([beacon.minor isEqual: @0]) front = beacon.rssi;
        
        if (beacon.rssi < 0) {
            count ++;
            if (beacon.rssi > maxval) maxval = beacon.rssi;
        }
    }
    
    if (count >0)
    {
        NSTimeInterval remaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
        NSLog(@"time %f #%lu max %ld delta %ld",(remaining < 10000)?remaining:10000, (unsigned long)count, maxval, front - back);
    }
    
    if (count == 2 && (front-back) >=self.delta && self.canConnect && maxval > self.threshold) {
        [self speakMessageWithString:@"Connection"];
        
        // suspend connectability during connection
        self.canConnect = NO;
        
        // callback for aborted connection
        NSBlockOperation *revertOperation = [NSBlockOperation blockOperationWithBlock:^{
            [self speakMessageWithString:@"connection annulée"];
            self.canConnect = YES; }];
        
        NSDictionary *userInfoDict = @{@"beacons" : beacons,
                                       @"revert" : revertOperation};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"iBeaconConnectable" object:self userInfo:userInfoDict];
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
