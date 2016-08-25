//
//  LCCKChatBar.m
//  LCCKChatBarExample
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/8/17.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatBar.h"
#import "LCCKChatMoreView.h"
#import "LCCKChatFaceView.h"
#import "LCCKProgressHUD.h"
#import "Mp3Recorder.h"
#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif
#import "LCCKUIService.h"
#import "UIImage+LCCKExtension.h"
#import "NSString+LCCKExtension.h"
#import "LCCKConversationService.h"

NSString *const kLCCKBatchDeleteTextPrefix = @"kLCCKBatchDeleteTextPrefix";
NSString *const kLCCKBatchDeleteTextSuffix = @"kLCCKBatchDeleteTextSuffix";

@interface LCCKChatBar () <UITextViewDelegate, UINavigationControllerDelegate, Mp3RecorderDelegate, LCCKChatFaceViewDelegate>

@property (strong, nonatomic) Mp3Recorder *MP3;
@property (nonatomic, strong) UIView *inputBarBackgroundView; /**< 输入栏目背景视图 */
@property (strong, nonatomic) UIButton *voiceButton; /**< 切换录音模式按钮 */
@property (strong, nonatomic) UIButton *voiceRecordButton; /**< 录音按钮 */

@property (strong, nonatomic) UIButton *faceButton; /**< 表情按钮 */
@property (strong, nonatomic) UIButton *moreButton; /**< 更多按钮 */
@property (weak, nonatomic) LCCKChatFaceView *faceView; /**< 当前活跃的底部view,用来指向faceView */
@property (weak, nonatomic) LCCKChatMoreView *moreView; /**< 当前活跃的底部view,用来指向moreView */

@property (assign, nonatomic, readonly) CGFloat bottomHeight;
@property (strong, nonatomic, readonly) UIViewController *rootViewController;

@property (assign, nonatomic) CGSize keyboardSize;

@property (strong, nonatomic) UITextView *textView;
@property (assign, nonatomic) CGFloat oldTextViewHeight;
@property (nonatomic, assign, getter=shouldAllowTextViewContentOffset) BOOL allowTextViewContentOffset;
@property (nonatomic, assign, getter=isClosed) BOOL close;

#pragma mark - MessageInputView Customize UI
///=============================================================================
/// @name MessageInputView Customize UI
///=============================================================================

@property (nonatomic, strong) UIColor *messageInputViewBackgroundColor;
@property (nonatomic, strong) UIColor *messageInputViewTextFieldTextColor;
@property (nonatomic, strong) UIColor *messageInputViewTextFieldBackgroundColor;
@property (nonatomic, strong) UIColor *messageInputViewRecordTextColor;
//TODO:MessageInputView-Tint-Color

@end

@implementation LCCKChatBar

#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setupConstraints {
    CGFloat offset = 5;
    [self.inputBarBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.and.top.mas_equalTo(self);
        make.bottom.mas_equalTo(self).priorityLow();
    }];
    
    [self.voiceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.inputBarBackgroundView.mas_left).with.offset(offset);
        make.bottom.equalTo(self.inputBarBackgroundView.mas_bottom).with.offset(-kChatBarBottomOffset);
        make.width.equalTo(self.voiceButton.mas_height);
    }];
    
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.inputBarBackgroundView.mas_right).with.offset(-offset);
        make.bottom.equalTo(self.inputBarBackgroundView.mas_bottom).with.offset(-kChatBarBottomOffset);
        make.width.equalTo(self.moreButton.mas_height);
    }];
    
    [self.faceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.moreButton.mas_left).with.offset(-offset);
        make.bottom.equalTo(self.inputBarBackgroundView.mas_bottom).with.offset(-kChatBarBottomOffset);
        make.width.equalTo(self.faceButton.mas_height);
    }];
    
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.voiceButton.mas_right).with.offset(offset);
        make.right.equalTo(self.faceButton.mas_left).with.offset(-offset);
        make.top.equalTo(self.inputBarBackgroundView).with.offset(kChatBarTextViewBottomOffset);
        make.bottom.equalTo(self.inputBarBackgroundView).with.offset(-kChatBarTextViewBottomOffset);
        make.height.mas_greaterThanOrEqualTo(kLCCKChatBarTextViewFrameMinHeight);
    }];
    
    CGFloat voiceRecordButtoInsets = -5.f;
    [self.voiceRecordButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.textView).insets(UIEdgeInsetsMake(voiceRecordButtoInsets, voiceRecordButtoInsets, voiceRecordButtoInsets, voiceRecordButtoInsets));
    }];
}

