//
//  PreferencesController.m
//  MacAgent
//
//  Created by Nattapong kongmun on 5/8/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import "PreferencesController.h"
//#import "StartAtLoginController.h"
#import "AppDelegate.h"

#define kRunAtLogin @"runAtLogin"
#define kAlwayAwake @"alwayAwake"
#define kVisibleLocal @"visibleLocal"

@interface PreferencesController (){
//    StartAtLoginController *loginController;
}
@property (weak) IBOutlet NSButton *autoRunOnLogin;
@property (weak) IBOutlet NSButton *alwaysAwake;
@property (weak) IBOutlet NSButton *visibleViaLocalNetwork;

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
//        loginController = [[StartAtLoginController alloc] initWithIdentifier:@"com.codegent.screencloud.MacAgentHelper"];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
//    [_autoLaunchButton setState: [[NSUserDefaults standardUserDefaults] boolForKey: kRunAtLogin]];
    [_alwayAwakeButton setState: [[NSUserDefaults standardUserDefaults] boolForKey: kAlwayAwake]];
    [_visibleLocalNetworkButton setState: [[NSUserDefaults standardUserDefaults] boolForKey: kVisibleLocal]];
    
    
    if( [self isLaunchAtStartup] ){
        self.autoRunOnLogin.state = NSOnState;
    }else{
        self.autoRunOnLogin.state = NSOffState;
    }
    
}

- (IBAction)autoLaunchAction:(id)sender
{
    [self toggleLaunchAtStartup];
    
//    if ([sender state]) {
//		if (![loginController startAtLogin]) {
//			[loginController setStartAtLogin: YES];
//		}
//	} else {
//		if ([loginController startAtLogin]) {
//			[loginController setStartAtLogin:NO];
//		}
//	}
//    NSLog(@"%d", [loginController startAtLogin]);
    
	[[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:kRunAtLogin];
    
    if( [self isLaunchAtStartup] ){
        self.autoRunOnLogin.state = NSOnState;
    }else{
        self.autoRunOnLogin.state = NSOffState;
    }
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
        [(AppDelegate *)[[NSApplication sharedApplication] delegate]startService];
        
//        [(AppDelegate *)[[NSApplication sharedApplication] delegate] setupSocket];
//        [(AppDelegate *)[[NSApplication sharedApplication] delegate] startWebServer];
        
    } else {
        NSLog(@"turn off visibe via local network");
//        [(AppDelegate *)[[NSApplication sharedApplication] delegate] stopSocket];
//        [(AppDelegate *)[[NSApplication sharedApplication] delegate] stopWebServer];
        [(AppDelegate *)[[NSApplication sharedApplication] delegate] stopService];
        
    }
}




// Login Items

- (BOOL)isLaunchAtStartup {
    // See if the app is currently in LoginItems.
    LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
    // Store away that boolean.
    BOOL isInList = itemRef != nil;
    // Release the reference if it exists.
    if (itemRef != nil) CFRelease(itemRef);
    
    return isInList;
}

- (void)toggleLaunchAtStartup {
    // Toggle the state.
    BOOL shouldBeToggled = ![self isLaunchAtStartup];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return;
    if (shouldBeToggled) {
        // Add the app to the LoginItems list.
        CFURLRef appUrl = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
        if (itemRef) CFRelease(itemRef);
        
        NSLog(@"added toggle app : %@", appUrl);
        
    }
    else {
        // Remove the app from the LoginItems list.
        LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
        LSSharedFileListItemRemove(loginItemsRef,itemRef);
        if (itemRef != nil) CFRelease(itemRef);
        
        NSLog(@"remove toggle app");
    }
    CFRelease(loginItemsRef);
}

- (LSSharedFileListItemRef)itemRefInLoginItems {
    LSSharedFileListItemRef res = nil;
    
    // Get the app's URL.
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return nil;
    // Iterate over the LoginItems.
    NSArray *loginItems = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, nil);
    for (id item in loginItems) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)(item);
        CFURLRef itemURLRef;
        if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
            // Again, use toll-free bridging.
            NSURL *itemURL = (__bridge NSURL *)itemURLRef;
            if ([itemURL isEqual:bundleURL]) {
                res = itemRef;
                break;
            }
        }
    }
    // Retain the LoginItem reference.
    if (res != nil) CFRetain(res);
    CFRelease(loginItemsRef);
    CFRelease((__bridge CFTypeRef)(loginItems));
    
    return res;
}


@end
