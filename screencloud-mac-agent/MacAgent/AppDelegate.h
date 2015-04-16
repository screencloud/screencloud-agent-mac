//
//  AppDelegate.h
//  MacAgent
//
//  Created by Nattapong kongmun on 5/8/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Webkit/Webkit.h>
#import "StatusItemView.h"
#import "GCDAsyncUdpSocket.h"
#import "JSBridge.h"

@class AwakeManager;
@class PreferencesController;

@interface AppDelegate : NSObject <NSApplicationDelegate, JSBridgeDelegate>
{
    NSStatusItem *statusItem;
    StatusItemView *statusView;
    AwakeManager *awakeManager;
    PreferencesController *preferencesController;
}

@property (weak) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSMenuItem *fullscreenMenuItem;
@property (weak) IBOutlet NSMenuItem *showHidePlayerMenuItem;

@property (assign) IBOutlet NSWindow *playerWindow;

@property (weak) IBOutlet WebView *screenView;

- (IBAction)quitAction:(id)sender;
- (void)checkAwakeStatus;

- (void)startService;
- (void)stopService;


//- (void)setupSocket;
//- (void)stopSocket;
//- (void)startWebServer;
//- (void)stopWebServer;

// Javascirpt Expose
//+ (void) stop;

@end