- (void)dealloc {
    self.delegate = nil;
    _faceView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark -
#pragma mark - Setter Method

- (void)setCachedText:(NSString *)cachedText {
    _cachedText = [cachedText copy];
    if ([_cachedText isEqualToString:@""]) {
        [self updateChatBarConstraintsIfNeededShouldCacheText:NO];
        self.allowTextViewContentOffset = YES;
        return;
    }
    if ([_cachedText lcck_isSpace]) {
        _cachedText = @"";
        return;
    }
}

- (UIViewController *)controllerRef {
    return self.delegate;
}

- (void)setDelegate:(id<LCCKChatBarDelegate>)delegate {
    _delegate = delegate;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (range.location == [textView.text length]) {
        self.allowTextViewContentOffset = YES;
    } else {
        self.allowTextViewContentOffset = NO;
    }
    if ([text isEqualToString:@"\n"]) {
        [self sendTextMessage:textView.text];
        return NO;
    } else if (text.length == 0){
        //构造元素需要使用两个空格来进行缩进，右括号]或者}写在新的一行，并且与调用语法糖那行代码的第一个非空字符对齐：
        NSArray *defaultRegulations = @[
                                        //判断删除的文字是否符合表情文字规则
                                        @{
                                            kLCCKBatchDeleteTextPrefix : @"[",
                                            kLCCKBatchDeleteTextSuffix : @"]",
                                            },
                                        //判断删除的文字是否符合提醒群成员的文字规则
                                        @{
                                            kLCCKBatchDeleteTextPrefix : @"@",
                                            kLCCKBatchDeleteTextSuffix : @" ",
                                            },
                                        ];
        NSArray *additionRegulation;
        if ([self.delegate respondsToSelector:@selector(regulationForBatchDeleteText)]) {
            additionRegulation = [self.delegate regulationForBatchDeleteText];
        }
        if (additionRegulation.count > 0) {
            defaultRegulations = [defaultRegulations arrayByAddingObjectsFromArray:additionRegulation];
        }
        for (NSDictionary *regulation in defaultRegulations) {
            NSString *prefix = regulation[kLCCKBatchDeleteTextPrefix];
            NSString *suffix = regulation[kLCCKBatchDeleteTextSuffix];
            if (![self textView:textView shouldChangeTextInRange:range deleteBatchOfTextWithPrefix:prefix suffix:suffix]) {
                return  NO;
            }
        }
        return YES;
    } else if ([text isEqualToString:@"@"]) {
        if ([self.delegate respondsToSelector:@selector(didInputAtSign:)]) {
            [self.delegate didInputAtSign:self];
        }
        return YES;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self textViewDidChange:textView shouldCacheText:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range deleteBatchOfTextWithPrefix:(NSString *)prefix
          suffix:(NSString *)suffix {
    NSString *substringOfText = [textView.text substringWithRange:range];
    if ([substringOfText isEqualToString:suffix]) {
        NSUInteger location = range.location;
        NSUInteger length = range.length;
        NSString *subText;
        while (YES) {
            if (location == 0) {
                return YES;
            }
            location -- ;
            length ++ ;
            subText = [textView.text substringWithRange:NSMakeRange(location, length)];
            if (([subText hasPrefix:prefix] && [subText hasSuffix:suffix])) {
                //这里注意，批量删除的字符串，除了前缀和后缀，中间不能有空格出现
                NSString *string = [textView.text substringWithRange:NSMakeRange(location, length-1)];
                if (![string lcck_containsString:@" "]) {
                    break;
                }
            }
        }
        
        textView.text = [textView.text stringByReplacingCharactersInRange:NSMakeRange(location, length) withString:@""];
        [textView setSelectedRange:NSMakeRange(location, 0)];
        [self textViewDidChange:self.textView];
        return NO;
    }
    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    self.faceButton.selected = self.moreButton.selected = self.voiceButton.selected = NO;
    [self showFaceView:NO];
    [self showMoreView:NO];
    [self showVoiceView:NO];
    return YES;
}

#pragma mark -
#pragma mark - Private Methods

- (void)updateChatBarConstraintsIfNeeded {
    NSString *reason = [NSString stringWithFormat:@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"Should update on main thread"];
    NSAssert([NSThread mainThread], reason);
    BOOL shouldCacheText = NO;
    BOOL shouldScrollToBottom = YES;
    LCCKFunctionViewShowType functionViewShowType = self.showType;
    switch (functionViewShowType) {
        case LCCKFunctionViewShowNothing: {
            shouldScrollToBottom = NO;
            shouldCacheText = YES;
        }
            break;
        case LCCKFunctionViewShowFace:
        case LCCKFunctionViewShowMore:
        case LCCKFunctionViewShowKeyboard: {
            shouldCacheText = YES;
        }
            break;
        case LCCKFunctionViewShowVoice:
            shouldCacheText = NO;
            break;
    }
    [self updateChatBarConstraintsIfNeededShouldCacheText:shouldCacheText];
    [self chatBarFrameDidChangeShouldScrollToBottom:shouldScrollToBottom];
}

- (void)updateChatBarConstraintsIfNeededShouldCacheText:(BOOL)shouldCacheText {
    [self textViewDidChange:self.textView shouldCacheText:shouldCacheText];
}

- (void)updateChatBarKeyBoardConstraints {
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-self.keyboardSize.height);
    }];
    [UIView animateWithDuration:LCCKAnimateDuration animations:^{
        [self layoutIfNeeded];
    } completion:nil];
}

