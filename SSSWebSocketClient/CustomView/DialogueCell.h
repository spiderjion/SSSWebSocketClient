//
//  DialogueCell.h
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-7.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Dialogue;

@interface DialogueCell : UITableViewCell

+ (CGFloat)cellHeightWithText:(NSString *)text;

- (void)renderContentsWithData:(Dialogue *)dialogue;

@end
