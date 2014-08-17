//
//  MPScanner.h
//  BeaconScan
//
//  Created by Edouard FISCHER on 17/08/2014.
//  Copyright (c) 2014 Edouard FISCHER. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPScanner : NSObject

@property (nonatomic) int delta;
@property (nonatomic) int threshold;
@property (nonatomic, strong) NSString *proximityUuid;

- (id)initWithUuid:(NSString *)proximity;
- (void)start;
- (void)stop;

@end

