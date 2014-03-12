//
//  DialogueCell.m
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-7.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import "DialogueCell.h"
#import "Dialogue.h"
#import "NSObject+DyCinjection.h"

@implementation DialogueCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self setCellContents];
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
    self.textLabel.text = dialogue.content[SSSDialogueContentKey];
    if (dialogue.type == DialogueTypeMine)
    {
        self.textLabel.textColor = [UIColor orangeColor];
    }
    else
    {
        self.textLabel.textColor = [UIColor blackColor];
    }
}

- (void)setCellContents
{
    self.textLabel.numberOfLines = 0;
    self.textLabel.font = [UIFont systemFontOfSize:16.f];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
}

#if IsEnableDyci
- (void)updateOnClassInjection
{
    [self setCellContents];
}
#endif

@end
