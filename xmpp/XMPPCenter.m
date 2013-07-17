//
//  XMPPCenter.m
//  xmpp
//
//  Created by YANG HONGBO on 2013-7-15.
//  Copyright (c) 2013年 YANG HONGBO. All rights reserved.
//

#import "DDLog.h"

#import "XMPPCenter.h"
#import "XMPPStream.h"
#import "XMPPReconnect.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPRoster.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPvCardTemp.h"
#import "XMPPvCardAvatarModule.h"
#import "XMPPCapabilitiesCoreDataStorage.h"
#import "XMPPCapabilities.h"
#import "XMPPJID.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface XMPPCenter () <XMPPStreamDelegate>
{
    XMPPStream * _xmppStream;
    XMPPReconnect * _xmppReconnect;
    XMPPRoster * _xmppRoster;
    XMPPRosterCoreDataStorage *_xmppRosterStorage;
    id<XMPPvCardAvatarStorage,XMPPvCardTempModuleStorage> _xmppvCardStorage;
    XMPPvCardAvatarModule * _xmppvCardAvatarModule;
    XMPPvCardTempModule * _xmppvCardTempModule;
    XMPPCapabilities * _xmppCapabilities;
    id<XMPPCapabilitiesStorage> _xmppCapabilitiesStorage;
    
    BOOL _allowSelfSignedCertificates;
	BOOL _allowSSLHostNameMismatch;
}
@end

@implementation XMPPCenter

- (void)setupStream
{
    NSAssert(nil == _xmppStream, @"setup stream");
    
    _xmppStream = [[XMPPStream alloc] init];
    
#if !TARGET_IPHONE_SIMULATOR
//    _xmppStream.enableBackgroundingOnSocket = YES;
#endif
    
    _xmppReconnect = [[XMPPReconnect alloc] init];
    
    _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
    _xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:_xmppRosterStorage];
    _xmppRoster.autoFetchRoster = YES;
    _xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    
    _xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
    _xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardStorage];
    _xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardTempModule];
    _xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
    _xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:_xmppCapabilitiesStorage];
    _xmppCapabilities.autoFetchHashedCapabilities = YES;
    _xmppCapabilities.autoFetchNonHashedCapabilities = NO;
    
    [_xmppReconnect activate:_xmppStream];
    [_xmppRoster activate:_xmppStream];
    [_xmppvCardTempModule activate:_xmppStream];
    [_xmppvCardAvatarModule activate:_xmppStream];
    [_xmppCapabilities activate:_xmppStream];
    
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    _allowSelfSignedCertificates = NO;
    _allowSSLHostNameMismatch = NO;
}

- (BOOL)connect
{
    if (![_xmppStream isDisconnected]) {
        return YES;
    }
    NSString * myJID = @"admin@localhost";
    [_xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
    
    NSError * error = nil;
    if (![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
        UIAlertView * a = [[UIAlertView alloc] initWithTitle:@"error"
                                                   message:@""
                                                  delegate:nil
                                         cancelButtonTitle:@"Ok"
                                         otherButtonTitles:nil, nil];
        [a show];
        
        DDLogError(@"Error connecting: %@", error);
        return NO;
    }
    return YES;
}

- (void)sendElement:(NSXMLElement *)element
{
    [_xmppStream sendElement:element];
}

- (void)goOnline
{
    XMPPPresence *presence = [XMPPPresence presence];
    [_xmppStream sendElement:presence];
}

- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [_xmppStream sendElement:presence];
}

- (void)disconnect
{
    [self goOffline];
    [_xmppStream disconnect];
}

#pragma mark - XMPPStream Delegate
- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    DDLogInfo(@"XMPP socket did connect");
}
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSError * error = nil;
    if (![_xmppStream authenticateWithPassword:@"admin" error:&error]) {
        DDLogWarn(@"authentication failed:%@" , error);
    }
}
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    DDLogInfo(@"XMPP didAuthenticate");
    [self goOnline];
}
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    DDLogInfo(@"XMPP didNotAuthenticate");
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    if ([message isChatMessageWithBody]) {
        XMPPUserCoreDataStorageObject *user = [_xmppRosterStorage userForJID:[message from]
		                                                         xmppStream:_xmppStream
		                                               managedObjectContext:[_xmppRosterStorage mainThreadManagedObjectContext]];
		
		NSString *body = [[message elementForName:@"body"] stringValue];
		NSString *displayName = [user displayName];
        DDLogVerbose(@"body:%@ displayName:%@", body, displayName);
    }
}
@end