#pragma mark - 核心方法
///=============================================================================
/// @name 核心方法
///=============================================================================

/*!
 * updateChatBarConstraintsIfNeeded: WhenTextViewHeightDidChanged
 * 只要文本修改了就会调用，特殊情况，也会调用：刚刚进入对话追加草稿、键盘类型切换、添加表情信息
 */
- (void)textViewDidChange:(UITextView *)textView
          shouldCacheText:(BOOL)shouldCacheText {
    if (shouldCacheText) {
        self.cachedText = self.textView.text;
    }
    CGRect textViewFrame = self.textView.frame;
    CGSize textSize = [self.textView sizeThatFits:CGSizeMake(CGRectGetWidth(textViewFrame), 1000.0f)];
    // from iOS 7, the content size will be accurate only if the scrolling is enabled.
    textView.scrollEnabled = (textSize.height > kLCCKChatBarTextViewFrameMinHeight);
    // textView 控件的高度在 kLCCKChatBarTextViewFrameMinHeight 和 kLCCKChatBarMaxHeight-offset 之间
    CGFloat newTextViewHeight = MAX(kLCCKChatBarTextViewFrameMinHeight, MIN(kLCCKChatBarTextViewFrameMaxHeight, textSize.height));
    BOOL textViewHeightChanged = (self.oldTextViewHeight != newTextViewHeight);
    if (textViewHeightChanged) {
       //FIXME:如果有草稿，且超出了最低高度，会产生约束警告。
        self.oldTextViewHeight = newTextViewHeight;
        [self.textView mas_updateConstraints:^(MASConstraintMaker *make) {
            CGFloat height = newTextViewHeight;
            make.height.mas_equalTo(height);
        }];
        [self chatBarFrameDidChangeShouldScrollToBottom:YES];
    }
    if (textView.scrollEnabled && self.allowTextViewContentOffset) {
        if (newTextViewHeight == kLCCKChatBarTextViewFrameMaxHeight) {
            [textView setContentOffset:CGPointMake(0, textView.contentSize.height - newTextViewHeight) animated:YES];
        } else {
            [textView setContentOffset:CGPointZero animated:YES];
        }
    }
}

