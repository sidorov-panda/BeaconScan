//
//  BSAppDelegate.m
//  BeaconScan
//
//  Created by Edouard FISCHER on 10/08/2014.
//  Copyright (c) 2014 Edouard FISCHER. All rights reserved.
//

#import "MPAppDelegate.h"
#import "MPScanner.h"
@import AVFoundation;
@import CoreLocation;

@interface MPAppDelegate ()

@property (nonatomic, strong) MPScanner *scanner;

@end

@implementation MPAppDelegate

#pragma mark - UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.scanner = [[MPScanner alloc] initWithUuid:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
    self.scanner.delta = 9;
    self.scanner.threshold = -70;
    
    [self.scanner start];
    
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
    
    NSLog(@"application did enter background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    NSLog(@"application will enter foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    NSLog(@"application did become active");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"application will terminate");
}




@end
