//
//  SocketBLController.m
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-7.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import "SocketBLController.h"
#import "SocketConfig.h"
#import "AZSocketIO.h"

@interface SocketBLController ()

/**
 *  <#Description#>
 */
@property (nonatomic, strong) AZSocketIO *socket;

@end

@implementation SocketBLController

- (AZSocketIO *)socket
{
    if (!_socket)
    {
        _socket = [[AZSocketIO alloc] initWithHost:SocketServerHost
                                           andPort:SocketServerPort
                                            secure:NO];
        
        __block SocketBLController *blcontroller = self;
        
        [_socket setMessageReceivedBlock:^(id data) {
            NSLog(@"%@",data);
            [blcontroller messageRecieved:data];
        }];
        
        [_socket setEventReceivedBlock:^(NSString *eventName, id data) {
            NSLog(@"%@ : %@", eventName, data);
            [blcontroller eventRecieved:eventName data:data];
        }];
        
        [_socket setDisconnectedBlock:^{
            NSLog(@"disconnect!");
        }];
        
        [_socket setErrorBlock:^(NSError *error) {
            NSLog(@"error : %@",error);
        }];
    }
    return _socket;
}

#pragma mark - Public methods

- (void)startConnect:(void (^)(void))complete
{
    [self.socket connectWithSuccess:^{
        NSLog(@"Success connect!");
        dispatch_async(dispatch_get_main_queue(), ^{
            complete();
        });
    } andFailure:^(NSError *error) {
        NSLog(@"Fail to connect : %@",error);
    }];
}

- (void)endConnect
{
    [self.socket disconnect];
}

- (void)sendMessage:(Dialogue *)message data:(id)data complete:(void (^)())complete failure:(void (^)(NSError *))failure
{
    
}

#pragma mark - Private methods

- (void)eventRecieved:(NSString *)eventName data:(id)data
{
    
}

- (void)messageRecieved:(id)data
{
    
}

@end
