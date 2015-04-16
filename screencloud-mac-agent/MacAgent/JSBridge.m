//
//  JSBridge.m
//  MacAgent
//
//  Created by Jirasak Saebang on 4/7/15.
//  Copyright (c) 2015 Codegent. All rights reserved.
//

#import "JSBridge.h"

@implementation JSBridge

- (void)stop
{
    NSLog(@"JSBridge: --- stop ----");
    [self.delegate onScreenDisconnected];
}

- (void)focus
{
    NSLog(@"JSBridge: --- focus ----");
    [self.delegate onFocused];
}

//+ (NSString *) webScriptNameForSelector:(SEL)sel
//{
//    NSString *name;
//    if (sel == @selector(stop))
//        name = @"stop";
//    
//    return name;
//}
//
//+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
//{
//    if (aSelector == @selector(stop)) return NO;
//    return YES;
//}

#pragma mark- JAVASCRIPT EXPOSE

+ (NSString *) webScriptNameForSelector:(SEL)selector
{
    NSLog(@"-- webScriptNameForSelector ---");
    NSString *name;
    
    if( selector == @selector(stop))
        name = @"stop";
    
    return name;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    NSLog(@"-- isSelectorExcludedFromWebScript --");
    
    if (aSelector == @selector(stop:)){
        NSLog(@"......... NO for stop:");
        return NO;
    }else if (aSelector == @selector(stop)){
        NSLog(@"......... NO for stop");
        return NO;
    }else if (aSelector == @selector(focus)){
        NSLog(@"......... NO for focus");
        return NO;
    }
    
    return YES;
}


@end
