//
//  ScreenCloudView.m
//  MacAgent
//
//  Created by Nattapong kongmun on 5/14/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import "ScreenCloudView.h"

@implementation ScreenCloudView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    
}

//- (void)cancelOperation:(id)sender
//{
//    NSLog(@"cancel");
//}

- (void)keyDown:(NSEvent *)e {
    unsigned short keyPress = [e keyCode];
    long flags = [e modifierFlags];

    // command + ...?
    if (flags & NSCommandKeyMask)
    {
        NSLog(@"Command key was pressed");
        if (keyPress == 76 || keyPress == 36) {
            NSLog(@"command + return or enter");
            [_window toggleFullScreen:self];
        }
    }
    
    // esc
    if (keyPress == 53) {    // option + return or enter
        NSLog(@"option + esc");
        
        if ([_window styleMask] & NSFullScreenWindowMask) {
            [_window toggleFullScreen:nil];
        }
    }
    
    // option + ...?
//    if (flags & NSAlternateKeyMask) {
//        if (keyPress == 76 || keyPress == 36) {    // option + return or enter
//            NSLog(@"option + return or enter");
//            
////            [_window setFrame:[_window frameRectForContentRect:[[_window screen] frame]] display:YES animate:YES];
////            SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
////            [NSMenu setMenuBarVisible:NO];
//            
//            //[_window toggleFullScreen:self];
//        }
//    }
}

@end
