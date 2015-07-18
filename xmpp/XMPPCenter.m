#import "DDLog.h"

#import "XMPPCenter.h"
#import "XMPPFramework.h"
#import "DDXML.h"

#define TEST1

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface XMPPCenter () <XMPPStreamDelegate, XMPPPubSubDelegate>
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
    
    XMPPPubSub * _xmppPubSub;
    
    XMPPCompression * _xmppCompression;
    
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
#ifdef TEST1
    NSString * myJID = @"test1@iotpi.io";
#else
    NSString * myJID = @"test2@iotpi.io";
#endif
    
    [_xmppStream setMyJID:[XMPPJID jidWithString:myJID]];
    [_xmppStream setHostName:@"localhost"];
    [_xmppStream setHostPort:5222];
    
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
//    [_xmppvCardTempModule activate:_xmppStream];
//    [_xmppvCardAvatarModule activate:_xmppStream];
    [_xmppCapabilities activate:_xmppStream];
    
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    _allowSelfSignedCertificates = NO;
    _allowSSLHostNameMismatch = NO;
    
    _xmppPubSub = [[XMPPPubSub alloc] initWithServiceJID:_xmppStream.myJID];
    [_xmppPubSub activate:_xmppStream];
    [_xmppPubSub addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    _xmppCompression = [[XMPPCompression alloc] init];
    [_xmppCompression activate:_xmppStream];
}

- (BOOL)connect
{
    if (![_xmppStream isDisconnected]) {
        return YES;
    }
    
    NSError * error = nil;
    if (![_xmppStream connectWithTimeout:5 error:&error]) {
//        UIAlertView * a = [[UIAlertView alloc] initWithTitle:@"error"
//                                                   message:@""
//                                                  delegate:nil
//                                         cancelButtonTitle:@"Ok"
//                                         otherButtonTitles:nil, nil];
//        [a show];
        
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

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    DDLogInfo(@"XMPP disconnected: %@", error);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    DDLogInfo(@"xmppStreamDidConnect");
    NSError * error = nil;
    if (![_xmppStream authenticateWithPassword:@"test" error:&error]) {
        DDLogWarn(@"authentication failed:%@" , error);
    }
}

- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender
{
    DDLogInfo(@"XMPP connectDidTimeout");
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    DDLogInfo(@"XMPP didAuthenticate");
    [self goOnline];
    
#ifdef TEST1
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(sendMessageTimer:) userInfo:nil repeats:YES];
#endif
//    [_xmppPubSub subscribeToNode:@"1234567"];
}

- (void)sendMessageTimer:(NSTimer *)t
{
//    NSString * JID = @"test1@xingyun.cn";
//    XMPPMessage * m = [XMPPMessage messageWithType:@"chat" to:[XMPPJID jidWithString:JID]];
//    [m addBody:@"{\"messageId\":\"13\",\"toid\":\"100200886012\",\"content\":\"13\"}"];
//    [_xmppStream sendElement:m];
    
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"
     @"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"
     @"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"
     @"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"
     @"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"
     @"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"
     @"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"
     @"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"
     @"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"@"hello xmpp"];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"to" stringValue:@"test2@iotpi.io"];
    [message addChild:body];
    
    [_xmppStream sendElement:message];
    
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message
{
    DDLogInfo(@"sent message:%@", [message body]);
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
		
		NSString *body = [message body];
		NSString *displayName = [user displayName];
        DDLogVerbose(@"body:%@ displayName:%@", body, displayName);
    }
}

#pragma mark - PubSub
- (void)xmppPubSub:(XMPPPubSub *)sender didPublishToNode:(NSString *)node withResult:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"node:%@", node);
}

- (void)xmppPubSub:(XMPPPubSub *)sender didReceiveMessage:(XMPPMessage *)message
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSString *body = [message body];
    DDLogVerbose(@"body:%@", body);
}

- (void)xmppPubSub:(XMPPPubSub *)sender didSubscribeToNode:(NSString *)node withResult:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"node:%@", node);
//    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(sendPubSubMessageTimer:) userInfo:nil repeats:YES];
}

- (void)xmppPubSub:(XMPPPubSub *)sender didCreateNode:(NSString *)node withResult:(XMPPIQ *)iq
{
    [_xmppPubSub subscribeToNode:@"1234567"];
}

- (void)xmppPubSub:(XMPPPubSub *)sender didDeleteNode:(NSString *)node withResult:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"node:%@", node);
}

- (void)xmppPubSub:(XMPPPubSub *)sender didNotCreateNode:(NSString *)node withError:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"node:%@", node);
}

- (void)xmppPubSub:(XMPPPubSub *)sender didNotDeleteNode:(NSString *)node withError:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"node:%@", node);
}

- (void)sendPubSubMessageTimer:(NSTimer *)timer
{
    NSXMLElement * e = [NSXMLElement elementWithName:@"TEST" stringValue:@"xxxxxxxx"];
    [_xmppPubSub publishToNode:@"1234567" entry:e];
}

- (void)xmppPubSub:(XMPPPubSub *)sender didUnsubscribeFromNode:(NSString *)node withResult:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"node:%@", node);
}

- (void)xmppPubSub:(XMPPPubSub *)sender didNotSubscribeToNode:(NSString *)node withError:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"node:%@", node);
    
    [_xmppPubSub createNode:@"1234567"];
}
- (void)xmppPubSub:(XMPPPubSub *)sender didNotPublishToNode:(NSString *)node withError:(XMPPIQ *)iq
{
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    DDLogVerbose(@"node:%@", node);
}



@end