#pragma mark - MP3RecordedDelegate

- (void)endConvertWithMP3FileName:(NSString *)fileName {
    if (fileName) {
        [LCCKProgressHUD dismissWithProgressState:LCCKProgressSuccess];
        [self sendVoiceMessage:fileName seconds:[LCCKProgressHUD seconds]];
    } else {
        [LCCKProgressHUD dismissWithProgressState:LCCKProgressError];
    }
}

- (void)failRecord {
    [LCCKProgressHUD dismissWithProgressState:LCCKProgressError];
}

- (void)beginConvert {
    [LCCKProgressHUD changeSubTitle:@"正在转换..."];
}



#pragma mark - LCCKChatFaceViewDelegate

- (void)faceViewSendFace:(NSString *)faceName {
    if ([faceName isEqualToString:@"[删除]"]) {
        [self textView:self.textView shouldChangeTextInRange:NSMakeRange(self.textView.text.length - 1, 1) replacementText:@""];
    } else if ([faceName isEqualToString:@"发送"]) {
        NSString *text = self.textView.text;
        if (!text || text.length == 0) {
            return;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatBar:sendMessage:)]) {
            [self.delegate chatBar:self sendMessage:text];
        }
        self.textView.text = @"";
        self.cachedText = @"";
        self.showType = LCCKFunctionViewShowFace;
    } else {
        [self appendString:faceName beginInputing:NO];
    }
}

#pragma mark - Public Methods

- (void)close {
    //关闭
    self.close = YES;
}

- (void)open {
    self.close = NO;
}

- (void)endInputing {
    if (self.voiceButton.selected) {
        return;
    }
    self.faceButton.selected = self.moreButton.selected = self.voiceButton.selected = NO;
    self.showType = LCCKFunctionViewShowNothing;
}

- (void)appendString:(NSString *)string beginInputing:(BOOL)beginInputing {
    self.allowTextViewContentOffset = YES;
    if (self.textView.text.length > 0 && [string hasPrefix:@"@"] && ![self.textView.text hasSuffix:@" "]) {
        self.textView.text = [self.textView.text stringByAppendingString:@" "];
    }
    NSString *textViewText;
    //特殊情况：处于语音按钮显示时，self.textView.text无信息，但self.cachedText有信息
    if (self.textView.text.length == 0 && self.cachedText.length > 0) {
        textViewText = self.cachedText;
    } else {
        textViewText = self.textView.text;
    }
    NSString *appendedString = [textViewText stringByAppendingString:string];
    self.cachedText = appendedString;
    self.textView.text = appendedString;
    if (beginInputing && self.keyboardSize.height == 0) {
        [self beginInputing];
    } else {
        [self updateChatBarConstraintsIfNeeded];
    }
}

- (void)appendString:(NSString *)string {
    [self appendString:string beginInputing:YES];
}

- (void)beginInputing {
    [self.textView becomeFirstResponder];
}

#pragma mark - Private Methods

