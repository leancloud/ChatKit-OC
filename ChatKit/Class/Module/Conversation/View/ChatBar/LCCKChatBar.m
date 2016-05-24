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

@interface LCCKChatBar () <UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, Mp3RecorderDelegate,LCCKChatMoreViewDelegate, LCCKChatMoreViewDataSource, LCCKChatFaceViewDelegate, LCCKLocationControllerDelegate>

@property (strong, nonatomic) Mp3Recorder *MP3;
@property (strong, nonatomic) UIButton *voiceButton; /**< 切换录音模式按钮 */
@property (strong, nonatomic) UIButton *voiceRecordButton; /**< 录音按钮 */

@property (strong, nonatomic) UIButton *faceButton; /**< 表情按钮 */
@property (strong, nonatomic) UIButton *moreButton; /**< 更多按钮 */
@property (strong, nonatomic) LCCKChatFaceView *faceView; /**< 当前活跃的底部view,用来指向faceView */
@property (strong, nonatomic) LCCKChatMoreView *moreView; /**< 当前活跃的底部view,用来指向moreView */

@property (strong, nonatomic) UITextView *textView;

@property (assign, nonatomic, readonly) CGFloat bottomHeight;
@property (strong, nonatomic, readonly) UIViewController *rootViewController;

@property (assign, nonatomic) CGRect keyboardFrame;
@property (copy, nonatomic) NSString *inputText;

@end

@implementation LCCKChatBar

#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)updateConstraints{
    [super updateConstraints];
    [self.voiceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left).with.offset(10);
        make.top.equalTo(self.mas_top).with.offset(8);
        make.width.equalTo(self.voiceButton.mas_height);
    }];
    
    [self.moreButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.mas_right).with.offset(-10);
        make.top.equalTo(self.mas_top).with.offset(8);
        make.width.equalTo(self.moreButton.mas_height);
    }];
    
    [self.faceButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.moreButton.mas_left).with.offset(-10);
        make.top.equalTo(self.mas_top).with.offset(8);
        make.width.equalTo(self.faceButton.mas_height);
    }];
    
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.voiceButton.mas_right).with.offset(10);
        make.right.equalTo(self.faceButton.mas_left).with.offset(-10);
        make.top.equalTo(self.mas_top).with.offset(4);
        make.bottom.equalTo(self.mas_bottom).with.offset(-4);
    }];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    
    if ([text isEqualToString:@"\n"]) {
        [self sendTextMessage:textView.text];
        return NO;
    } else if (text.length == 0){
        //判断删除的文字是否符合表情文字规则
        NSString *deleteText = [textView.text substringWithRange:range];
        if ([deleteText isEqualToString:@"]"]) {
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
                if (([subText hasPrefix:@"["] && [subText hasSuffix:@"]"])) {
                    break;
                }
            }
            textView.text = [textView.text stringByReplacingCharactersInRange:NSMakeRange(location, length) withString:@""];
            [textView setSelectedRange:NSMakeRange(location, 0)];
            [self textViewDidChange:self.textView];
            return NO;
        }
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
    CGRect textViewFrame = self.textView.frame;
    CGSize textSize = [self.textView sizeThatFits:CGSizeMake(CGRectGetWidth(textViewFrame), 1000.0f)];
    CGFloat offset = 10;
    textView.scrollEnabled = (textSize.height + 0.1 > kLCCKChatBarMaxHeight-offset);
    textViewFrame.size.height = MAX(34, MIN(kLCCKChatBarMaxHeight, textSize.height));
    CGRect addBarFrame = self.frame;
    addBarFrame.size.height = textViewFrame.size.height+offset;
    addBarFrame.origin.y = self.superViewHeight - self.bottomHeight - addBarFrame.size.height;
    [self setFrame:addBarFrame animated:NO];
    if (textView.scrollEnabled) {
        [textView scrollRangeToVisible:NSMakeRange(textView.text.length - 2, 1)];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
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

- (void)sendLocation:(CLPlacemark *)placemark{
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

- (void)failRecord{
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
                !showNotificationBlock ?: showNotificationBlock(self, @"您的设备不支持拍照", nil, LCCKMessageNotificationTypeError);
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
    return @[@"chat_bar_icons_camera", @"chat_bar_icons_pic", @"chat_bar_icons_location"];
}

#pragma mark - LCCKChatFaceViewDelegate

- (void)faceViewSendFace:(NSString *)faceName {
    if ([faceName isEqualToString:@"[删除]"]) {
        [self textView:self.textView shouldChangeTextInRange:NSMakeRange(self.textView.text.length - 1, 1) replacementText:@""];
    } else if ([faceName isEqualToString:@"发送"]){
        NSString *text = self.textView.text;
        if (!text || text.length == 0) {
            return;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(chatBar:sendMessage:)]) {
            [self.delegate chatBar:self sendMessage:text];
        }
        self.inputText = @"";
        self.textView.text = @"";
        [self setFrame:CGRectMake(0, self.superViewHeight - self.bottomHeight - kLCCKChatBarMinHeight, self.frame.size.width, kLCCKChatBarMinHeight) animated:NO];
        [self showViewWithType:LCCKFunctionViewShowFace];
    } else {
        self.textView.text = [self.textView.text stringByAppendingString:faceName];
        [self textViewDidChange:self.textView];
    }
}

#pragma mark - Public Methods

- (void)endInputing {
    [self showViewWithType:LCCKFunctionViewShowNothing];
}

#pragma mark - Private Methods

- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardFrame = CGRectZero;
    [self textViewDidChange:self.textView];
}

