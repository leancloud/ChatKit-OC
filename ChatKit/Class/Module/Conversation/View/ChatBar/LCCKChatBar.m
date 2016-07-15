//
//  LCCKChatBar.m
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/8/17.
//  Copyright (c) 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKChatBar.h"

#import "LCCKLocationController.h"
#import "LCCKChatMoreView.h"
#import "LCCKChatFaceView.h"
#import "LCCKProgressHUD.h"
#import "Mp3Recorder.h"
#import "Masonry.h"
#import "LCCKUIService.h"
#import "UIImage+LCCKExtension.h"
#import "NSString+LCCKExtension.h"

NSString *const kLCCKBatchDeleteTextPrefix = @"kLCCKBatchDeleteTextPrefix";
NSString *const kLCCKBatchDeleteTextSuffix = @"kLCCKBatchDeleteTextSuffix";

@interface LCCKChatBar () <UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, Mp3RecorderDelegate,LCCKChatMoreViewDelegate, LCCKChatMoreViewDataSource, LCCKChatFaceViewDelegate, LCCKLocationControllerDelegate>

@property (strong, nonatomic) Mp3Recorder *MP3;
@property (nonatomic, strong) UIView *inputBarBackgroundView; /**< 输入栏目背景视图 */
@property (strong, nonatomic) UIButton *voiceButton; /**< 切换录音模式按钮 */
@property (strong, nonatomic) UIButton *voiceRecordButton; /**< 录音按钮 */

@property (strong, nonatomic) UIButton *faceButton; /**< 表情按钮 */
@property (strong, nonatomic) UIButton *moreButton; /**< 更多按钮 */
@property (strong, nonatomic) LCCKChatFaceView *faceView; /**< 当前活跃的底部view,用来指向faceView */
@property (strong, nonatomic) LCCKChatMoreView *moreView; /**< 当前活跃的底部view,用来指向moreView */

@property (assign, nonatomic, readonly) CGFloat bottomHeight;
@property (strong, nonatomic, readonly) UIViewController *rootViewController;

@property (assign, nonatomic) CGRect keyboardFrame;

@property (strong, nonatomic) UITextView *textView;

@end

@implementation LCCKChatBar

#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)updateConstraints {
    [super updateConstraints];
    
    [self.inputBarBackgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.and.right.and.top.mas_equalTo(self);
        //        make.height.mas_equalTo(kLCCKChatBarMinHeight).priorityLow();
        make.bottom.mas_equalTo(self).priorityLow();
    }];
    
    [self.voiceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.inputBarBackgroundView.mas_left).with.offset(10);
        make.bottom.equalTo(self.inputBarBackgroundView.mas_bottom).with.offset(-kChatBarBottomOffset);
        make.width.equalTo(self.voiceButton.mas_height);
    }];
    
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.inputBarBackgroundView.mas_right).with.offset(-10);
        make.bottom.equalTo(self.inputBarBackgroundView.mas_bottom).with.offset(-kChatBarBottomOffset);
        make.width.equalTo(self.moreButton.mas_height);
    }];
    
    [self.faceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.moreButton.mas_left).with.offset(-10);
        make.bottom.equalTo(self.inputBarBackgroundView.mas_bottom).with.offset(-kChatBarBottomOffset);
        make.width.equalTo(self.faceButton.mas_height);
    }];
    
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.voiceButton.mas_right).with.offset(10);
        make.right.equalTo(self.faceButton.mas_left).with.offset(-10);
        make.top.equalTo(self.inputBarBackgroundView.mas_top).with.offset(kChatBarTextViewBottomOffset);
        make.bottom.equalTo(self.inputBarBackgroundView.mas_bottom).with.offset(-kChatBarTextViewBottomOffset);
    }];
    
    CGFloat offset = -5.f;
    [self.voiceRecordButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.textView).insets(UIEdgeInsetsMake(offset, offset, offset, offset));
    }];
}

