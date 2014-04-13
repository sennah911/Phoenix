//
//  SDAlertWindowController.h
//  Zephyros
//
//  Created by Steven on 4/14/13.
//  Copyright (c) 2013 Giant Robot Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PHAlerts : NSObject

+ (PHAlerts*) sharedAlerts;

- (void) show:(NSString*)oneLineMsg;
- (void) show:(NSString*)oneLineMsg duration:(CGFloat)duration;
- (void) show:(NSString*)oneLineMsg duration:(CGFloat)duration centerPoint:(CGPoint)center;

@property CGFloat alertDisappearDelay;
@property BOOL alertAnimates;

@end