- (void)keyboardWillHide:(NSNotification *)notification {
    NSString *reason = [NSString stringWithFormat:@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"Should update on main thread"];
    NSAssert([NSThread mainThread], reason);
    if (self.isClosed) {
        return;
    }
    self.keyboardSize = CGSizeZero;
    if (_showType == LCCKFunctionViewShowKeyboard) {
        _showType = LCCKFunctionViewShowNothing;
    }
    [self updateChatBarKeyBoardConstraints];
    [self updateChatBarConstraintsIfNeeded];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSString *reason = [NSString stringWithFormat:@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"Should update on main thread"];
    NSAssert([NSThread mainThread], reason);
    if (self.isClosed) {
        return;
    }
    CGFloat oldHeight = self.keyboardSize.height;
    self.keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    //兼容搜狗输入法：一次键盘事件会通知两次，且键盘高度不一。
    if (self.keyboardSize.height != oldHeight) {
        _showType = LCCKFunctionViewShowNothing;
    }
    if (self.keyboardSize.height == 0) {
        _showType = LCCKFunctionViewShowNothing;
        return;
    }
    self.allowTextViewContentOffset = YES;
    [self updateChatBarKeyBoardConstraints];
    self.showType = LCCKFunctionViewShowKeyboard;
}

/**
 *  lazy load inputBarBackgroundView
 *
 *  @return UIView
 */
- (UIView *)inputBarBackgroundView {
    if (_inputBarBackgroundView == nil) {
        UIView *inputBarBackgroundView = [[UIView alloc] init];
        _inputBarBackgroundView = inputBarBackgroundView;
    }
    return _inputBarBackgroundView;
}

- (void)setup {
    self.close = NO;
    self.oldTextViewHeight = kLCCKChatBarTextViewFrameMinHeight;
    self.allowTextViewContentOffset = YES;
    self.MP3 = [[Mp3Recorder alloc] initWithDelegate:self];
    [self addSubview:self.inputBarBackgroundView];
    
    [self.inputBarBackgroundView addSubview:self.voiceButton];
    [self.inputBarBackgroundView addSubview:self.moreButton];
    [self.inputBarBackgroundView addSubview:self.faceButton];
    [self.inputBarBackgroundView addSubview:self.textView];
    [self.inputBarBackgroundView addSubview:self.voiceRecordButton];
    
    UIImageView *topLine = [[UIImageView alloc] init];
    topLine.backgroundColor = kLCCKTopLineBackgroundColor;
    [self.inputBarBackgroundView addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.and.top.equalTo(self.inputBarBackgroundView);
        make.height.mas_equalTo(.5f);
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    self.backgroundColor = self.messageInputViewBackgroundColor;
    [self setupConstraints];
}

/**
 *  开始录音
 */
- (void)startRecordVoice {
    [LCCKProgressHUD show];
    self.voiceRecordButton.highlighted = YES;
    [self.MP3 startRecord];
}

/**
 *  取消录音
 */
- (void)cancelRecordVoice {
    [LCCKProgressHUD dismissWithMessage:@"取消录音"];
    self.voiceRecordButton.highlighted = NO;
    [self.MP3 cancelRecord];
}

/**
 *  录音结束
 */
- (void)confirmRecordVoice {
    [self.MP3 stopRecord];
}

/**
 *  更新录音显示状态,手指向上滑动后提示松开取消录音
 */
- (void)updateCancelRecordVoice {
    [LCCKProgressHUD changeSubTitle:@"松开取消录音"];
}

/**
 *  更新录音状态,手指重新滑动到范围内,提示向上取消录音
 */
- (void)updateContinueRecordVoice {
    [LCCKProgressHUD changeSubTitle:@"向上滑动取消录音"];
}

- (void)setShowType:(LCCKFunctionViewShowType)showType {
    if (_showType == showType) {
        return;
    }
    _showType = showType;
    //显示对应的View
    [self showMoreView:showType == LCCKFunctionViewShowMore && self.moreButton.selected];
    [self showVoiceView:showType == LCCKFunctionViewShowVoice && self.voiceButton.selected];
    [self showFaceView:showType == LCCKFunctionViewShowFace && self.faceButton.selected];
    
    switch (showType) {
        case LCCKFunctionViewShowNothing: {
            self.textView.text = self.cachedText;
            [self.textView resignFirstResponder];
        }
            break;
        case LCCKFunctionViewShowVoice: {
            self.cachedText = self.textView.text;
            self.textView.text = nil;
            [self.textView resignFirstResponder];
        }
            break;
        case LCCKFunctionViewShowMore:
        case LCCKFunctionViewShowFace:
            self.textView.text = self.cachedText;
            [self.textView resignFirstResponder];
            break;
        case LCCKFunctionViewShowKeyboard:
            self.textView.text = self.cachedText;
            break;
    }
    [self updateChatBarConstraintsIfNeeded];
}

- (void)buttonAction:(UIButton *)button {
    LCCKFunctionViewShowType showType = button.tag;
    //更改对应按钮的状态
    if (button == self.faceButton) {
        [self.faceButton setSelected:!self.faceButton.selected];
        [self.moreButton setSelected:NO];
        [self.voiceButton setSelected:NO];
    } else if (button == self.moreButton){
        [self.faceButton setSelected:NO];
        [self.moreButton setSelected:!self.moreButton.selected];
        [self.voiceButton setSelected:NO];
    } else if (button == self.voiceButton){
        [self.faceButton setSelected:NO];
        [self.moreButton setSelected:NO];
        [self.voiceButton setSelected:!self.voiceButton.selected];
    }
    if (!button.selected) {
        showType = LCCKFunctionViewShowKeyboard;
        [self beginInputing];
    }
    self.showType = showType;
}

- (void)showFaceView:(BOOL)show {
    if (show) {
        [self faceView];
        [self.faceView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.and.left.mas_equalTo(self);
            make.height.mas_equalTo(kFunctionViewHeight);
            // hide blow screen
            make.top.mas_equalTo(self.superview.mas_bottom);
        }];
        [self.faceView layoutIfNeeded];
        
        [self.faceView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.superview.mas_bottom).offset(-kFunctionViewHeight);
        }];
        [UIView animateWithDuration:LCCKAnimateDuration animations:^{
            [self.faceView layoutIfNeeded];
        } completion:nil];
        
        [self.faceView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.inputBarBackgroundView.mas_bottom);
        }];
    } else if (self.faceView.superview) {
        [self.faceView removeFromSuperview];
    }
}