//TODO:
- (void)makeTextViewConstraints {
    //    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    //    if ((orientation == UIDeviceOrientationLandscapeLeft) || (orientation == UIDeviceOrientationLandscapeRight)) {
    //        NSLog(@"Landscape Left or Right !");
    //        [self.textView mas_remakeConstraints:^(MASConstraintMaker *make) {
    //            CGFloat offset = kChatBarTextViewBottomOffset;
    //            make.edges.mas_equalTo(self).insets(UIEdgeInsetsMake(offset, offset, offset, offset));
    //        }];
    //    } else if (orientation == UIDeviceOrientationPortrait) {
    [self.textView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.voiceButton.mas_right).with.offset(10);
        make.right.equalTo(self.faceButton.mas_left).with.offset(-10);
        make.top.equalTo(self.inputBarBackgroundView.mas_top).with.offset(kChatBarTextViewBottomOffset);
        make.bottom.equalTo(self.inputBarBackgroundView.mas_bottom).with.offset(-kChatBarTextViewBottomOffset);
    }];
    //        NSLog(@"Landscape portrait!");
    //    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
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

- (void)textViewDidChange:(UITextView *)textView {
    [self textViewDidChange:textView shouldCacheText:YES];
}

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
    CGFloat textViewHeight = MAX(kLCCKChatBarTextViewFrameMinHeight, MIN(kLCCKChatBarTextViewFrameMaxHeight, textSize.height));
    [self.textView mas_updateConstraints:^(MASConstraintMaker *make) {
        CGFloat height = textViewHeight;
        make.height.mas_equalTo(height);
    }];
    [self.textView layoutIfNeeded];
    
    [self mas_updateConstraints:^(MASConstraintMaker *make) {
        if (self.keyboardFrame.size.height == 0) {
            make.bottom.mas_equalTo(self.superview);
        } else {
            make.bottom.mas_equalTo(self.superview).offset(-self.keyboardFrame.size.height);
        }
    }];
    [self layoutIfNeeded];
    if (textView.scrollEnabled) {
        if (textViewHeight == kLCCKChatBarTextViewFrameMaxHeight) {
            [textView setContentOffset:CGPointMake(0, textView.contentSize.height - textViewHeight) animated:YES];
        } else {
            [textView setContentOffset:CGPointZero animated:YES];
        }
    }
    [self chatBarConstraintsDidChange];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self sendImageMessage:image];
    [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - LCCKLocationControllerDelegate

- (void)cancelLocation {
    [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)sendLocation:(CLPlacemark *)placemark {
    [self cancelLocation];
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBar:sendLocation:locationText:)]) {
        [self.delegate chatBar:self sendLocation:placemark.location.coordinate locationText:placemark.name];
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
    NSLog(@"开始转换");
    [LCCKProgressHUD changeSubTitle:@"正在转换..."];
}

#pragma mark - LCCKChatMoreViewDelegate & LCCKChatMoreViewDataSource

- (void)moreView:(LCCKChatMoreView *)moreView selectIndex:(LCCKChatMoreItemType)itemType {
    switch (itemType) {
        case LCCKChatMoreItemAlbum: {
            //显示相册
            UIImagePickerController *pickerC = [[UIImagePickerController alloc] init];
            pickerC.delegate = self;
            [self.rootViewController presentViewController:pickerC animated:YES completion:nil];
        }
            break;
        case LCCKChatMoreItemCamera: {
            //显示拍照
            if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                LCCKShowNotificationBlock showNotificationBlock = [LCCKUIService sharedInstance].showNotificationBlock;
                id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
                UIWindow *window = delegate.window;
                !showNotificationBlock ?: showNotificationBlock(window.rootViewController, @"您的设备不支持拍照", nil, LCCKMessageNotificationTypeError);
                break;
            }
            
            UIImagePickerController *pickerC = [[UIImagePickerController alloc] init];
            pickerC.sourceType = UIImagePickerControllerSourceTypeCamera;
            pickerC.delegate = self;
            [self.rootViewController presentViewController:pickerC animated:YES completion:nil];
        }
            break;
        case LCCKChatMoreItemLocation: {
            //显示地理位置
            LCCKLocationController *locationC = [[LCCKLocationController alloc] init];
            locationC.delegate = self;
            UINavigationController *locationNav = [[UINavigationController alloc] initWithRootViewController:locationC];
            [self.rootViewController presentViewController:locationNav animated:YES completion:nil];
        }
            break;
        default:
            break;
    }
}

