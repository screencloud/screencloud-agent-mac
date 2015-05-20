//
//  AppDelegate.m
//  MacAgent
//
//  Created by Nattapong kongmun on 5/8/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import "AppDelegate.h"
#import "AwakeManager.h"
#import "PreferencesController.h"
#import <sys/sysctl.h>
#import "GCDHttpd.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "Reachability.h"
//#import "GCDAsyncUdpSocket.h"

@implementation AppDelegate {
    GCDAsyncUdpSocket *udpSocket;
    BOOL isRunning;
    GCDHttpd *httpd;
    
    NSUInteger bootID;
    
    BOOL isInternetWentDown;
    JSBridge *jsBridge;
}

#define kShowIcon @"showIcon"
#define kOnline @"isOnline"
#define kScreenCloudUrl @"http://screenbox.io"  //http://screencloud.io
#define kIcon @"MenuIcon"
#define kActiveIcon @"MenuIconActive"
#define kPreferencesTitle @"Preferences"
#define kAlwayAwake @"alwayAwake"
#define kUUID @"uuid"
#define kVisibleLocal @"visibleLocal"
#define kLastOpenUrl @"kLastOpenUrl"

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    isInternetWentDown = NO;
    
    NSString *lastOpenURL = [[NSUserDefaults standardUserDefaults] stringForKey:kLastOpenUrl];
    
    if( [lastOpenURL isEqualToString:@""] || lastOpenURL == (id)[NSNull null] || !lastOpenURL || lastOpenURL == nil ){
        lastOpenURL = kScreenCloudUrl;
    }
    
    // Hack url for test
//    lastOpenURL = @"http://192.168.10.36:8888/jsbridge.html";
    
    
    
    NSLog(@" lastOpenURL = %@", lastOpenURL);
    
    // load default sreencloud url
    NSURLRequest *request = [NSURLRequest requestWithURL:
                             [NSURL URLWithString:lastOpenURL]];
    [self.screenView.mainFrame loadRequest:request];
    
    jsBridge = [[JSBridge alloc] init];
    jsBridge.delegate = self;
    id win = [self.screenView windowScriptObject];
    [win setValue:jsBridge forKey:@"ScreenCloudRemote"];
    
    [_playerWindow toggleFullScreen:self];
    [_playerWindow makeFirstResponder: self.screenView];
//    [self.screenView enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
    [self.screenView setFrameLoadDelegate:self];
    
    
    awakeManager = [[AwakeManager alloc] initWithSleepOff:NO];
    [self checkAwakeStatus];
    
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(appWillTerminateNotification:)
               name:NSApplicationWillTerminateNotification
             object:nil];
    
    
    // Allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    // Tell the reachability that we DON'T want to be reachable on 3G/EDGE/CDMA
//    reach.reachableOnWWAN = NO;
    
    // Here we set up a NSNotification observer. The Reachability that caused the notification
    // is passed in the object parameter
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    [reach startNotifier];
    
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

- (void)onStopScreen
{
    NSLog(@"--- onStopScreen ---");
    
    // load default sreencloud url
//    NSURLRequest *request = [NSURLRequest requestWithURL:
//                             [NSURL URLWithString:kScreenCloudUrl]];
//    [self.screenView.mainFrame loadRequest:request];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:kLastOpenUrl];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)awakeFromNib
{
    
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: 24.0];
	statusView = [[StatusItemView alloc] initWithStatusItem: statusItem];
	[statusView setMenu: self.statusMenu];
    [statusView setImage: [NSImage imageNamed:@"Status"]];
    [statusView setAlternateImage: [NSImage imageNamed:@"StatusHighlighted"]];
    [statusItem setView: statusView];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kOnline] == 0) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kOnline];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kVisibleLocal]) {
        NSLog(@"turn on visibe via local network");
        
        [self startService];
        
    } else {
        NSLog(@"turn off visibe via local network");
    }
    
    [self setOnlineState];
    
    if ([self playerWindow].isVisible) {
        self.showHidePlayerMenuItem.title = @"Show Player";
        
    } else {
        self.showHidePlayerMenuItem.title = @"Hide Player";
        
    }
    
//    if ([[NSUserDefaults standardUserDefaults] boolForKey:kShowIcon] == 0) {
//        [statusView setHidden:YES];
//    }
}

- (void)dealloc
{
    NSLog(@"-- dealloc --");
    [self sendByebye];
    [udpSocket close];
}