/**
 *  显示moreView
 *  @param show 要显示的moreView
 */
- (void)showMoreView:(BOOL)show {
    if (show) {
        [self moreView];
        [self.moreView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.and.left.mas_equalTo(self);
            make.height.mas_equalTo(kFunctionViewHeight);
            // hide blow screen
            make.top.mas_equalTo(self.superview.mas_bottom);
        }];
        [self.moreView layoutIfNeeded];
        
        [self.moreView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.superview.mas_bottom).offset(-kFunctionViewHeight);
        }];
        
        [UIView animateWithDuration:LCCKAnimateDuration animations:^{
            [self.moreView layoutIfNeeded];
        } completion:nil];
        
        [self.moreView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.inputBarBackgroundView.mas_bottom);
        }];
    } else if (self.moreView.superview) {
        [self.moreView removeFromSuperview];
    }
}

- (void)showVoiceView:(BOOL)show {
    self.voiceButton.selected = show;
    self.voiceRecordButton.selected = show;
    self.voiceRecordButton.hidden = !show;
    self.textView.hidden = !self.voiceRecordButton.hidden;
}

/**
 *  发送普通的文本信息,通知代理
 *
 *  @param text 发送的文本信息
 */
- (void)sendTextMessage:(NSString *)text{
    if (!text || text.length == 0 || [text lcck_isSpace]) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBar:sendMessage:)]) {
        [self.delegate chatBar:self sendMessage:text];
    }
    self.textView.text = @"";
    self.cachedText = @"";
    self.showType = LCCKFunctionViewShowKeyboard;
}

/**
 *  通知代理发送语音信息
 *
 *  @param voiceData 发送的语音信息data
 *  @param seconds   语音时长
 */
- (void)sendVoiceMessage:(NSString *)voiceFileName seconds:(NSTimeInterval)seconds {
    if ((seconds > 0) && self.delegate && [self.delegate respondsToSelector:@selector(chatBar:sendVoice:seconds:)]) {
        [self.delegate chatBar:self sendVoice:voiceFileName seconds:seconds];
    }
}

