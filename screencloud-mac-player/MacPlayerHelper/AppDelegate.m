//
//  AppDelegate.m
//  MacPlayerHelper
//
//  Created by Nattapong kongmun on 5/9/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	NSString *appPath = [[[NSBundle mainBundle] bundlePath] stringByReplacingOccurrencesOfString:@"/Contents/Library/LoginItems/MacPlayerHelper.app" withString:@""];
	NSString *binaryPath = [[NSBundle bundleWithPath:appPath] executablePath];
	[[NSWorkspace sharedWorkspace] launchApplication:binaryPath];
	[NSApp terminate:nil];
}
@end