- (void)keyboardFrameWillChange:(NSNotification *)notification {
    self.keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self textViewDidChange:self.textView];
}

- (void)setup {
    
    self.MP3 = [[Mp3Recorder alloc] initWithDelegate:self];
    [self addSubview:self.voiceButton];
    [self addSubview:self.moreButton];
    [self addSubview:self.faceButton];
    [self addSubview:self.textView];
    [self.textView addSubview:self.voiceRecordButton];
    UIImageView *topLine = [[UIImageView alloc] init];
    topLine.backgroundColor = [UIColor colorWithRed:184/255.0f green:184/255.0f blue:184/255.0f alpha:1.0f];
    [self addSubview:topLine];
    
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.top.equalTo(self.mas_top);
        make.height.mas_equalTo(@.5f);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillShowNotification object:nil];
    
    self.backgroundColor = [UIColor colorWithRed:235/255.0f green:236/255.0f blue:238/255.0f alpha:1.0f];

    [self updateConstraintsIfNeeded];
    
    //FIX 修复首次初始化页面 页面显示不正确 textView不显示bug
    [self layoutIfNeeded];
}

/**
 *  开始录音
 */
- (void)startRecordVoice {
    [LCCKProgressHUD show];
    [self.MP3 startRecord];
}

/**
 *  取消录音
 */
- (void)cancelRecordVoice {
    [LCCKProgressHUD dismissWithMessage:@"取消录音"];
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
    
    switch (showType) {
        case LCCKFunctionViewShowNothing: {
            [self setFrame:CGRectMake(0, self.superViewHeight - kLCCKChatBarMinHeight, self.frame.size.width, kLCCKChatBarMinHeight) animated:NO];
            [self.textView resignFirstResponder];
        }
            break;
        case LCCKFunctionViewShowVoice: {
            self.inputText = self.textView.text;
            [self setFrame:CGRectMake(0, self.superViewHeight - kLCCKChatBarMinHeight, self.frame.size.width, kLCCKChatBarMinHeight) animated:NO];
            [self.textView resignFirstResponder];
        }
            break;
        case LCCKFunctionViewShowMore:
        case LCCKFunctionViewShowFace:
            self.inputText = self.textView.text;
            [self setFrame:CGRectMake(0, self.superViewHeight - kFunctionViewHeight - self.textView.frame.size.height - 10, self.frame.size.width, self.textView.frame.size.height + 10) animated:NO];
            [self.textView resignFirstResponder];
            [self textViewDidChange:self.textView];
            break;
        case LCCKFunctionViewShowKeyboard:
            self.textView.text = self.inputText;
            [self textViewDidChange:self.textView];
            self.inputText = nil;
            break;
    }
}