- (void) startService
{
    bootID = [[NSDate date] timeIntervalSince1970];
    NSLog(@"bootID = %li", bootID);
    
    [self setupSocket];
    [self startWebServer];
    
    [self sendNotifyAlive];
    [self performSelector:@selector(sendNotifyAlive) withObject:nil afterDelay:0.1];
    [self performSelector:@selector(sendNotifyAlive) withObject:nil afterDelay:0.2];
    
    /*
     Devices SHOULD wait a random interval (e.g. between 0 and 100milliseconds) before sending an initial set of advertisements in order to reduce the likelihood of network storms; this random interval SHOULD also be applied on occasions where the device obtains a new IP address or a new UPnP-enabled interface is installed.
     Due to the unreliable nature of UDP, devices SHOULD send the entire set of discovery messages more than once with some delay between sets e.g. a few hundred milliseconds. To avoid network congestion discovery messages SHOULD NOT be sent more than three times.
     */
}

- (void) stopService
{
    [self sendByebye];
    [self stopSocket];
    [self stopWebServer];
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

- (void)stopSocket
{
    NSLog(@"-- stopSocket --");
    [udpSocket close];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
//    NSString *addressMsg = [[NSString alloc] initWithData:address encoding:<#(NSStringEncoding)#>];
//    NSLog(@"address = %@", addressMsg );
//    NSLog(@"\n\n\nmsg = \n%@\n---------------", msg);
    
    if (msg)
    {
        if (!([msg rangeOfString:@"M-SEARCH * HTTP/1.1"].location == NSNotFound)) {
            NSString *responsePayload = @"HTTP/1.1 200 OK\n" \
            "ST: urn:dial-multiscreen-org:service:dial:1\n" \
            "HOST: 239.255.255.250:1900\n" \
            "EXT:\n" \
            "CACHE-CONTROL: max-age=1800\n" \
            "LOCATION: http://%@:9009/ssdp/device-desc.xml\n" \
            "CONFIGID.UPNP.ORG: 111\n" \
            "BOOTID.UPNP.ORG: %li\n" \
            "USN: uuid:%@\n\n";
            
            @try {
                
                responsePayload = [NSString stringWithFormat:responsePayload,
                                                                   [self getIPWithNSHost],
                                                                    bootID,
                                                                   [self UUID]];
                NSData *d = [responsePayload dataUsingEncoding:NSUTF8StringEncoding];
                
//                NSLog(@"responsePayload = %@", responsePayload);
//                NSLog(@"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
                
                [udpSocket sendData:d toAddress:address withTimeout:-1 tag:0];
                
            }
            @catch ( NSException *e ) {
                NSLog(@"error %@", e);
            }
        }
    }
    else
    {
//        NSLog(@"Error converting received data into UTF-8 String : msg = %@", msg);
    }
}

- (void)sendNotifyAlive
{
    // cache-control must be greater or equal to 1800
    NSString *responsePayload = @"NOTIFY * HTTP/1.1\n" \
    "HOST: 239.255.255.250:1900\n" \
    "CACHE-CONTROL: max-age=1800\n" \
    "LOCATION: http://%@:9009/ssdp/device-desc.xml\n" \
    "NT: urn:dial-multiscreen-org:service:dial:1\n" \
    "NTS: ssdp:alive\n" \
    "USN: uuid:%@\n" \
    "CONFIGID.UPNP.ORG: 111\n" \
    "BOOTID.UPNP.ORG: %li\n\n";
    
    
    responsePayload = [NSString stringWithFormat:responsePayload, [self getIPWithNSHost], [self UUID], bootID];
    NSData *data = [responsePayload dataUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(@"Send NotifyAlive responsePayload = %@", responsePayload);
    
    [udpSocket sendData:data toHost:@"239.255.255.250" port:1900 withTimeout:-1 tag:1];
    
    NSLog(@"SENT : NotifyAlive =====================");
}

- (void)sendByebye
{
    NSString *responsePayload = @"NOTIFY * HTTP/1.1\n" \
    "HOST: 239.255.255.250:1900\n" \
    "NT: urn:dial-multiscreen-org:service:dial:1\n" \
    "NTS: ssdp:byebye\n" \
    "USN: uuid:%@\n" \
    "CONFIGID.UPNP.ORG: 111\n" \
    "BOOTID.UPNP.ORG: %li\n\n";
    
    
    responsePayload = [NSString stringWithFormat:responsePayload, [self UUID], bootID];
    NSData *data = [responsePayload dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"sendByebye responsePayload = %@", responsePayload);
    
    [udpSocket sendData:data toHost:@"239.255.255.250" port:1900 withTimeout:-1 tag:1];
    
    NSLog(@"SENT : ssdp:byebye ====================");
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
    httpd = [[GCDHttpd alloc] initWithDispatchQueue:dispatch_get_main_queue()];  // dispatch_get_current_queue()
    
    httpd.port = 9009;       // Listen on 0.0.0.0:9009
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
    
    NSLog(@"webServer Started");
}

- (void)stopWebServer
{
    if (httpd) {
        [httpd stop];
    }
}

- (id)screencloudGet:(GCDRequest *)request {
    return @"";
}

- (id)screencloudPost:(GCDRequest *)request {
    NSString* commandObj = [[NSString alloc] initWithData:request.rawData encoding:NSUTF8StringEncoding];
    NSLog(@"\n\nscreencloudPost: message %@", commandObj);
    
    NSData *jsonData = [commandObj dataUsingEncoding:NSUTF8StringEncoding];
    NSError *e;
    NSDictionary *commandDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&e];
    
    if (commandDict) {
        if ([commandDict[@"command"] isEqualToString:@"open_url"]) {
            NSString *url = commandDict[@"url"];
            
            
            // Hack url for test
//            url = @"http://192.168.10.36:8888/jsbridge.html";
            
            
            NSURLRequest *request = [NSURLRequest requestWithURL:
                                     [NSURL URLWithString:url]];
            [self.screenView.mainFrame loadRequest:request];
            
            if(   !   ( [url isEqualToString:@""] || url == (id)[NSNull null] || !url || url == nil )) {
                [[NSUserDefaults standardUserDefaults] setObject:url forKey:kLastOpenUrl];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
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
    
    NSLog(@"appInfo = %@", appInfo);
    
    GCDResponse * response = [request responseWithStatus:200 message:appInfo];
    response.headers[@"Access-Control-Allow-Method"] = @"GET, POST, DELETE, OPTIONS";
    response.headers[@"Access-Control-Expose-Headers"] = @"Location";
    response.headers[@"Cache-control"] = @"no-cache, must-revalidate, no-store";
    response.headers[@"Content-type"] = @"application/xml;charset=utf-8";
    response.headers[@"Application-URL"] = [NSString stringWithFormat:@"http://%@:9009/apps/", [self getIPWithNSHost]];
    
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
    
    NSString *computerName = [[NSHost currentHost] localizedName];
    NSLog(@">> computerName = %@", computerName);
//    computerName = [[[[[[computerName stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;amp;"]
//        stringByReplacingOccurrencesOfString: @"\"" withString: @"&quot;"]
//       stringByReplacingOccurrencesOfString: @"'" withString: @"&#39;"]
//      stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"]
//     stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"]
//    stringByReplacingOccurrencesOfString: @"’" withString: @"&#39;"];
    
    NSLog(@" computerName = %@", computerName);
    
//    computerName = @"Jirasaks MacBook ProO";
    
    
    deviceDesc = [deviceDesc stringByReplacingOccurrencesOfString:@"#friendlyname#" withString:[self escapeHtml:computerName] ];
    deviceDesc = [deviceDesc stringByReplacingOccurrencesOfString:@"#manufacturer#" withString:@"ScreenCloud Mac, Apple inc."];
    deviceDesc = [deviceDesc stringByReplacingOccurrencesOfString:@"#modelName#" withString:@"Retina"];
    deviceDesc = [deviceDesc stringByReplacingOccurrencesOfString:@"#uuid#" withString:[self UUID]];
    deviceDesc = [deviceDesc stringByReplacingOccurrencesOfString:@"#base#" withString:[NSString stringWithFormat:@"http://%@:9009/apps/", [self getIPWithNSHost]]];
    
//    NSLog(@"deviceDesc = %@", deviceDesc);
    
    GCDResponse * response = [request responseWithStatus:200 message:deviceDesc];
    response.headers[@"Access-Control-Allow-Method"] = @"GET, POST, DELETE, OPTIONS";
    response.headers[@"Access-Control-Expose-Headers"] = @"Location";
    response.headers[@"Content-type"] = @"application/xml";
    response.headers[@"Application-URL"] = [NSString stringWithFormat:@"http://%@:9009/apps/", [self getIPWithNSHost]];
    
//    NSLog(@"response = %@", response);
    NSLog(@"deviceDesc = %@", deviceDesc);
    
    return response;
}

- (NSString *) escapeHtml:(NSString *)string
{
    return [[[[[[string stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;amp;"]
         stringByReplacingOccurrencesOfString: @"\"" withString: @"&quot;"]
        stringByReplacingOccurrencesOfString: @"'" withString: @"&#39;"]
       stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"]
      stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"]
     stringByReplacingOccurrencesOfString: @"’" withString: @"&#39;"];
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
    [NSApp activateIgnoringOtherApps:YES];// Bring to front
    
    //if (!preferencesController) {
		preferencesController = [[PreferencesController alloc] initWithWindowNibName:kPreferencesTitle];
	//}
    
	[preferencesController showWindow: self];
    [[preferencesController window] center];
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
    
    [_playerWindow toggleFullScreen:self];
    
}

- (IBAction)showHideAction:(id)sender
{
    if ([self playerWindow].isVisible) {
        [[self playerWindow] orderOut:nil];
        
        self.showHidePlayerMenuItem.title = @"Show Player";
        
    } else {
        [[self playerWindow] makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];// Bring to front
        
        self.showHidePlayerMenuItem.title = @"Hide Player";
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
    [self sendByebye];
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

- (void)appWillTerminateNotification:(NSNotification *)notify
{
    NSLog(@"-- appWillTerminate --");
    [self sendByebye];
}

#pragma mark- WebView Delegate

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    NSLog(@"webView:--- didFailLoadWithError --- : %@", error);
    
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame
                                                         *)frame
{
    if(frame == [sender mainFrame]) {
        NSLog(@"webView:--- didFinishLoadForFrame --- : %@", frame);
    }
}

//- (void)loopCheckInternet
//{
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        NSLog(@"----boooooo loopCheckInternet boooooo -------------------------------");
//        [self isInternetAvailable];
//    });
//}
//
//-(BOOL)isInternetAvailable
//{
//    NSLog(@"--- isInternetAvailable ---");
////    [self loopCheckInternet];
//    bool success = false;
//    const char *host_name = [@"screencloud.io"
//                             cStringUsingEncoding:NSASCIIStringEncoding];
//    
//    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL,
//                                                                                host_name);
//    SCNetworkReachabilityFlags flags;
//    success = SCNetworkReachabilityGetFlags(reachability, &flags);
//    bool isAvailable = success && (flags & kSCNetworkFlagsReachable) &&
//    !(flags & kSCNetworkFlagsConnectionRequired);
//    if (isAvailable) {
//        NSLog(@"Host is reachable: %d", flags);
//        
//        if(isInternetWentDown){
//            // reload the webview
//            isInternetWentDown = NO;
//            self.screenView.mainFrameURL = self.screenView.mainFrameURL;
//        }
//        return YES;
//    }else{
//        NSLog(@"Host is unreachable X X X");
//        isInternetWentDown = YES;
//        return NO;
//    }
//}

- (void)reachabilityChanged:(NSNotification *)notify
{
    Reachability *reach = (Reachability *)notify.object;
    
    NSLog(@"-- reachabilityChanged --- reach = %@", reach );
    if(reach.isReachable){
        NSLog(@"------ Internet OK -----");
        if(isInternetWentDown){
            // reload the webview
            isInternetWentDown = NO;
            
            NSString *lastOpenURL = [[NSUserDefaults standardUserDefaults] stringForKey:kLastOpenUrl];
            
            if( [lastOpenURL isEqualToString:@""] || lastOpenURL == (id)[NSNull null] || !lastOpenURL || lastOpenURL == nil ){
                lastOpenURL = kScreenCloudUrl;
            }
            NSURLRequest *request = [NSURLRequest requestWithURL:
                                     [NSURL URLWithString:lastOpenURL]];
            [self.screenView.mainFrame loadRequest:request];
            NSLog(@" try reload webview with url = %@", self.screenView.mainFrameURL );
            
        }
    }else{
        NSLog(@"------ Internet NOT NOT NOT OK -----");
        isInternetWentDown = YES;
    }
}


#pragma mark- JSDelegate

- (void)onScreenDisconnected
{
    NSLog(@"--- onScreenDisconnected ---");
    
    NSLog(@" kScreenCloudUrl = %@", kScreenCloudUrl);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:
                             [NSURL URLWithString:kScreenCloudUrl]];
    [self.screenView.mainFrame loadRequest:request];
}

- (void)onFocused
{
    NSLog(@"--- onFocused ---");
    
}

@end
