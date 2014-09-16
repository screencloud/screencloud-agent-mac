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
#import <sys/sysctl.h>

#import "GCDHttpd.h"
//#import "GCDAsyncUdpSocket.h"

@implementation AppDelegate {
    GCDAsyncUdpSocket *udpSocket;
    BOOL isRunning;
    GCDHttpd *httpd;
}

#define kShowIcon @"showIcon"
#define kOnline @"isOnline"
#define kScreenCloudUrl @"http://screencloud.io"
#define kIcon @"MenuIcon"
#define kActiveIcon @"MenuIconActive"
#define kPreferencesTitle @"Preferences"
#define kAlwayAwake @"alwayAwake"
#define kUUID @"uuid"

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
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: 24.0];
	statusView = [[StatusItemView alloc] initWithStatusItem: statusItem];
	[statusView setMenu: statusMenux];
    [statusView setImage: [NSImage imageNamed:@"Status"]];
    [statusView setAlternateImage: [NSImage imageNamed:@"StatusHighlighted"]];
    [statusItem setView: statusView];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnline] == 0) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kOnline];
    }
    
    [self setupSocket];
    [self startWebServer];
    [self setOnlineState];
    
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShowIcon] == 0) {
//        [statusView setHidden:YES];
//    }
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
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (msg)
    {
        if (!([msg rangeOfString:@"M-SEARCH * HTTP/1.1"].location == NSNotFound)) {
            NSString *responsePayload = @"HTTP/1.1 200 OK\n" \
            "ST: urn:dial-multiscreen-org:service:dial:1\n" \
            "HOST: 239.255.255.250:1900\n" \
            "EXT:\n" \
            "CACHE-CONTROL: max-age=1800\n" \
            "LOCATION: http://%@:8008/ssdp/device-desc.xml\n" \
            "CONFIGID.UPNP.ORG: 7339\n" \
            "BOOTID.UPNP.ORG: 7339\n" \
            "USN: uuid:%@\n\n";
            
            @try {
                responsePayload = [NSString stringWithFormat:responsePayload, [self getIPWithNSHost], [self UUID]];
                NSData *d = [responsePayload dataUsingEncoding:NSUTF8StringEncoding];
                [udpSocket sendData:d toAddress:address withTimeout:-1 tag:0];
            }
            @catch ( NSException *e ) {
                NSLog(@"error %@", e);
            }
        }
    }
    else
    {
        NSLog(@"Error converting received data into UTF-8 String");
    }
}

-(NSString *)getIPWithNSHost{
    NSArray *addresses = [[NSHost currentHost] addresses];
    NSString *stringAddress;
    for (NSString *anAddress in addresses) {
        if (![anAddress hasPrefix:@"127"] && [[anAddress componentsSeparatedByString:@"."] count] == 4) {
            stringAddress = anAddress;
            break;
        } else {
            // stringAddress = @"IPv4 address not available" ;
            stringAddress = @"127.0.0.1";
        }
    }
    return stringAddress;
}

- (void)startWebServer
{
    // Initialize the httpd
    httpd = [[GCDHttpd alloc] initWithDispatchQueue:dispatch_get_current_queue()];
    httpd.port = 8008;       // Listen on 0.0.0.0:8008
    // Router setup
    // [httpd addTarget:self action:@selector(deferredIndex:) forMethod:@"GET" role:@"/users/:userid"];
    [httpd addTarget:self action:@selector(simpleIndex:) forMethod:@"GET" role:@"/"];
    [httpd addTarget:self action:@selector(deviceIndex:) forMethod:@"GET" role:@"/ssdp/device-desc.xml"];
    [httpd addTarget:self action:@selector(appIndex:) forMethod:@"GET" role:@"/apps"];
    [httpd addTarget:self action:@selector(screencloudGet:) forMethod:@"GET" role:@"/apps/ScreenCloud"];
    [httpd addTarget:self action:@selector(screencloudPost:) forMethod:@"POST" role:@"/apps/ScreenCloud"];
    // [httpd serveDirectory:@"/tmp/" forURLPrefix:@"/t/"];    // Static file serving "/t/"
    [httpd serveResource:@"screen.png" forRole:@"/icon1024.png"];   // Resource in the main bundle
    
    [httpd start];
}

- (id)screencloudGet:(GCDRequest *)request {
    return @"";
}

- (id)screencloudPost:(GCDRequest *)request {
    NSString* commandObj = [[NSString alloc] initWithData:request.rawData encoding:NSUTF8StringEncoding];
    NSLog(@"message %@", commandObj);
    
    NSData *jsonData = [commandObj dataUsingEncoding:NSUTF8StringEncoding];
    NSError *e;
    NSDictionary *commandDict = [NSJSONSerialization JSONObjectWithData:jsonData options:nil error:&e];
    if (commandDict) {
        if ([commandDict[@"command"] isEqualToString:@"open_url"]) {    
            NSString *url = commandDict[@"url"];
            NSURLRequest *request = [NSURLRequest requestWithURL:
                                     [NSURL URLWithString:url]];
            [self.screenView.mainFrame loadRequest:request];
        }
    } else {
        NSLog(@"do have dict");
    }
    return @"";
}