- (void)buttonAction:(UIButton *)button {
    self.inputText = self.textView.text;
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
    } else {
        self.inputText = self.textView.text;
    }
    
    [self showViewWithType:showType];
}

- (void)showFaceView:(BOOL)show {
    if (show) {
        [self.superview addSubview:self.faceView];
        [UIView animateWithDuration:.3 animations:^{
            [self.faceView setFrame:CGRectMake(0, self.superViewHeight - kFunctionViewHeight, self.frame.size.width, kFunctionViewHeight)];
        } completion:nil];
    } else {
        [UIView animateWithDuration:.3 animations:^{
            [self.faceView setFrame:CGRectMake(0, self.superViewHeight, self.frame.size.width, kFunctionViewHeight)];
        } completion:^(BOOL finished) {
            [self.faceView removeFromSuperview];
        }];
    }
}

/**
 *  显示moreView
 *  @param show 要显示的moreView
 */
- (void)showMoreView:(BOOL)show {
    if (show) {
        [self.superview addSubview:self.moreView];
        [UIView animateWithDuration:.3 animations:^{
            [self.moreView setFrame:CGRectMake(0, self.superViewHeight - kFunctionViewHeight, self.frame.size.width, kFunctionViewHeight)];
        } completion:nil];
    } else {
        [UIView animateWithDuration:.3 animations:^{
            [self.moreView setFrame:CGRectMake(0, self.superViewHeight, self.frame.size.width, kFunctionViewHeight)];
        } completion:^(BOOL finished) {
            [self.moreView removeFromSuperview];
        }];
    }
}

- (void)showVoiceView:(BOOL)show {
    self.voiceButton.selected = show;
    self.voiceRecordButton.selected = show;
    self.voiceRecordButton.hidden = !show;
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
    self.inputText = @"";
    self.textView.text = @"";
    [self setFrame:CGRectMake(0, self.superViewHeight - self.bottomHeight - kLCCKChatBarMinHeight, self.frame.size.width, kLCCKChatBarMinHeight) animated:NO];
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

#pragma mark - Getters

- (LCCKChatFaceView *)faceView {
    if (!_faceView) {
        _faceView = [[LCCKChatFaceView alloc] initWithFrame:CGRectMake(0, self.superViewHeight , self.frame.size.width, kFunctionViewHeight)];
        _faceView.delegate = self;
        _faceView.backgroundColor = self.backgroundColor;
    }
    return _faceView;
}

- (LCCKChatMoreView *)moreView {
    if (!_moreView) {
        _moreView = [[LCCKChatMoreView alloc] initWithFrame:CGRectMake(0, self.superViewHeight, self.frame.size.width, kFunctionViewHeight)];
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
        [_voiceRecordButton setBackgroundColor:[UIColor lightGrayColor]];
        _voiceRecordButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
        [_voiceRecordButton setTitle:@"按住录音" forState:UIControlStateNormal];
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
        [_moreButton setBackgroundImage:[self imageInBundlePathForImageName:@"ToolViewKeyboard"] forState:UIControlStateSelected];
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

- (UIViewController *)rootViewController{
    return [[UIApplication sharedApplication] keyWindow].rootViewController;
}

#pragma mark - Getters

- (void)setFrame:(CGRect)frame animated:(BOOL)animated{
    if (animated) {
        [UIView animateWithDuration:.3 animations:^{
            [self setFrame:frame];
        }];
    } else {
        [self setFrame:frame];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatBarFrameDidChange:frame:)]) {
        [self.delegate chatBarFrameDidChange:self frame:frame];
    }
}

- (UIImage *)imageInBundlePathForImageName:(NSString *)imageName {
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
    return image;
}

@end