- (NSArray *)titlesOfMoreView:(LCCKChatMoreView *)moreView {
    return @[ @"拍摄",@"照片",@"位置" ];
}

- (NSArray<NSString *> *)imageNamesOfMoreView:(LCCKChatMoreView *)moreView {
    return @[
             @"chat_bar_icons_camera",
             @"chat_bar_icons_pic",
             @"chat_bar_icons_location"
             ];
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
        self.cachedText = @"";
        self.textView.text = @"";
        [self chatBarConstraintsDidChange];
        [self showViewWithType:LCCKFunctionViewShowFace];
    } else {
        [self appendString:faceName beginInputing:NO];
    }
}

#pragma mark - Public Methods

- (void)endInputing {
    if (self.voiceButton.selected) {
        return;
    }
    self.faceButton.selected = self.moreButton.selected = self.voiceButton.selected = NO;
    
    [self showViewWithType:LCCKFunctionViewShowNothing];
}

- (void)appendString:(NSString *)string beginInputing:(BOOL)beginInputing {
    self.textView.text = [self.textView.text stringByAppendingString:string];
    [self textViewDidChange:self.textView];
    if (beginInputing) {
        [self beginInputing];
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
    self.keyboardFrame = CGRectZero;
    [self textViewDidChange:self.textView shouldCacheText:NO];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    self.keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self textViewDidChange:self.textView shouldCacheText:NO];
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
    //    void (^deviceOrientationDidChangeBlock)(NSNotification *) = ^(NSNotification *notification) {
    //        [self makeTextViewConstraints];
    //    };
    //    [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
    //                                                      object:nil
    //                                                       queue:[NSOperationQueue mainQueue]
    //                                                  usingBlock:deviceOrientationDidChangeBlock];
    
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
    
    self.backgroundColor = [UIColor colorWithRed:235/255.0f green:236/255.0f blue:238/255.0f alpha:1.0f];
    
    [self updateConstraintsIfNeeded];
    
    //FIX 修复首次初始化页面 页面显示不正确, textView 不显示bug
    [self layoutIfNeeded];
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

- (void)showViewWithType:(LCCKFunctionViewShowType)showType {
    //显示对应的View
    [self showMoreView:showType == LCCKFunctionViewShowMore && self.moreButton.selected];
    [self showVoiceView:showType == LCCKFunctionViewShowVoice && self.voiceButton.selected];
    [self showFaceView:showType == LCCKFunctionViewShowFace && self.faceButton.selected];
    [self chatBarConstraintsDidChange];
    
    switch (showType) {
        case LCCKFunctionViewShowNothing: {
            self.textView.text = self.cachedText;
            //            self.textView.contentOffset = CGPointZero;
            [self textViewDidChange:self.textView];
            [self.textView resignFirstResponder];
        }
            break;
        case LCCKFunctionViewShowVoice: {
            self.cachedText = self.textView.text;
            self.textView.text = nil;
            //            self.textView.contentOffset = CGPointZero;
            [self.textView resignFirstResponder];
            //            [self chatBarConstraintsDidChange];
            [self textViewDidChange:self.textView shouldCacheText:NO];
        }
            break;
        case LCCKFunctionViewShowMore:
        case LCCKFunctionViewShowFace:
            self.textView.text = self.cachedText;
            [self.textView resignFirstResponder];
            [self textViewDidChange:self.textView];
            break;
        case LCCKFunctionViewShowKeyboard:
            self.textView.text = self.cachedText;
            [self textViewDidChange:self.textView];
            break;
    }
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
        [self.textView becomeFirstResponder];
    }
    
    [self showViewWithType:showType];
}