/**
 *  通知代理发送图片信息
 *
 *  @param image 发送的图片
 */
- (void)sendImageMessage:(UIImage *)image {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBar:sendPictures:)]) {
        [self.delegate chatBar:self sendPictures:@[image]];
    }
}

- (void)chatBarFrameDidChangeShouldScrollToBottom:(BOOL)shouldScrollToBottom {
    NSString *reason = [NSString stringWithFormat:@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"Should update on main thread"];
    NSAssert([NSThread mainThread], reason);
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBarFrameDidChange:shouldScrollToBottom:)]) {
        [self.delegate chatBarFrameDidChange:self shouldScrollToBottom:shouldScrollToBottom];
    }
}

- (UIImage *)imageInBundlePathForImageName:(NSString *)imageName {
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
    return image;
}

#pragma mark - Getters

- (LCCKChatFaceView *)faceView {
    if (!_faceView) {
        LCCKChatFaceView *faceView = [[LCCKChatFaceView alloc] init];
        faceView.delegate = self;
        faceView.backgroundColor = self.backgroundColor;
        [self addSubview:(_faceView = faceView)];
    }
    return _faceView;
}

- (LCCKChatMoreView *)moreView {
    if (!_moreView) {
        LCCKChatMoreView *moreView = [[LCCKChatMoreView alloc] init];
        moreView.inputViewRef = self;
        [self addSubview:(_moreView = moreView)];
    }
    return _moreView;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.font = [UIFont systemFontOfSize:16.0f];
        _textView.delegate = self;
        _textView.layer.cornerRadius = 4.0f;
        _textView.textColor = self.messageInputViewTextFieldTextColor;
        _textView.backgroundColor = self.messageInputViewTextFieldBackgroundColor;
        _textView.layer.borderColor = [UIColor colorWithRed:204.0/255.0f green:204.0/255.0f blue:204.0/255.0f alpha:1.0f].CGColor;
        _textView.returnKeyType = UIReturnKeySend;
        _textView.layer.borderWidth = .5f;
        _textView.layer.masksToBounds = YES;
        _textView.scrollsToTop = NO;
    }
    return _textView;
}

- (UIButton *)voiceButton {
    if (!_voiceButton) {
        _voiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _voiceButton.tag = LCCKFunctionViewShowVoice;
        [_voiceButton setTitleColor:self.messageInputViewRecordTextColor forState:UIControlStateNormal];
        [_voiceButton setTitleColor:self.messageInputViewRecordTextColor forState:UIControlStateHighlighted];
        [_voiceButton setBackgroundImage:[self imageInBundlePathForImageName:@"ToolViewInputVoice"] forState:UIControlStateNormal];
        [_voiceButton setBackgroundImage:[self imageInBundlePathForImageName:@"ToolViewKeyboard"] forState:UIControlStateSelected];
        [_voiceButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_voiceButton sizeToFit];
    }
    return _voiceButton;
}

