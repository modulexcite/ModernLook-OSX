//
//  MLHooverButton.m
//  ModernLookOSX
//
//  Created by András Gyetván on 17/03/15.
//  Copyright (c) 2015 DroidZONE. All rights reserved.
//

#import "MLHoverButton.h"
#import <QuartzCore/QuartzCore.h>

@interface MLHoverButton ()
@property (nonatomic, strong) NSTrackingArea* trackingArea;
@property (nonatomic) BOOL hoovered;
@property (nonatomic, strong) NSImage* tintedImage;
//@property (nonatomic, strong) CAShapeLayer* bgLayer;
//@property (nonatomic, strong) CALayer* imgLayer;
@end

@implementation MLHoverButton

- (instancetype) initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if(self) {
		[self commonInit];
	}
	return self;
}

- (instancetype) initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if(self) {
		[self commonInit];
	}
	return self;
}

- (void) viewDidEndLiveResize {
	[self createTrackingArea];
}

- (void) commonInit {
	self.wantsLayer = YES;
	[self createTrackingArea];
	self.hoovered = NO;
	self.hoveredForegroundColor = [NSColor whiteColor] ;//]selectedTextColor];
	self.hoveredBackgroundColor = [NSColor selectedTextBackgroundColor];
	self.backgroundColor = [NSColor clearColor];
	self.foregroundColor = [NSColor controlTextColor];
	self.circleBorder = 8;
	self.drawsOn = NO;
}

- (void) createTrackingArea {
	if(self.trackingArea) {
		[self removeTrackingArea:self.trackingArea];
	}
	NSRect circleRect = self.bounds;
	self.trackingArea = [[NSTrackingArea alloc] initWithRect:circleRect
		options: (NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp)
		owner:self userInfo:nil
	];
	[self addTrackingArea:self.trackingArea];
	
}

- (void)mouseEntered:(NSEvent *)theEvent {
	self.hoovered = YES;
	self.needsDisplay = YES;
}

- (void)mouseExited:(NSEvent *)theEvent {
	self.hoovered = NO;
	self.needsDisplay = YES;
}

- (void) setHoveredForegroundColor:(NSColor *)hooveredForegroundColor {
	_hoveredForegroundColor = hooveredForegroundColor;
	if(self.image) {
		self.tintedImage = [self imageTintedWithColor:self.hoveredForegroundColor];
	}
}

- (void) setImage:(NSImage *)image {
	[super setImage:image];
	if(image) {
		self.tintedImage = [self imageTintedWithColor:self.hoveredForegroundColor];
	} else {
		self.tintedImage = nil;
	}
}

- (NSImage *)imageTintedWithColor:(NSColor *)tint
{
	NSImage *image = [self.image copy];
	if (tint) {
		[image lockFocus];
		[tint set];
		NSRect imageRect = {NSZeroPoint, [image size]};
		NSRectFillUsingOperation(imageRect, NSCompositeSourceAtop);
		[image unlockFocus];
	}
	return image;
}

- (void) drawText:(NSString*) text inRect:(NSRect)rect withColor:(NSColor*) fc {
	NSMutableParagraphStyle * aParagraphStyle = [[NSMutableParagraphStyle alloc] init];
	[aParagraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
	[aParagraphStyle setAlignment:NSLeftTextAlignment];
	
	NSDictionary *attrs = @{NSParagraphStyleAttributeName: aParagraphStyle,NSFontAttributeName: self.font,NSForegroundColorAttributeName: fc};
	
	NSSize size = [self.title sizeWithAttributes:attrs];
	
	NSRect r = NSMakeRect(rect.origin.x,// + (bounds.size.width - size.width)/2.0,
						  rect.origin.y + ((rect.size.height - size.height)/2.0) - 2,
						  rect.size.width,
						  size.height);
	[self.title drawInRect:r withAttributes:attrs];
	
}

- (void)drawRect:(NSRect)dirtyRect {
	BOOL isOn = NO;
	[NSGraphicsContext saveGraphicsState];
	NSRect circleRect = self.bounds;
	
	if(circleRect.size.width > circleRect.size.height) {
//		CGFloat originalW = circleRect.size.width;
		circleRect.size.width = circleRect.size.height;
//		circleRect.origin.x = ((originalW - circleRect.size.width)/2.0);
	} else if(circleRect.size.width < circleRect.size.height) {
		CGFloat originalH = circleRect.size.height;
		circleRect.size.height = circleRect.size.width;
		circleRect.origin.y = ((originalH - circleRect.size.height)/2.0);
	}
	
	NSRect textRect = self.bounds;
	textRect.origin.x += circleRect.size.width + 4;
	textRect.size.width -= circleRect.size.width + 4;
	
	NSColor* bg = self.backgroundColor;
	NSColor* fc = nil;
	isOn = (self.hoovered && !self.isHighlighted);// || (self.state == NSOnState);
	if(self.drawsOn && (self.state == NSOnState)) {
		isOn = YES;
	}
	if(isOn) {
		bg = self.hoveredBackgroundColor;
		fc = self.hoveredForegroundColor;
	} else {
		bg = self.backgroundColor;
		fc = self.foregroundColor;
	}
	
	NSBezierPath* bgPath = [NSBezierPath bezierPathWithOvalInRect:circleRect];
	[bg set];
	[bgPath fill];
	
	if(self.image) {
		
		NSRect targetRect = NSInsetRect(circleRect, self.circleBorder, self.circleBorder);
		
		NSImage* i = nil;
		
		if(isOn) {
			i = self.tintedImage;
		} else {
			i = self.image;
		}
		
		NSRect imageRect = NSZeroRect;
		CGFloat w = i.size.width;
		CGFloat h = i.size.height;
		if(w > targetRect.size.width) w = targetRect.size.width;
		if(h > targetRect.size.height) h = targetRect.size.height;
		imageRect.size.width = w;
		imageRect.size.height = h;
		
		imageRect.origin.x = (circleRect.size.width - imageRect.size.width)/2.0f;
		imageRect.origin.y = (circleRect.size.height - imageRect.size.height)/2.0f;
		
		[i drawInRect:imageRect];
		[self drawText:self.title inRect:textRect withColor:fc];
		
	} else {
		NSString* sign = nil;
		NSString* text = nil;
		NSArray* components = [self.title componentsSeparatedByString:@"|"];
		if(components.count == 2) {
			sign = components[0];
			text = components[1];
		} else {
			sign = [self.title substringToIndex:1];
			text = [self.title substringFromIndex:1];
		}
		NSMutableParagraphStyle * aParagraphStyle = [[NSMutableParagraphStyle alloc] init];
		[aParagraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
		[aParagraphStyle setAlignment:NSCenterTextAlignment];
		
		NSDictionary *attrs = @{NSParagraphStyleAttributeName: aParagraphStyle,NSFontAttributeName: self.font,NSForegroundColorAttributeName: fc};
		
		NSSize size = [sign sizeWithAttributes:attrs];
		
		NSRect r = NSMakeRect(circleRect.origin.x,// + (bounds.size.width - size.width)/2.0,
							  circleRect.origin.y + ((circleRect.size.height - size.height)/2.0) - 2,
							  circleRect.size.width,
							  size.height);
		
		[sign drawInRect:r withAttributes:attrs];
		[self drawText:text inRect:textRect withColor:fc];
	}
	[NSGraphicsContext restoreGraphicsState];
}

@end
