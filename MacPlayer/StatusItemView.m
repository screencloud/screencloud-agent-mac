//
//  StatusItemView.m
//  MacPlayer
//
//  Created by Nattapong kongmun on 5/8/2557 BE.
//  Copyright (c) 2557 Codegent. All rights reserved.
//

#import "StatusItemView.h"

@implementation StatusItemView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id) initWithStatusItem: (NSStatusItem *) statusItem {
	CGFloat itemWidth = [statusItem length];
	CGFloat itemHeight = [[NSStatusBar systemStatusBar] thickness];
	NSRect itemRect = NSMakeRect(0.0, 0.0, itemWidth, itemHeight);
	self = [self initWithFrame:itemRect];
	if (self != nil)
    {
		_statusItem = statusItem;
		[_statusItem setView: self];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [_statusItem drawStatusBarBackgroundInRect:dirtyRect withHighlight:_isHighlighted];
    
    NSImage *icon = _isHighlighted ? _alternateImage : _image;
    NSSize iconSize = [icon size];

    NSRect bounds = [self bounds];
	
    CGFloat iconX = roundf((NSWidth(bounds) - iconSize.width) / 2);
    CGFloat iconY = roundf((NSHeight(bounds) - iconSize.height) / 2);
    NSPoint iconPoint = NSMakePoint(iconX, iconY);
    [_image drawAtPoint:iconPoint fromRect:bounds operation:NSCompositeSourceOver fraction:1.0];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSLog(@"mouseDown");
    
    NSMenu *menu = [super menu];
    [_statusItem popUpStatusItemMenu:menu];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSLog(@"rightMouseDown");
}

- (void)setHighlighted:(BOOL)newFlag
{
    if (_isHighlighted == newFlag) return;
    _isHighlighted = newFlag;
    [self setNeedsDisplay:YES];
}

- (void)setImage:(NSImage *)newImage
{
	_image = newImage;
    [self setNeedsDisplay: YES];
}

- (void)setAlternateImage:(NSImage *)newImage
{
    _alternateImage = newImage;
    if (_isHighlighted)
        [self setNeedsDisplay:YES];
}

@end