- (void)showFaceView:(BOOL)show {
    if (show) {
        [self addSubview:self.faceView];
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
        [self.inputBarBackgroundView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.faceView.mas_top);
        }];
        [UIView animateWithDuration:LCCKAnimateDuration animations:^{
            // [self.faceView setFrame:CGRectMake(0, self.superViewHeight - kFunctionViewHeight, self.frame.size.width, kFunctionViewHeight)];
            [self.faceView layoutIfNeeded];
            //            [self.inputBarBackgroundView layoutIfNeeded];
        } completion:nil];
    } else if (self.faceView.superview) {
        //        [self.faceView layoutIfNeeded];
        //        [self.faceView mas_updateConstraints:^(MASConstraintMaker *make) {
        //            make.top.mas_equalTo(self.superview.mas_bottom);
        //        }];
        [UIView animateWithDuration:LCCKAnimateDuration animations:^{
            // [self.faceView setFrame:CGRectMake(0, self.superViewHeight, self.frame.size.width, kFunctionViewHeight)];
            //                        [self.faceView layoutIfNeeded];
            [self.faceView removeFromSuperview];
        } completion:^(BOOL finished) {
        }];
    }
}

/**
 *  显示moreView
 *  @param show 要显示的moreView
 */
- (void)showMoreView:(BOOL)show {
    if (show) {
        [self addSubview:self.moreView];
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
        [self.inputBarBackgroundView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.moreView.mas_top);
        }];
        [UIView animateWithDuration:LCCKAnimateDuration animations:^{
            //            [self.moreView setFrame:CGRectMake(0, self.superViewHeight - kFunctionViewHeight, self.frame.size.width, kFunctionViewHeight)];
            [self.moreView layoutIfNeeded];
            //            [self.inputBarBackgroundView layoutIfNeeded];
            // [self.inputBarBackgroundView layoutIfNeeded];
        } completion:nil];
    } else if (self.moreView.superview) {
        // [self.moreView layoutIfNeeded];
        // [self.moreView mas_updateConstraints:^(MASConstraintMaker *make) {
        // make.top.mas_equalTo(self.superview.mas_bottom);
        // }];
        [UIView animateWithDuration:LCCKAnimateDuration animations:^{
            // [self.moreView setFrame:CGRectMake(0, self.superViewHeight, self.frame.size.width, kFunctionViewHeight)];
            // [self.moreView layoutIfNeeded];
            // [self.moreView layoutIfNeeded];
            [self.moreView removeFromSuperview];
        } completion:^(BOOL finished) {
        }];
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
    if (!text || text.length == 0) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBar:sendMessage:)]) {
        [self.delegate chatBar:self sendMessage:text];
    }
    self.cachedText = @"";
    self.textView.text = @"";
    [self chatBarConstraintsDidChange];
    [self showViewWithType:LCCKFunctionViewShowKeyboard];
}

/**
 *  通知代理发送语音信息
 *
 *  @param voiceData 发送的语音信息data
 *  @param seconds   语音时长
 */
- (void)sendVoiceMessage:(NSString *)voiceFileName seconds:(NSTimeInterval)seconds{
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBar:sendVoice:seconds:)]) {
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

- (void)chatBarConstraintsDidChange {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBarFrameDidChange:)]) {
        [self.delegate chatBarFrameDidChange:self];
    }
}

- (UIImage *)imageInBundlePathForImageName:(NSString *)imageName {
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
    return image;
}

#pragma mark - Getters

- (LCCKChatFaceView *)faceView {
    if (!_faceView) {
        _faceView = [[LCCKChatFaceView alloc] init];
        _faceView.delegate = self;
        _faceView.backgroundColor = self.backgroundColor;
    }
    return _faceView;
}

- (LCCKChatMoreView *)moreView {
    if (!_moreView) {
        _moreView = [[LCCKChatMoreView alloc] init];
        _moreView.delegate = self;
        _moreView.dataSource = self;
        _moreView.backgroundColor = self.backgroundColor;
    }
    return _moreView;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.font = [UIFont systemFontOfSize:16.0f];
        _textView.delegate = self;
        _textView.layer.cornerRadius = 4.0f;
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

- (CGFloat)bottomHeight{
    if (self.faceView.superview || self.moreView.superview) {
        return MAX(self.keyboardFrame.size.height, MAX(self.faceView.frame.size.height, self.moreView.frame.size.height));
    } else {
        return MAX(self.keyboardFrame.size.height, CGFLOAT_MIN);
    }
}

- (UIViewController *)rootViewController {
    return [[UIApplication sharedApplication] keyWindow].rootViewController;
}

@end
