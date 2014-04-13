//
//  SDAlertWindowController.m
//  Zephyros
//
//  Created by Steven on 4/14/13.
//  Copyright (c) 2013 Giant Robot Software. All rights reserved.
//

#import "PHAlerts.h"

#import <QuartzCore/QuartzCore.h>




@protocol PHAlertHoraMortisNostraeDelegate <NSObject>

- (void) oraPro:(id)nobis;

@end



@interface PHAlertWindowController : NSWindowController

- (void) show:(NSString*)oneLineMsg duration:(CGFloat)duration pushDownBy:(CGFloat)adjustment;
- (void) show:(NSString*)oneLineMsg duration:(CGFloat)duration centerPoint:(CGPoint)center;

@property (weak) id<PHAlertHoraMortisNostraeDelegate> delegate;

@end





@interface PHAlerts () <PHAlertHoraMortisNostraeDelegate>

@property NSMutableArray* visibleAlerts;

@end


@implementation PHAlerts

+ (PHAlerts*) sharedAlerts {
    static PHAlerts* sharedAlerts;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAlerts = [[PHAlerts alloc] init];
        sharedAlerts.alertDisappearDelay = 1.0;
        sharedAlerts.visibleAlerts = [NSMutableArray array];
    });
    return sharedAlerts;
}

- (void) show:(NSString*)oneLineMsg {
    [self show:oneLineMsg duration:self.alertDisappearDelay];
}

- (void) show:(NSString*)oneLineMsg duration:(CGFloat)duration {
    CGFloat absoluteTop;
    
    NSScreen* currentScreen = [NSScreen mainScreen];
    
    if ([self.visibleAlerts count] == 0) {
        CGRect screenRect = [currentScreen frame];
        absoluteTop = screenRect.size.height / 1.55; // pretty good spot
    }
    else {
        PHAlertWindowController* ctrl = [self.visibleAlerts lastObject];
        absoluteTop = NSMinY([[ctrl window] frame]) - 3.0;
    }
    
    if (absoluteTop <= 0)
        absoluteTop = NSMaxY([currentScreen visibleFrame]);
    
    PHAlertWindowController* alert = [[PHAlertWindowController alloc] init];
    alert.delegate = self;
    [alert show:oneLineMsg duration:duration pushDownBy:absoluteTop];
    [self.visibleAlerts addObject:alert];
}

- (void) show:(NSString*)oneLineMsg duration:(CGFloat)duration centerPoint:(CGPoint)centerPoint {
    NSScreen* currentScreen = [NSScreen mainScreen];
    
    CGRect screenRect = [currentScreen frame];
    
    //Invert y
    centerPoint.y = screenRect.size.height - centerPoint.y;
    
    PHAlertWindowController* alert = [[PHAlertWindowController alloc] init];
    alert.delegate = self;
    [alert show:oneLineMsg duration:duration centerPoint:centerPoint];
}

- (void) oraPro:(id)nobis {
    [self.visibleAlerts removeObject:nobis];
}

@end









@interface PHAlertWindowController ()

@property IBOutlet NSTextField* textField;
@property IBOutlet NSBox* box;

@end

@implementation PHAlertWindowController

- (NSString*) windowNibName {
    return @"AlertWindow";
}

- (void) windowDidLoad {
    self.window.styleMask = NSBorderlessWindowMask;
    self.window.backgroundColor = [NSColor clearColor];
    self.window.opaque = NO;
    self.window.level = NSFloatingWindowLevel;
    self.window.ignoresMouseEvents = YES;
    self.window.animationBehavior = ([PHAlerts sharedAlerts].alertAnimates ? NSWindowAnimationBehaviorAlertPanel : NSWindowAnimationBehaviorNone);
//    self.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary;
}

- (void) show:(NSString*)oneLineMsg duration:(CGFloat)duration pushDownBy:(CGFloat)adjustment {
    NSDisableScreenUpdates();
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.01];
    [[[self window] animator] setAlphaValue:1.0];
    [NSAnimationContext endGrouping];
    
    [self useTitleAndResize:[oneLineMsg description]];
    [self setFrameWithAdjustment:adjustment];
    [self showWindow:self];
    [self performSelector:@selector(fadeWindowOut) withObject:nil afterDelay:duration];
    
    NSEnableScreenUpdates();
}

- (void) show:(NSString*)oneLineMsg duration:(CGFloat)duration centerPoint:(CGPoint)center {
    NSDisableScreenUpdates();
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.01];
    [[[self window] animator] setAlphaValue:1.0];
    [NSAnimationContext endGrouping];
    
    [self useTitleAndResize:[oneLineMsg description]];
    [self setFrameWithCenterPoint:center];
    [self showWindow:self];
    [self performSelector:@selector(fadeWindowOut) withObject:nil afterDelay:duration];
    
    NSEnableScreenUpdates();
}

- (void)setFrameWithCenterPoint:(CGPoint)center {
    CGRect winRect = [[self window] frame];
    
    winRect.origin.x = center.x - (winRect.size.width / 2.0);
    winRect.origin.y = center.y - winRect.size.height;
    
    [self.window setFrame:winRect display:NO];
}

- (void) setFrameWithAdjustment:(CGFloat)pushDownBy {
    NSScreen* currentScreen = [NSScreen mainScreen];
    CGRect screenRect = [currentScreen frame];
    CGRect winRect = [[self window] frame];
    
    winRect.origin.x = (screenRect.size.width / 2.0) - (winRect.size.width / 2.0);
    winRect.origin.y = pushDownBy - winRect.size.height;
    
    [self.window setFrame:winRect display:NO];
}

- (void) fadeWindowOut {
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.15];
    [[[self window] animator] setAlphaValue:0.0];
    [NSAnimationContext endGrouping];
    
    [self performSelector:@selector(closeAndResetWindow) withObject:nil afterDelay:0.15];
}

- (void) closeAndResetWindow {
    [[self window] orderOut:nil];
    [[self window] setAlphaValue:1.0];
    
    [self.delegate oraPro:self];
}

- (void) useTitleAndResize:(NSString*)title {
    [self window]; // sigh; required in case nib hasnt loaded yet
    
    self.textField.stringValue = title;
    [self.textField sizeToFit];
    
	NSRect windowFrame = [[self window] frame];
	windowFrame.size.width = [self.textField frame].size.width + 32.0;
	windowFrame.size.height = [self.textField frame].size.height + 24.0;
	[[self window] setFrame:windowFrame display:YES];
}

@end
