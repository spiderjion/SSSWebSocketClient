//
//  Dialogue.h
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-7.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

/**
 *  The dialogue type
 */
typedef NS_ENUM(NSInteger, DialogueType)
{
    /*!
     @brief The dialogue that will not show.
     */
    DialogueTypeNone,
    /*!
     @brief The dialogue that send by the client and display on the right in the cell.
     */
    DialogueTypeMine,
    /*!
     @brief The dialogue that receive from server and display on the left in the cell.
     */
    DialogueTypeOthers
};


#import "BaseModel.h"

@interface Dialogue : BaseModel

/**
 *  The content of dialogue.It can be string or dictionary. if it's a dic,the keys of dic are in SSSKey.h.
 */
@property (nonatomic, strong) id content;

/**
 *  type of DialogueType
 */
@property (nonatomic, assign) DialogueType type;

/**
 *  dialogue event type.A dialogue maybe just for operation like an administrator kick out a man from group.
 */
@property (nonatomic, copy) NSString *event;

/**
 *  A Boolean value that determines the message send successfully or not.
 */
@property (nonatomic, assign) BOOL isSendSuccessfully;

@end
