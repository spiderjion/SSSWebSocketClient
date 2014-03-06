//
//  AZSocketIO.m
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright 2012 Patrick Shields
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "AZSocketIO.h"
#import "AFHTTPClient.h"
#import "AZSocketIOTransport.h"
#import "AZWebsocketTransport.h"
#import "AZxhrTransport.h"
#import "AZSocketIOPacket.h"

#define PROTOCOL_VERSION @"1"

NSString * const AZSocketIODefaultNamespace = @"";

@interface AZSocketIO ()
@property(nonatomic, strong, readwrite)NSString *host;
@property(nonatomic, strong, readwrite)NSString *port;
@property(nonatomic, assign, readwrite)BOOL secureConnections;
@property(nonatomic, copy, readwrite)NSString *endpoint;

@property(nonatomic, strong)NSOperationQueue *queue;

@property(nonatomic, strong)ConnectedBlock connectionBlock;

@property(nonatomic, strong)AFHTTPClient *httpClient;
@property(nonatomic, strong)NSDictionary *transportMap;

@property(nonatomic, strong)NSMutableDictionary *ackCallbacks;
@property(nonatomic, assign)NSUInteger ackCount;
@property(nonatomic, strong)NSTimer *heartbeatTimer;
@property(nonatomic, assign)NSUInteger connectionAttempts;

@property(nonatomic, strong)NSMutableDictionary *specificEventBlocks;

@property(nonatomic, strong)NSArray *availableTransports;
@property(nonatomic, strong)NSString *sessionId;
@property(nonatomic, assign)NSInteger heartbeatInterval;
@property(nonatomic, assign)NSInteger disconnectInterval;

@property(nonatomic, assign)NSTimeInterval currentReconnectDelay;

@property(nonatomic, assign, readwrite)AZSocketIOState state;
@end

@implementation AZSocketIO

- (id)initWithHost:(NSString *)host andPort:(NSString *)port secure:(BOOL)secureConnections
{
    return [self initWithHost:host
                      andPort:port
                       secure:secureConnections
                withNamespace:AZSocketIODefaultNamespace];
}

- (id)initWithHost:(NSString *)host andPort:(NSString *)port secure:(BOOL)secureConnections withNamespace:(NSString *)endpoint
{
    NSParameterAssert(host);
    NSParameterAssert(port);
    NSParameterAssert(endpoint);
    
    self = [super init];
    if (self) {
        self.host = host;
        self.port = port;
        self.secureConnections = secureConnections;
        self.endpoint = endpoint;
        
        NSString *protocolString = self.secureConnections ? @"https://" : @"http://";
        NSString *urlString = [NSString stringWithFormat:@"%@%@:%@", protocolString,
                               self.host, self.port];
        
        self.httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
        self.ackCallbacks = [NSMutableDictionary dictionary];
        self.ackCount = 0;
        self.specificEventBlocks = [NSMutableDictionary new];
        
        self.queue = [[NSOperationQueue alloc] init];
        [self.queue setSuspended:YES];
        
        self.transports = [NSMutableSet setWithObjects:@"websocket", @"xhr-polling", nil];
        self.transportMap = @{ @"websocket" : [AZWebsocketTransport class], @"xhr-polling" : [AZxhrTransport class] };
        
        self.reconnect = YES;
        self.reconnectionDelay = .5;
        self.reconnectionLimit = MAXFLOAT;
        self.maxReconnectionAttempts = 10;
        self.state = AZSocketIOStateDisconnected;
    }
    return self;
}

- (void)setReconnectionDelay:(NSTimeInterval)reconnectionDelay
{
    _reconnectionDelay = reconnectionDelay;
    _currentReconnectDelay = reconnectionDelay;
}

