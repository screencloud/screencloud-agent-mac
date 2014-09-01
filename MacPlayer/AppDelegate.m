//
//  AppDelegate.m
//  MacPlayer
//
//  Created by Nattapong kongmun on 5/8/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import "AppDelegate.h"
#import "AwakeManager.h"
#import "PreferencesController.h"

//#import "GCDHttpd.h"
//#import "GCDAsyncUdpSocket.h"

@implementation AppDelegate {
    GCDAsyncUdpSocket *udpSocket;
    BOOL isRunning;
}

#define kShowIcon @"showIcon"
#define kOnline @"isOnline"
#define kScreenCloudUrl @"http://screencloud.io"
#define kIcon @"MenuIcon"
#define kActiveIcon @"MenuIconActive"
#define kPreferencesTitle @"Preferences"
#define kAlwayAwake @"alwayAwake"

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // load sreencloud url
    NSURLRequest *request = [NSURLRequest requestWithURL:
                             [NSURL URLWithString:kScreenCloudUrl]];
    [self.screenView.mainFrame loadRequest:request];

    [_window toggleFullScreen:self];
    [_window makeFirstResponder: self.screenView];
    //[self.screenView enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
    
    awakeManager = [[AwakeManager alloc] initWithSleepOff:NO];
    [self checkAwakeStatus];
    
    //udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)checkAwakeStatus
{
    NSLog(@"check awake status");
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kAlwayAwake]) {
        [awakeManager turnOn];
        NSLog(@"turn awake on");
    } else {
        [awakeManager turnOff];
        NSLog(@"turn awake off");
    }
}

- (void)awakeFromNib
{
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: 22.0];
    
	statusView = [[StatusItemView alloc] initWithStatusItem: statusItem];
	[statusView setMenu: statusMenux];
    [statusView setImage: [NSImage imageNamed:kIcon]];
    [statusView setAlternateImage: [NSImage imageNamed:kActiveIcon]];
    
    [statusItem setView: statusView];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnline] == 0) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kOnline];
    }
    
    [self setupSocket];
//    [self startWebServer];
    [self setOnlineState];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShowIcon] == 0) {
        [statusView setHidden:YES];
    }
}

- (void)dealloc
{
    [udpSocket close];
}

- (void)setupSocket
{
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    if (![udpSocket bindToPort:1900  error:&error])
    {
        NSLog(@"Error binding to port: %@", error);
        return;
    }
    if(![udpSocket joinMulticastGroup:@"239.255.255.250" error:&error]){
        NSLog(@"Error connecting to multicast group: %@", error);
        return;
    }
    if (![udpSocket beginReceiving:&error])
    {
        NSLog(@"Error receiving: %@", error);
        return;
    }
    NSLog(@"Socket Ready");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSLog(@"***********************");
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg)
    {
        NSLog(@"msg %@", msg);
    }
    else
    {
        NSLog(@"Error converting received data into UTF-8 String");
    }
    
    //[udpSocket sendData:data toAddress:address withTimeout:-1 tag:0];
}

//- (void)startSSDP
//{
//    if (isRunning)
//    {
//        // STOP udp echo server
//        
//        [udpSocket close];
//        
//        NSLog(@"Stopped Udp Echo server");
//
//        isRunning = false;
//    }
//    else
//    {
//        // START udp echo server
//        
//        int port = 9100;
//        
//        NSError *error = nil;
//        
//        if (![udpSocket bindToPort:port error:&error])
//        {
//            NSLog(@"Error starting server (bind): %@", error);
//            return;
//        }
//        if (![udpSocket beginReceiving:&error])
//        {
//            [udpSocket close];
//            
//            NSLog(@"Error starting server (recv): %@", error);
//            return;
//        }
//        
//        NSLog(@"Udp Echo server started on port %hu", [udpSocket localPort]);
//        isRunning = YES;
//        NSLog(@"Started");
//    }
//}
//
//- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
//      fromAddress:(NSData *)address
//withFilterContext:(id)filterContext
//{
//    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    if (msg)
//    {
//        NSLog(@"msg %@", msg);
//    }
//    else
//    {
//        NSLog(@"Error converting received data into UTF-8 String");
//    }
//    
//    [udpSocket sendData:data toAddress:address withTimeout:-1 tag:0];
//}

//- (void)startWebServer
//{
//    // Initialize the httpd
//    httpd = [[GCDHttpd alloc] initWithDispatchQueue:dispatch_get_current_queue()];
//    httpd.port = 8000;       // Listen on 0.0.0.0:8000
//    // Router setup
//    // [httpd addTarget:self action:@selector(deferredIndex:) forMethod:@"GET" role:@"/users/:userid"];
//    [httpd addTarget:self action:@selector(simpleIndex:) forMethod:@"GET" role:@"/"];
//    // [httpd serveDirectory:@"/tmp/" forURLPrefix:@"/t/"];    // Static file serving "/t/"
//    [httpd serveResource:@"screen.png" forRole:@"/icon1024.png"];   // Resource in the main bundle
//    
//    [httpd start];
//}

//- (id)simpleIndex:(GCDRequest *)request {
//    return @"hello";
//}

- (void)setOnlineState
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnline]) {
		[statusView setImage: [NSImage imageNamed:kActiveIcon]];
	} else {
        [statusView setImage: [NSImage imageNamed:kIcon]];
    }
}

- (IBAction)showPreferences:(id)sender
{
    //if (!preferencesController) {
		preferencesController = [[PreferencesController alloc] initWithWindowNibName:kPreferencesTitle];
	//}
	[[preferencesController window] center];

	[preferencesController showWindow: self];
}

- (IBAction)showHideAppAtStatusBar:(id)sender
{
    if ([statusView isHidden]) {
        [statusView setHidden:NO];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShowIcon];
    } else {
        [statusView setHidden:YES];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShowIcon];
    }
}

- (IBAction)showHideAction:(id)sender
{
    if ([self window].isVisible) {
        [[self window] orderOut:nil];
    } else {
        [[self window] makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];// Bring to front
    }
}

- (IBAction)setGetMessageOn:(id)sender
{
    NSLog(@"get messsage from server every 1 sec.");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kOnline];
    [self setOnlineState];
}

- (IBAction)setGetMessageOff:(id)sender
{
    NSLog(@"stop get messsage from server");
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kOnline];
    [self setOnlineState];
}

- (IBAction)quitAction:(id)sender
{
    [NSApp terminate:self];
}

- (void)keyDown:(NSEvent *)e {
    unsigned short keyPress = [e keyCode];
    long flags = [e modifierFlags];
    
    NSLog(@"key -> %d", [e keyCode]);
    
    NSLog (@"%hu", keyPress);
    
    if (flags & NSAlternateKeyMask) {
        if (keyPress == 76 || keyPress == 36) {    // option + return or enter
            NSLog(@"option + return or enter");
            
            //            [_window setFrame:[_window frameRectForContentRect:[[_window screen] frame]] display:YES animate:YES];
            //            SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
            //            [NSMenu setMenuBarVisible:NO];
            
            
            
        } else if (keyPress == 53) {    // option + return or enter
            NSLog(@"option + esc");
            
            
        }
    }
}

@end
