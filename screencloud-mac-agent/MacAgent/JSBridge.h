//
//  JSBridge.h
//  MacAgent
//
//  Created by Jirasak Saebang on 4/7/15.
//  Copyright (c) 2015 Codegent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JSBridgeDelegate <NSObject>

- (void)onScreenDisconnected;
- (void)onFocused;

@end

@interface JSBridge : NSObject

@property (nonatomic, weak) id <JSBridgeDelegate> delegate;

//+ (JSBridge *)jsBridge;
- (void)stop;

@end
