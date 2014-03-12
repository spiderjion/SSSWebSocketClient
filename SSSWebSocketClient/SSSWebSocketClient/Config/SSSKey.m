//
//  SSSKey.m
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-12.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import "SSSKey.h"

@implementation SSSKey

/**
 *  The keys for Dialogue model instance's content dic.
 */
NSString *const SSSDialogueToKey = @"to";
NSString *const SSSDialogueContentKey = @"text";

/**
 *  The keys for socket event.
 */
NSString *const SSSSocketEventNickName = @"nickname";
NSString *const SSSSocketEventOnlineList = @"online";
NSString *const SSSSocketEventMessage = @"message";

@end
