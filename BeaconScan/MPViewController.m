//
//  MPViewController.m
//  BeaconScan
//
//  Created by Edouard FISCHER on 16/08/2014.
//  Copyright (c) 2014 Edouard FISCHER. All rights reserved.
//

#import "MPViewController.h"

@interface MPViewController ()

@end

@implementation MPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connect:) name:@"iBeaconConnectable" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)connect:(NSNotification *)notification {
    NSLog(@"could connect");
    NSOperation *revert = notification.userInfo[@"revert"];
    [revert start];
}
@end
