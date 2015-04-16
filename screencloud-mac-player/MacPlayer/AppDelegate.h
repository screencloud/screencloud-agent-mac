//
//  AppDelegate.h
//  MacPlayer
//
//  Created by Nattapong kongmun on 5/8/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Webkit/Webkit.h>
#import "StatusItemView.h"

@class AwakeManager;
@class PreferencesController;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSMenu *statusMenux;
    NSStatusItem *statusItem;
    StatusItemView *statusView;
    
    AwakeManager *awakeManager;

    PreferencesController *preferencesController;
}

@property (assign) IBOutlet NSWindow *window;

@property (weak) IBOutlet WebView *screenView;

- (IBAction)quitAction:(id)sender;
- (void)checkAwakeStatus;

@end
