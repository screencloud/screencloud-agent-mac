//
//  StatusItemView.h
//  MacPlayer
//
//  Created by Nattapong kongmun on 5/8/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StatusItemView : NSControl<NSMenuDelegate>
{
    NSStatusItem *_statusItem;
    NSImage *_image;
    NSImage *_alternateImage;
    BOOL _isHighlighted;
}

@property (nonatomic, readonly) NSStatusItem *statusItem;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSImage *alternateImage;
@property (nonatomic, setter = setHighlighted:) BOOL isHighlighted;

- (id) initWithStatusItem: (NSStatusItem *) statusItem;

@end
