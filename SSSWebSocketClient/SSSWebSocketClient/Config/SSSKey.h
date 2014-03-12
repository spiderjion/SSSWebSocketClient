//
//  SSSKey.h
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-12.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSSKey : NSObject

/**
 *  The keys for Dialogue model instance's content dic.
 */
SSS_EXTERN NSString *const SSSDialogueToKey;
SSS_EXTERN NSString *const SSSDialogueContentKey;


/**
 *  The keys for socket event.
 */
SSS_EXTERN NSString *const SSSSocketEventNickName;
SSS_EXTERN NSString *const SSSSocketEventOnlineList;
SSS_EXTERN NSString *const SSSSocketEventMessage;

@end
