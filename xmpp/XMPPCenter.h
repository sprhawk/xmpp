//
//  XMPPCenter.h
//  xmpp
//
//  Created by YANG HONGBO on 2013-7-15.
//  Copyright (c) 2013年 YANG HONGBO. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XMPPCenter : NSObject
- (void)setupStream;
- (BOOL)connect;
@end
