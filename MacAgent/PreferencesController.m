//
//  PreferencesController.m
//  MacAgent
//
//  Created by Nattapong kongmun on 5/8/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import "PreferencesController.h"
#import "StartAtLoginController.h"
#import "AppDelegate.h"

#define kRunAtLogin @"runAtLogin"
#define kAlwayAwake @"alwayAwake"
#define kVisibleLocal @"visibleLocal"

@interface PreferencesController ()

@end

@implementation PreferencesController

+ (void) initialize
{
	NSDictionary *defaultsRunAtLogin = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool:NO] forKey:kRunAtLogin];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsRunAtLogin];
    
    
	NSDictionary *defaultsAlwayAwake = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool:NO] forKey:kAlwayAwake];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsAlwayAwake];
    
    NSDictionary *defaultsVisibleLocal = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool:NO] forKey:kVisibleLocal];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsVisibleLocal];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        loginController = [[StartAtLoginController alloc] initWithIdentifier:@"com.codegent.screencloud.MacAgentHelper"];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [_autoLaunchButton setState: [[NSUserDefaults standardUserDefaults] boolForKey: kRunAtLogin]];
    [_alwayAwakeButton setState: [[NSUserDefaults standardUserDefaults] boolForKey: kAlwayAwake]];
    [_visibleLocalNetworkButton setState: [[NSUserDefaults standardUserDefaults] boolForKey: kVisibleLocal]];
}

- (IBAction)autoLaunchAction:(id)sender
{
    if ([sender state]) {
		if (![loginController startAtLogin]) {
			[loginController setStartAtLogin: YES];
		}
	} else {
		if ([loginController startAtLogin]) {
			[loginController setStartAtLogin:NO];
		}
	}
    //NSLog(@"%d", [loginController startAtLogin]);
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:kRunAtLogin];
}

- (IBAction)alwayAwakeAction:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:kAlwayAwake];
    
    [(AppDelegate *)[[NSApplication sharedApplication] delegate] checkAwakeStatus];
}

- (IBAction)visibleLocalNetworkAction:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:kVisibleLocal];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kVisibleLocal]) {
        NSLog(@"turn on visibe via local network");
        [(AppDelegate *)[[NSApplication sharedApplication] delegate] setupSocket];
        [(AppDelegate *)[[NSApplication sharedApplication] delegate] startWebServer];
    } else {
        NSLog(@"turn off visibe via local network");
        [(AppDelegate *)[[NSApplication sharedApplication] delegate] stopSocket];
        [(AppDelegate *)[[NSApplication sharedApplication] delegate] stopWebServer];
    }
}

@end
