//
//  AppDelegate.m
//  xmppMac
//
//  Created by YANG HONGBO on 2015-7-18.
//  Copyright (c) 2015年 YANG HONGBO. All rights reserved.
//

#import "AppDelegate.h"
#import "XMPPCenter.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

@interface AppDelegate ()
{
    XMPPCenter * _center;
}
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    _center = [[XMPPCenter alloc] init];
    [_center setupStream];
    [_center connect];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
