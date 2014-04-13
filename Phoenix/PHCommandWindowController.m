//
//  PHCommandWindowController.m
//  Phoenix
//
//  Created by Hannes Remahl on 13/04/14.
//  Copyright (c) 2014 Steven. All rights reserved.
//

#import "PHCommandWindowController.h"

@interface PHCommandWindowController ()

@end

@implementation PHCommandWindowController

- (NSString*) windowNibName {
    return @"PHCommandWindowController";
}

- (void) windowDidLoad {
    self.window.styleMask = NSBorderlessWindowMask;
    self.window.backgroundColor = [NSColor clearColor];
    self.window.opaque = NO;
    self.window.level = NSFloatingWindowLevel;
    self.window.ignoresMouseEvents = NO;
    
    NSScreen *screen = [NSScreen mainScreen];
    
    [self.window setFrame:CGRectMake(0, 0, screen.frame.size.width, self.window.frame.size.height) display:NO];
    [self.window makeKeyAndOrderFront:nil];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (IBAction)enterPressed:(NSTextField *)sender {
    NSLog(@"%@", sender.stringValue);
    [self.delegate commandStringSent:sender.stringValue];
    sender.stringValue = @"";
}

@end

@interface PHCommandWindow : NSWindow

@end

@implementation PHCommandWindow

- (BOOL)canBecomeKeyWindow {
    return YES;
}

@end