#pragma mark connection management
- (void)connectWithSuccess:(ConnectedBlock)success andFailure:(ErrorBlock)failure
{
    self.state = AZSocketIOStateConnecting;
    self.connectionBlock = success;
    self.errorBlock = failure;
    NSString *urlString = [NSString stringWithFormat:@"socket.io/%@", PROTOCOL_VERSION];
    [self.httpClient getPath:urlString
                  parameters:nil
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         NSString *response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                         NSArray *msg = [response componentsSeparatedByString:@":"];
                         if ([msg count] < 4) {
                             NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                             [errorDetail setValue:@"Server handshake message could not be decoded" forKey:NSLocalizedDescriptionKey];
                             failure([NSError errorWithDomain:AZDOMAIN code:AZSocketIOErrorConnection userInfo:errorDetail]);
                             return;
                         }
                         self.sessionId = [msg objectAtIndex:0];
                         self.heartbeatInterval = [[msg objectAtIndex:1] intValue];
                         self.disconnectInterval = [[msg objectAtIndex:2] intValue];
                         self.availableTransports = [[msg objectAtIndex:3] componentsSeparatedByString:@","];
                         self.currentReconnectDelay = self.reconnectionDelay;
                         [self connect];
                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         self.state = AZSocketIOStateDisconnected;
                         if (![self reconnect]) {
                             failure(error);
                         }
                     }];
}

- (void)connect
{
    self.connectionAttempts++;
    for (NSString *transportType in self.availableTransports) {
        if ([self.transports containsObject:transportType]) {
            [self connectViaTransport:transportType];
            return;
        }
    }
    
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"None of the available transports are recognized by this server" forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:AZDOMAIN code:AZSocketIOErrorConnection userInfo:errorDetail];
    self.errorBlock(error);
}

- (void)connectViaTransport:(NSString*)transportType 
{
    if ([transportType isEqualToString:@"websocket"]) {
        self.transport = [[AZWebsocketTransport alloc] initWithDelegate:self secureConnections:self.secureConnections];
    } else if ([transportType isEqualToString:@"xhr-polling"]) {
        self.transport = [[AZxhrTransport alloc] initWithDelegate:self secureConnections:self.secureConnections];
    } else {
        NSLog(@"Transport not implemented");
    }
    [self.transport connect];
}

- (void)disconnect
{
    [self clearHeartbeatTimeout];
    self.state = AZSocketIOStateDisconnecting;
    [self.transport disconnect];
}

- (BOOL)reconnect
{
    if (self.shouldReconnect && self.state == AZSocketIOStateDisconnected) {
        NSString *transportName = [[self.transportMap allKeysForObject:[self.transport class]] lastObject];
        self.availableTransports = [self.availableTransports filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return ![transportName isEqualToString:evaluatedObject] && [self.transports containsObject:evaluatedObject];
        }]];
        if ([self.availableTransports count] > 0) {
            [self connect];
            return YES;
        } else if (self.connectionAttempts < self.maxReconnectionAttempts) {
            if (self.currentReconnectDelay < self.reconnectionLimit) {
                NSLog(@"Reconnecting after %f", self.currentReconnectDelay);
                NSInvocation *connectionCallable = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(connectWithSuccess:andFailure:)]];
                connectionCallable.target = self;
                connectionCallable.selector = @selector(connectWithSuccess:andFailure:);
                [connectionCallable setArgument:&_connectionBlock atIndex:2];
                [connectionCallable setArgument:&_errorBlock atIndex:3];
                [NSTimer scheduledTimerWithTimeInterval:self.currentReconnectDelay invocation:connectionCallable repeats:NO];
                
                self.currentReconnectDelay *= 2;
                return YES;
            }
        }
    }

    return NO;
}

#pragma mark data sending
- (BOOL)send:(id)data error:(NSError *__autoreleasing *)error ack:(ACKCallback)callback
{
    return [self send:data error:error ack:callback argCount:0];
}

- (BOOL)send:(id)data error:(NSError *__autoreleasing *)error ackWithArgs:(ACKCallbackWithArgs)callback
{
    return [self send:data error:error ack:callback argCount:1];
}

- (BOOL)send:(id)data error:(NSError *__autoreleasing *)error ack:(id)callback argCount:(NSUInteger)argCount
{
    AZSocketIOPacket *packet = [[AZSocketIOPacket alloc] init];
    
    if (![data isKindOfClass:[NSString class]]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:error];
        if (jsonData == nil) {
            return NO;
        }
        
        packet.data = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        packet.type = JSON_MESSAGE;
    } else {
        packet.data = data;
        packet.type = MESSAGE;
    }
    
    if (callback != NULL) {
        packet.Id = [NSString stringWithFormat:@"%d", self.ackCount++];
        [self.ackCallbacks setObject:callback forKey:packet.Id];
        if (argCount > 0) {
            packet.Id = [packet.Id stringByAppendingString:@"+"];
        }
    }
    
    return [self sendPacket:packet error:error];
}

