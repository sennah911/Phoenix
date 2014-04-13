//
//  PHCommandWindowController.h
//  Phoenix
//
//  Created by Hannes Remahl on 13/04/14.
//  Copyright (c) 2014 Steven. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol PHCommandWindowDelegate <NSObject>

- (void)commandStringSent:(NSString *)string;

@end

@interface PHCommandWindowController : NSWindowController

@property (weak) id<PHCommandWindowDelegate> delegate;

@end