- (id)simpleIndex:(GCDRequest *)request {
    return @"hello";
}

- (id)appIndex:(GCDRequest *)request {
    
    //    NSString *appInfo = @"";
    NSString *appInfo = @"<?xml version='1.0' encoding='UTF-8'?>\n" \
    "    <service xmlns='urn:dial-multiscreen-org:schemas:dial'>\n" \
    "        <name>%@</name>\n" \
    "        <options allowStop='true'/>\n" \
    "        <activity-status xmlns='urn:chrome.google.com:cast'>\n" \
    "            <description>Legacy</description>\n" \
    "        </activity-status>\n" \
    "        <servicedata xmlns='urn:chrome.google.com:cast'>\n" \
    "            <connectionSvcURL>%@</connectionSvcURL>\n" \
    "            <protocols>%@</protocols>\n" \
    "        </servicedata>\n" \
    "        <state>%@</state>\n" \
    "        %@\n" \
    "    </service>";
    
    appInfo = [NSString stringWithFormat:appInfo, @"", @"", @"", @"", @""];
    
    GCDResponse * response = [request responseWithStatus:200 message:appInfo];
    response.headers[@"Access-Control-Allow-Method"] = @"GET, POST, DELETE, OPTIONS";
    response.headers[@"Access-Control-Expose-Headers"] = @"Location";
    response.headers[@"Cache-control"] = @"no-cache, must-revalidate, no-store";
    response.headers[@"Content-type"] = @"application/xml;charset=utf-8";
    response.headers[@"Application-URL"] = [NSString stringWithFormat:@"http://%@:8008/apps/", [self getIPWithNSHost]];
    
    return response;
}


- (id)deviceIndex:(GCDRequest *)request
{
    
    NSString *deviceDesc = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" \
    "    <root xmlns=\"urn:schemas-upnp-org:device-1-0\">\n" \
    "        <specVersion>\n" \
    "        <major>1</major>\n" \
    "        <minor>0</minor>\n" \
    "        </specVersion>\n" \
    "        <URLBase>#base#</URLBase>\n" \
    "        <device>\n" \
    "            <deviceType>urn:dial-multiscreen-org:device:dial:1</deviceType>\n" \
    "            <friendlyName>#friendlyname#</friendlyName>\n" \
    "            <manufacturer>#manufacturer#</manufacturer>\n" \
    "            <modelName>#modelName#</modelName>\n" \
    "            <UDN>uuid:#uuid#</UDN>\n" \
    "            <serviceList>\n" \
    "                <service>\n" \
    "                    <serviceType>urn:schemas-upnp-org:service:dial:1</serviceType>\n" \
    "                    <serviceId>urn:upnp-org:serviceId:dial</serviceId>\n" \
    "                    <controlURL>/ssdp/notfound</controlURL>\n" \
    "                    <eventSubURL>/ssdp/notfound</eventSubURL>\n" \
    "                    <SCPDURL>/ssdp/notfound</SCPDURL>\n" \
    "                </service>\n" \
    "            </serviceList>\n" \
    "        </device>\n" \
    "    </root>";
    
    deviceDesc = [deviceDesc stringByReplacingOccurrencesOfString:@"#friendlyname#" withString:@"Mac agent"];
    deviceDesc = [deviceDesc stringByReplacingOccurrencesOfString:@"#manufacturer#" withString:@"Apple inc."];
    deviceDesc = [deviceDesc stringByReplacingOccurrencesOfString:@"#modelName#" withString:@"Retina"];
    deviceDesc = [deviceDesc stringByReplacingOccurrencesOfString:@"#uuid#" withString:[self UUID]];
    deviceDesc = [deviceDesc stringByReplacingOccurrencesOfString:@"#base#" withString:[NSString stringWithFormat:@"http://%@:8008/apps/", [self getIPWithNSHost]]];

    GCDResponse * response = [request responseWithStatus:200 message:deviceDesc];
    response.headers[@"Access-Control-Allow-Method"] = @"GET, POST, DELETE, OPTIONS";
    response.headers[@"Access-Control-Expose-Headers"] = @"Location";
    response.headers[@"Content-type"] = @"application/xml";
    response.headers[@"Application-URL"] = [NSString stringWithFormat:@"http://%@:8008/apps/", [self getIPWithNSHost]];
    return response;
}
                  
- (NSString *)UUID {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *uuid;
    if ([userDefaults valueForKey:kUUID]){
        uuid = [userDefaults valueForKey:kUUID];
    } else {
        uuid = [self generateUUID];
        [userDefaults setValue:uuid forKey:kUUID];
        [userDefaults synchronize];
    }
    return uuid;
}

- (NSString*)generateUUID {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge NSString *)string;
}

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

- (IBAction)fullscreenAction:(id)sender
{
    NSLog(@"take full screen");
    
    [_window toggleFullScreen:self];
    
    
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
