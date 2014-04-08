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
#import "Dialogue.h"

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

- (void)sendMessage:(Dialogue *)message complete:(void (^)())complete failure:(void (^)(NSError *))failure
{
    NSError *error = nil;
    BOOL isSuccess = [self.socket emit:message.event
                                  args:message.content
                                 error:&error];
    if (isSuccess)
    {
        NSLog(@"send message : %@",message.content);
        if (complete != NULL)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete();
            });
        }
    }
    else
    {
        NSLog(@"Fail to send message : %@",error);
        if (failure != NULL)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }
}

#pragma mark - Private methods

- (void)eventRecieved:(NSString *)eventName data:(id)data
{
    if (self.eventBlock != NULL)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.eventBlock(eventName,data);
        });
    }
}

- (void)messageRecieved:(id)data
{
    //none
}

@end
