//
//  ViewController.m
//  SSSWebSocketClient
//
//  Created by sagles on 14-3-6.
//  Copyright (c) 2014年 sagles. All rights reserved.
//

#import "ViewController.h"
#import "DialogueCell.h"
#import "Dialogue.h"
#import "SocketBLController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

/**
 *  The datasource for tableview which contains Dialogue instances.It 
 *  contains all the dialogues both client's and server's.
 */
@property (nonatomic, strong) NSMutableArray *dialogueArray;

/**
 *  The socket client business logic controller
 */
@property (nonatomic, strong) SocketBLController *socketController;

@end

@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillShowNotitication:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillChangeFrameNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

#pragma mark - Property methods

- (NSMutableArray *)dialogueArray
{
    if (!_dialogueArray)
    {
        _dialogueArray = [NSMutableArray array];
    }
    return _dialogueArray;
}

- (SocketBLController *)socketController
{
    if (!_socketController)
    {
        _socketController = [[SocketBLController alloc] init];
    }
    return _socketController;
}

#pragma mark - Touch events

- (IBAction)sendButtonPressed:(id)sender
{
    UITextField *textfield = (UITextField *)[(UIBarButtonItem *)self.functionToolBar.items[0] customView];
    if (![textfield isKindOfClass:[UITextField class]])
    {
        [textfield resignFirstResponder];
        return;
    }
    
    if (textfield.text.length > 0)
    {
        Dialogue *d = [[Dialogue alloc] init];
        d.text = textfield.text;
        d.type = DialogueTypeMine;
        [self.dialogueArray addObject:d];
        [self.chattingTableView reloadData];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dialogueArray.count-1
                                                    inSection:0];
        [self.chattingTableView scrollToRowAtIndexPath:indexPath
                                      atScrollPosition:UITableViewScrollPositionBottom
                                              animated:NO];
        
        textfield.text = nil;
    }
    
}
- (IBAction)connectButtonPressed:(id)sender
{
    [self.socketController startConnect];
}

- (IBAction)downSwipe:(UISwipeGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self.view endEditing:YES];
    }
}

#pragma mark - UITableViewDataSource/Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dialogueArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Dialogue *d = self.dialogueArray[indexPath.row];
    return [DialogueCell cellHeightWithText:d.text];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Dialogue *d = self.dialogueArray[indexPath.row];
    return [DialogueCell cellHeightWithText:d.text];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentitier = @"dialogue";
    DialogueCell *cell = (DialogueCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentitier];
    if (!cell)
    {
        cell = [[DialogueCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:cellIdentitier];
    }
    
    [cell renderContentsWithData:self.dialogueArray[indexPath.row]];
    
    return cell;
}

#pragma mark - Keyboard Notification actions

- (void)handleKeyboardWillShowNotitication:(NSNotification *)notify
{
    [self changeViewsFrameWithKeyboardFrame:[notify.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue]
                          animationDuration:[notify.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                                      curve:[notify.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
}

- (void)handleKeyboardWillChangeFrameNotification:(NSNotification *)notify
{
    [self changeViewsFrameWithKeyboardFrame:[notify.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue]
                          animationDuration:[notify.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                                      curve:[notify.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
}

- (void)handleKeyboardWillHideNotification:(NSNotification *)notify
{
    [self changeViewsFrameWithKeyboardFrame:[notify.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue]
                          animationDuration:[notify.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                                      curve:[notify.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
}

- (void)changeViewsFrameWithKeyboardFrame:(CGRect)keyboardFrame
                        animationDuration:(double)duration
                                    curve:(UIViewAnimationCurve)curve
{
    CGRect frame = self.functionToolBar.frame;
    frame.origin.y = keyboardFrame.origin.y - frame.size.height;
    
    [UIView setAnimationCurve:curve];
    [UIView animateWithDuration:duration
                     animations:^{
                         if (!CGRectEqualToRect(self.functionToolBar.frame, frame)) {
                             self.functionToolBar.frame = frame;
                         }
                     } completion:^(BOOL finished) {
                         
                         if (frame.origin.y < CGRectGetMaxY(self.chattingTableView.frame))
                         {
                             self.chattingTableView.contentInset =
                             UIEdgeInsetsMake(64.f,
                                              0.f,
                                              CGRectGetMaxY(self.chattingTableView.frame) - frame.origin.y,
                                              0.f);
                         }
                         else
                         {
                             self.chattingTableView.contentInset = UIEdgeInsetsMake(64.f, 0.f, 0.f, 0.f);
                         }
                         
                         if (self.dialogueArray.count > 0)
                         {
                             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dialogueArray.count-1
                                                                         inSection:0];
                             [self.chattingTableView scrollToRowAtIndexPath:indexPath
                                                           atScrollPosition:UITableViewScrollPositionBottom
                                                                   animated:NO];
                         }
                     }];
}

@end
