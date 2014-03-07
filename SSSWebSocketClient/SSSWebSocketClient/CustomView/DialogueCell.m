//
//  DialogueCell.m
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-7.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import "DialogueCell.h"
#import "Dialogue.h"

@implementation DialogueCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.textLabel.numberOfLines = 0;
        self.textLabel.font = [UIFont systemFontOfSize:16.f];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

+ (CGFloat)cellHeightWithText:(NSString *)text
{
    return [text sizeWithAttributes:@{NSViewSizeDocumentAttribute: [NSValue valueWithCGSize:CGSizeMake(300.f, CGFLOAT_MAX)],
                                      NSDocumentTypeDocumentAttribute: NSPlainTextDocumentType,
                                      NSFontAttributeName :[UIFont systemFontOfSize:16.f]}].height;
}

- (void)renderContentsWithData:(Dialogue *)dialogue
{
    self.textLabel.text = dialogue.text;
}

@end
