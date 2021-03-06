//
//  PreferencesController.h
//  MacAgent
//
//  Created by Nattapong kongmun on 5/8/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//@class StartAtLoginController;

@interface PreferencesController : NSWindowController
{
//    StartAtLoginController *loginController;
    __weak NSButtonCell *_autoLaunchButton;
    __weak NSButtonCell *_alwayAwakeButton;
    __weak NSButtonCell *_visibleLocalNetworkButton;
}
@property (weak) IBOutlet NSButtonCell *autoLaunchButton;
@property (weak) IBOutlet NSButtonCell *alwayAwakeButton;
@property (weak) IBOutlet NSButtonCell *visibleLocalNetworkButton;
@end
