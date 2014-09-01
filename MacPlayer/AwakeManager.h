//
//  AwakeManager.h
//  MacPlayer
//
//  Created by Nattapong kongmun on 5/12/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

@interface AwakeManager : NSObject
{
    BOOL isSleepOff;
	IOPMAssertionID displayAssertionId;
	IOPMAssertionID idleAssertionId;
}

@property (assign) BOOL isSleepOff;

-(id)initWithSleepOff: (BOOL) sleepOff;
-(void) turnOn;
-(void) turnOff;

@end
