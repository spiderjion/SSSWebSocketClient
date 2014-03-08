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
 *  The content of dialogue
 */
@property (nonatomic, copy) NSString *text;

/**
 *  type of DialogueType
 */
@property (nonatomic, assign) DialogueType type;

@end
