//
//  Dialogue.h
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-7.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

/**
 *  对话类型
 */
typedef NS_ENUM(NSInteger, DialogueType)
{
    /*!
     @brief 自己的
     */
    DialogueTypeMine,
    /*!
     @brief 别人的
     */
    DialogueTypeOthers
};


#import "BaseModel.h"

@interface Dialogue : BaseModel

/**
 *  对话内容
 */
@property (nonatomic, copy) NSString *text;

/**
 *  对话类型
 */
@property (nonatomic, assign) DialogueType type;

@end