- (UIButton *)voiceRecordButton {
    if (!_voiceRecordButton) {
        _voiceRecordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _voiceRecordButton.hidden = YES;
        _voiceRecordButton.frame = self.textView.bounds;
        _voiceRecordButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_voiceRecordButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(9, 9, 9, 9);
        UIImage *voiceRecordButtonNormalBackgroundImage = [[self imageInBundlePathForImageName:@"VoiceBtn_Black"] resizableImageWithCapInsets:edgeInsets resizingMode:UIImageResizingModeStretch];
        UIImage *voiceRecordButtonHighlightedBackgroundImage = [[self imageInBundlePathForImageName:@"VoiceBtn_BlackHL"] resizableImageWithCapInsets:edgeInsets resizingMode:UIImageResizingModeStretch];
        [_voiceRecordButton setBackgroundImage:voiceRecordButtonNormalBackgroundImage forState:UIControlStateNormal];
        [_voiceRecordButton setBackgroundImage:voiceRecordButtonHighlightedBackgroundImage forState:UIControlStateHighlighted];
        _voiceRecordButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        [_voiceRecordButton setTitle:@"按住 说话" forState:UIControlStateNormal];
        [_voiceRecordButton setTitle:@"松开 结束" forState:UIControlStateHighlighted];
        [_voiceRecordButton addTarget:self action:@selector(startRecordVoice) forControlEvents:UIControlEventTouchDown];
        [_voiceRecordButton addTarget:self action:@selector(cancelRecordVoice) forControlEvents:UIControlEventTouchUpOutside];
        [_voiceRecordButton addTarget:self action:@selector(confirmRecordVoice) forControlEvents:UIControlEventTouchUpInside];
        [_voiceRecordButton addTarget:self action:@selector(updateCancelRecordVoice) forControlEvents:UIControlEventTouchDragExit];
        [_voiceRecordButton addTarget:self action:@selector(updateContinueRecordVoice) forControlEvents:UIControlEventTouchDragEnter];
    }
    return _voiceRecordButton;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _moreButton.tag = LCCKFunctionViewShowMore;
        [_moreButton setBackgroundImage:[self imageInBundlePathForImageName:@"TypeSelectorBtn_Black"] forState:UIControlStateNormal];
        [_moreButton setBackgroundImage:[self imageInBundlePathForImageName:@"TypeSelectorBtn_Black"] forState:UIControlStateSelected];
        [_moreButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_moreButton sizeToFit];
    }
    return _moreButton;
}

- (UIButton *)faceButton {
    if (!_faceButton) {
        _faceButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _faceButton.tag = LCCKFunctionViewShowFace;
        [_faceButton setBackgroundImage:[self imageInBundlePathForImageName:@"ToolViewEmotion"] forState:UIControlStateNormal];
        [_faceButton setBackgroundImage:[self imageInBundlePathForImageName:@"ToolViewKeyboard"] forState:UIControlStateSelected];
        [_faceButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_faceButton sizeToFit];
    }
    return _faceButton;
}

- (CGFloat)bottomHeight {
    if (self.faceView.superview || self.moreView.superview) {
        return MAX(self.keyboardSize.height, MAX(self.faceView.frame.size.height, self.moreView.frame.size.height));
    } else {
        return MAX(self.keyboardSize.height, CGFLOAT_MIN);
    }
}

- (UIViewController *)rootViewController {
    return [[UIApplication sharedApplication] keyWindow].rootViewController;
}

#pragma mark -
#pragma mark - MessageInputView Customize UI Method

- (UIColor *)messageInputViewBackgroundColor {
    if (_messageInputViewBackgroundColor) {
        return _messageInputViewBackgroundColor;
    }
    _messageInputViewBackgroundColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"MessageInputView-BackgroundColor"];
    return _messageInputViewBackgroundColor;
}

- (UIColor *)messageInputViewTextFieldTextColor {
    if (_messageInputViewTextFieldTextColor) {
        return _messageInputViewTextFieldTextColor;
    }
    _messageInputViewTextFieldTextColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"MessageInputView-TextField-TextColor"];
    return _messageInputViewTextFieldTextColor;
}

- (UIColor *)messageInputViewTextFieldBackgroundColor {
    if (_messageInputViewTextFieldBackgroundColor) {
        return _messageInputViewTextFieldBackgroundColor;
    }
    _messageInputViewTextFieldBackgroundColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"MessageInputView-TextField-BackgroundColor"];
    return _messageInputViewTextFieldBackgroundColor;
}

- (UIColor *)messageInputViewRecordTextColor {
    if (_messageInputViewRecordTextColor) {
        return _messageInputViewRecordTextColor;
    }
    _messageInputViewRecordTextColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"MessageInputView-Record-TextColor"];
    return _messageInputViewRecordTextColor;
}

@end
