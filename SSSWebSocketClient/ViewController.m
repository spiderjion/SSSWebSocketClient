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
#import "MBProgressHUD.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>

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
                                             selector:@selector(handleKeyboardNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardNotification:)
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
        __block ViewController *controller = self;
        _socketController.eventBlock = ^void(NSString *eventName,id data)
        {
            [controller socketDidReceiveEvent:eventName data:data];
        };
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
        //send message
        Dialogue *d = [[Dialogue alloc] init];
        d.content = @{SSSDialogueContentKey :textfield.text};
        d.type = DialogueTypeMine;
        d.event = SSSSocketEventMessage;
        [self.socketController sendMessage:d
                                  complete:^{
                                      d.isSendSuccessfully = YES;
                                  } failure:^(NSError *error) {
                                      d.isSendSuccessfully = NO;
                                  }];
        
        [self.dialogueArray addObject:d];
        [self.chattingTableView reloadData];
        
        //scroll to bottom
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dialogueArray.count-1
                                                    inSection:0];
        [self.chattingTableView scrollToRowAtIndexPath:indexPath
                                      atScrollPosition:UITableViewScrollPositionBottom
                                              animated:NO];
        
        //clear textfield
        textfield.text = nil;
    }
    
}
- (IBAction)connectButtonPressed:(id)sender
{
    __block ViewController *controller = self;
    [self.socketController startConnect:^{
        @autoreleasepool {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Input your name"
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"cancel"
                                                      otherButtonTitles:@"ok", nil];
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            alertView.delegate = controller;
            
            [alertView show];
        }
    }];
}

- (IBAction)disconnectButtonPressed:(id)sender
{
    [self.socketController endConnect];
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
    return [DialogueCell cellHeightWithText:d.content[SSSDialogueContentKey]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Dialogue *d = self.dialogueArray[indexPath.row];
    return [DialogueCell cellHeightWithText:d.content[SSSDialogueContentKey]];
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

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        [self.socketController endConnect];
    }
    else
    {
        //send message to tell what's your name to server.
        NSString *text = [alertView textFieldAtIndex:0].text;
        if (text.length > 0)
        {
            Dialogue *d = [[Dialogue alloc] init];
            d.event = SSSSocketEventNickName;
            d.type = DialogueTypeNone;
            d.content = text;
            
            [self.socketController sendMessage:d
                                      complete:^{
                                          //setup member list
                                      } failure:^(NSError *error) {
                                          @autoreleasepool {
                                              MBProgressHUD *hud =
                                              [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                              hud.labelText = error.debugDescription;
                                              [hud hide:YES afterDelay:2.f];
                                          }
                                      }];
        }
        
    }
}

#pragma mark - Keyboard Notification actions

- (void)handleKeyboardNotification:(NSNotification *)notify
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

#pragma mark - Call back

- (void)socketDidReceiveEvent:(NSString *)eventName data:(id)data
{
    if ([eventName isEqualToString:SSSSocketEventOnlineList])
    {
        //setup member list
    }
    else if ([eventName isEqualToString:SSSSocketEventMessage])
    {
        //reload dialogue table
    }
}

@end
