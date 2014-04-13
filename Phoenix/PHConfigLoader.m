//
//  PHConfigLoader.m
//  Phoenix
//
//  Created by Steven on 12/2/13.
//  Copyright (c) 2013 Steven. All rights reserved.
//

#import "PHConfigLoader.h"

#import <JavaScriptCore/JavaScriptCore.h>

#import "PHHotKey.h"
#import "PHAlerts.h"
#import "PHCommandWindowController.h"
#import "PHPathWatcher.h"

#import "PHMousePosition.h"

#import "PHWindow.h"
#import "PHApp.h"
#import "NSScreen+PHExtension.h"

@interface PHConfigLoader () <PHCommandWindowDelegate>

@property NSMutableArray* hotkeys;
@property PHPathWatcher* watcher;
@property PHCommandWindowController *commandWindowController;
@property JSContext* ctx;

@end


static NSString* PHConfigPath = @"~/.phoenix.js";


@implementation PHConfigLoader

- (id) init {
    if (self = [super init]) {
        self.watcher = [PHPathWatcher watcherFor:PHConfigPath handler:^{
            [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(reload) object:nil];
            [self performSelector:@selector(reload) withObject:nil afterDelay:0.25];
        }];
    }
    return self;
}

- (void) reload {
    NSString* filename = [PHConfigPath stringByStandardizingPath];
    NSString* config = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:NULL];
    
    if (!config) {
        [[NSFileManager defaultManager] createFileAtPath:filename
                                                contents:[@"" dataUsingEncoding:NSUTF8StringEncoding]
                                              attributes:nil];
        [[PHAlerts sharedAlerts] show:@"I just created ~/.phoenix.js for you :)" duration:7.0];
        return;
    }
    
    [self.hotkeys makeObjectsPerformSelector:@selector(disable)];
    self.hotkeys = [NSMutableArray array];
    
    self.ctx = [[JSContext alloc] initWithVirtualMachine:[[JSVirtualMachine alloc] init]];
    
    self.ctx.exceptionHandler = ^(JSContext* ctx, JSValue* val) {
        [[PHAlerts sharedAlerts] show:[NSString stringWithFormat:@"[js exception] %@", val] duration:3.0];
    };
    
    NSURL* _jsURL = [[NSBundle mainBundle] URLForResource:@"underscore-min" withExtension:@"js"];
    NSString* _js = [NSString stringWithContentsOfURL:_jsURL encoding:NSUTF8StringEncoding error:NULL];
    [self.ctx evaluateScript:_js];
    [self setupAPI:self.ctx];
    
    [self.ctx evaluateScript:config];
    [[PHAlerts sharedAlerts] show:@"Phoenix Config Loaded" duration:1.0];
}

- (void)commandStringSent:(NSString *)string {
    NSLog(@"%@", string);
    [self.ctx evaluateScript:string];
}

- (void) setupAPI:(JSContext*)ctx {
    JSValue* api = [JSValue valueWithNewObjectInContext:ctx];
    ctx[@"api"] = api;
    
    api[@"reload"] = ^(NSString* str) {
        [self reload];
    };
    
    api[@"launch"] = ^(NSString* appName) {
        [[NSWorkspace sharedWorkspace] launchApplication:appName];
    };
    
    api[@"alert"] = ^(NSString* str, CGFloat duration) {
        if (isnan(duration))
            duration = 2.0;
        
        [[PHAlerts sharedAlerts] show:str duration:duration];
    };
    
    api[@"positionedAlert"] = ^(NSString* str, CGFloat duration, CGFloat x, CGFloat y) {
        [[PHAlerts sharedAlerts] show:str duration:duration centerPoint:CGPointMake(x, y)];
    };

    
    api[@"bind"] = ^(NSString* key, NSArray* mods, JSValue* handler) {
        PHHotKey* hotkey = [PHHotKey withKey:key mods:mods handler:^BOOL{
            return [[handler callWithArguments:@[]] toBool];
        }];
        [self.hotkeys addObject:hotkey];
        [hotkey enable];
        return hotkey;
    };

    api[@"runCommand"] = ^(NSString* path, NSArray *args) {
        NSTask *task = [[NSTask alloc] init];

        [task setArguments:args];
        [task setLaunchPath:path];
        [task launch];

        while([task isRunning]);
    };
    
    api[@"setTint"] = ^(NSArray *red, NSArray *green, NSArray *blue) {
        CGGammaValue cred[red.count];
        for (int i = 0; i < red.count; ++i) {
            cred[i] = [[red objectAtIndex:i] floatValue];
        }
        CGGammaValue cgreen[green.count];
        for (int i = 0; i < green.count; ++i) {
            cgreen[i] = [[green objectAtIndex:i] floatValue];
        }
        CGGammaValue cblue[blue.count];
        for (int i = 0; i < blue.count; ++i) {
            cblue[i] = [[blue objectAtIndex:i] floatValue];
        }
        CGSetDisplayTransferByTable(CGMainDisplayID(), (int)sizeof(cred) / sizeof(cred[0]), cred, cgreen, cblue);
    };
    
    api[@"showCommandLine"] = ^ (BOOL show){
        if (!self.commandWindowController) {
            self.commandWindowController = [[PHCommandWindowController alloc] initWithWindowNibName:@"PHCommandWindowController"];
        }
        if (show) {
            self.commandWindowController.delegate = self;
            [self.commandWindowController showWindow:self.commandWindowController];
        } else {
            [self.commandWindowController close];
        }
    };
    
    api[@"overlay"] = ^(BOOL show, NSString *imagePath) {
        if (show) {
            NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
            
            int windowLevel = CGShieldingWindowLevel();
            NSRect windowRect = [[NSScreen mainScreen] frameIncludingDockAndMenu];
            [image setSize:NSSizeFromCGSize(CGSizeMake(windowRect.size.width, windowRect.size.height - 20))];

            self.overlayWindow = [[NSWindow alloc] initWithContentRect:windowRect
                                                              styleMask:NSBorderlessWindowMask
                                                                backing:NSBackingStoreBuffered
                                                                  defer:NO
                                                                 screen:[NSScreen mainScreen]];
        
            [self.overlayWindow setReleasedWhenClosed:YES];
            [self.overlayWindow setLevel:windowLevel];
            [self.overlayWindow setBackgroundColor:[NSColor colorWithPatternImage:image]];

            [self.overlayWindow setOpaque:NO];
            [self.overlayWindow setIgnoresMouseEvents:YES];
            [self.overlayWindow makeKeyAndOrderFront:nil];
        } else {
            [self.overlayWindow orderOut:nil];
        }
    };

    
    ctx[@"Window"] = [PHWindow self];
    ctx[@"App"] = [PHApp self];
    ctx[@"Screen"] = [NSScreen self];
    ctx[@"MousePosition"] = [PHMousePosition self];
}

@end
