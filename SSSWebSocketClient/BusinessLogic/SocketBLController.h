//
//  SocketBLController.h
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-7.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^EventReceiveBlock)(NSString *eventName, id data);

@class Dialogue;

@interface SocketBLController : NSObject

/**
 *  event receive block.It will call when client receive event message from server.
 */
@property (nonatomic, copy) EventReceiveBlock eventBlock;

/**
 *  Start to connect server.It will ask a nickname when connect successfully.
 *
 *  @param complete callback
 */
- (void)startConnect:(void(^)(void))complete;

- (void)endConnect;

- (void)sendMessage:(Dialogue *)message
           complete:(void(^)())complete
            failure:(void(^)(NSError *error))failure;

@end