- (BOOL)send:(id)data error:(NSError *__autoreleasing *)error
{        
    return [self send:data error:error ack:NULL];
}

- (void)sendExplicitConnectMessage
{
    AZSocketIOPacket *connectPacket = [[AZSocketIOPacket alloc] init];
    connectPacket.type = CONNECT;
    connectPacket.endpoint = self.endpoint;
    [self.transport send:[connectPacket encode]];
}

- (BOOL)emit:(NSString *)name args:(id)args error:(NSError *__autoreleasing *)error ack:(ACKCallback)callback
{
    return [self emit:name args:args error:error ack:callback argCount:0];
}

- (BOOL)emit:(NSString *)name args:(id)args error:(NSError *__autoreleasing *)error ackWithArgs:(ACKCallbackWithArgs)callback
{
    return [self emit:name args:args error:error ack:callback argCount:1];
}

- (BOOL)emit:(NSString *)name args:(id)args error:(NSError *__autoreleasing *)error ack:(id)callback argCount:(NSUInteger)argCount
{
    AZSocketIOPacket *packet = [[AZSocketIOPacket alloc] init];
    packet.type = EVENT;
    
    NSDictionary *data = nil;
    
    if (args) {
        data = @{ @"name" : name, @"args" : args};
    } else {
        data = @{ @"name" : name};
    }
    
    if (![NSJSONSerialization isValidJSONObject:data]) {
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"The provided args can't be converted to JSON"};
            *error = [NSError errorWithDomain:AZDOMAIN code:AZSocketIOErrorArgs userInfo:userInfo];
        }
        return NO;
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:error];
    if (jsonData == nil) {
        return NO;
    }
    
    packet.data = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    packet.Id = [NSString stringWithFormat:@"%d", self.ackCount++];
    
    if (callback != NULL) {
        [self.ackCallbacks setObject:callback forKey:packet.Id];
        if (argCount > 0) {
            packet.Id = [packet.Id stringByAppendingString:@"+"];
        }
    }
    
    return [self sendPacket:packet error:error];
}

- (BOOL)emit:(NSString *)name args:(id)args error:(NSError * __autoreleasing *)error
{
    return [self emit:name args:args error:error ack:NULL];
}

- (BOOL)sendPacket:(AZSocketIOPacket *)packet error:(NSError * __autoreleasing *)error
{
    packet.endpoint = self.endpoint;
    [self.queue addOperation:[NSBlockOperation blockOperationWithBlock:^{
        [self.transport send:[packet encode]];
    }]];
    return !self.queue.isSuspended;
}

#pragma mark event callback registration

- (void)addCallbackForEventName:(NSString *)name callback:(EventRecievedBlock)block
{
    NSMutableArray *callbacks = [self.specificEventBlocks objectForKey:name];
    if (callbacks == nil) {
        callbacks = [NSMutableArray array];
        [self.specificEventBlocks setValue:callbacks forKey:name];
    }
    [callbacks addObject:block];
}

- (BOOL)removeCallbackForEvent:(NSString *)name callback:(EventRecievedBlock)block
{
    NSMutableArray *callbacks = [self.specificEventBlocks objectForKey:name];
    if (callbacks != nil) {
        NSInteger count = [callbacks count];
        [callbacks removeObject:block];
        if ([callbacks count] == 0) {
            [self.specificEventBlocks removeObjectForKey:name];
            return YES;
        }
        return count != [callbacks count];
    }
    return NO;
}

- (NSInteger)removeCallbacksForEvent:(NSString *)name
{
    NSMutableArray *callbacks = [self.specificEventBlocks objectForKey:name];
    [self.specificEventBlocks removeObjectForKey:name];
    return [callbacks count];
}

- (NSArray *)callbacksForEvent:(NSString *)eventName
{
    return [[self.specificEventBlocks objectForKey:eventName] copy];
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [self.httpClient setDefaultHeader:field value:value];
}

