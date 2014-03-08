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
                                            secure:NO
                                     withNamespace:SOcketEndPoint];
    }
    return _socket;
}

- (void)startConnect
{
    [self.socket setEventRecievedBlock:^(NSString *eventName, id data) {
        NSLog(@"%@ : %@", eventName, data);
    }];
    
    [self.socket connectWithSuccess:^{
        [self.socket emit:@"I'm ready!" args:@"sagles" error:nil];
    } andFailure:^(NSError *error) {
        NSLog(@"Fail to connect : %@",error);
    }];
}

- (void)endConnect
{
    [self.socket disconnect];
}

@end
