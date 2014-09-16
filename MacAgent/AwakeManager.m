//
//  AwakeManager.m
//  MacAgent
//
//  Created by Nattapong kongmun on 5/12/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import "AwakeManager.h"

@implementation AwakeManager
{
    
}

@synthesize isSleepOff = isSleepOff;

-(id)initWithSleepOff: (BOOL) sleepOff
{
	self = [super init];
	if (self != nil) {
		isSleepOff = sleepOff;
	}
	return self;
}

-(void) turnOn
{
    NSLog(@"******turnOn****");
	IOReturn ret;
	ret = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep, kIOPMAssertionLevelOn, CFSTR("DisplaySleepOff"), &displayAssertionId);
	if (ret == kIOReturnSuccess)
		NSLog(@"Display sleep is off");
    else
        NSLog(@"Display sleep can not to be off");
    
	ret = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep, kIOPMAssertionLevelOn, CFSTR("IdleSleepOff"), &idleAssertionId);
	if (ret == kIOReturnSuccess)
		NSLog(@"Idle sleep is off");
    else
        NSLog(@"Idle sleep can not to be off");
    
	isSleepOff = YES;
}

-(void) turnOff
{
	IOReturn ret;
	if (displayAssertionId != 0) {
		ret = IOPMAssertionRelease(displayAssertionId);
		if (ret == kIOReturnSuccess)
			NSLog(@"Display sleep is on");
		displayAssertionId = 0;
	}
	if (idleAssertionId != 0) {
		ret = IOPMAssertionRelease(idleAssertionId);
		if (ret == kIOReturnSuccess)
			NSLog(@"Idle sleep is on");
		idleAssertionId = 0;
	}
	isSleepOff = NO;
}

@end