#pragma mark heartbeat

- (void)clearHeartbeatTimeout
{
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer = nil;
}

- (void)startHeartbeatTimeout
{
    [self clearHeartbeatTimeout];
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:self.heartbeatInterval
                                                           target:self
                                                         selector:@selector(heartbeatTimeout) 
                                                         userInfo:nil
                                                          repeats:NO];
}
- (void)heartbeatTimeout
{
    [self disconnect];
    [self reconnect];
}


#pragma mark AZSocketIOTransportDelegate

- (void)didReceiveMessage:(NSString *)message
{
    [self startHeartbeatTimeout];
    AZSocketIOPacket *packet = [[AZSocketIOPacket alloc] initWithString:message];
    AZSocketIOACKMessage *ackMessage; ACKCallback callback;
    switch (packet.type) {
        case DISCONNECT:
            [self disconnect];
            break;
        case CONNECT:
        {
            if (self.endpoint) {
                NSString *receivedEndpoint = packet.endpoint;
                if (![receivedEndpoint isEqualToString:self.endpoint]) {
                    [self sendExplicitConnectMessage];
                    return;
                }
            }
            
            self.connectionBlock();
            [self.queue setSuspended:NO];
            break;
        }
        case HEARTBEAT:
            [self.transport send:message];
            break;
        case MESSAGE:
            if (self.messageRecievedBlock) {
                self.messageRecievedBlock(packet.data);
            }
            break;
        case JSON_MESSAGE:
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                id outData = [NSJSONSerialization JSONObjectWithData:[packet.data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                [self performSelectorOnMainThread:@selector(didParseJSONMessage:)
                                       withObject:outData waitUntilDone:NO];
            });
            break;
        }
        case EVENT:
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                id outData = [NSJSONSerialization JSONObjectWithData:[packet.data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                [self performSelectorOnMainThread:@selector(didParseJSONEvent:)
                                       withObject:outData waitUntilDone:NO];
            });
            break;
        }
        case ACK:
            ackMessage = [[AZSocketIOACKMessage alloc] initWithPacket:packet];
            callback = [self.ackCallbacks objectForKey:ackMessage.messageId];
            if (callback != NULL) {
                if (ackMessage.args.count > 0) {
                    callback(ackMessage.args);
                } else {
                    callback();
                }
            }
            [self.ackCallbacks removeObjectForKey:ackMessage.messageId];
            break;
        case ERROR:
            [self disconnect];
            if (![self reconnect]) {
                if (self.errorBlock) {
                    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                    [errorDetail setValue:packet.data forKey:NSLocalizedDescriptionKey];
                    NSError *error = [NSError errorWithDomain:AZDOMAIN code:AZSocketIOErrorConnection userInfo:errorDetail];
                    self.errorBlock(error);
                }
            }
            break;
        default:
            break;
    }
}

- (void)didOpen
{
    self.state = AZSocketIOStateConnected;
    self.connectionAttempts = 0;
}

- (void)didClose
{
    self.state = AZSocketIOStateDisconnected;
    [self.queue setSuspended:YES];
    if (self.disconnectedBlock) {
        self.disconnectedBlock();
    }
}

- (void)didFailWithError:(NSError *)error
{
    self.state = AZSocketIOStateDisconnected;
    [self.queue setSuspended:YES];
    if (![self reconnect] && self.errorBlock) {
        self.errorBlock(error);
    }
}

#pragma mark - Parse response

- (void)didParseJSONMessage:(id)outData
{
    if (self.messageRecievedBlock) {
        self.messageRecievedBlock(outData);
    }
}

- (void)didParseJSONEvent:(id)outData
{
    NSArray *callbackList = [self.specificEventBlocks objectForKey:[outData objectForKey:@"name"]];
    if (callbackList != nil) {
        for (EventRecievedBlock block in callbackList) {
            block([outData objectForKey:@"name"], [outData objectForKey:@"args"]);
        }
    } else {
        if (self.eventRecievedBlock) {
            self.eventRecievedBlock([outData objectForKey:@"name"], [outData objectForKey:@"args"]);
        }
    }
}

@end
