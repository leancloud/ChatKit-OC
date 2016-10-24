//
//  LCCKTextFullScreenViewController.m
//  LeanCloudIMKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/23.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKTextFullScreenViewController.h"
#import "LCCKDeallocBlockExecutor.h"
#import "LCCKFaceManager.h"
#define kLCCKTextFont [UIFont systemFontOfSize:30.0f]
static void * const LCCKTextFullScreenViewContentSizeContext = (void*)&LCCKTextFullScreenViewContentSizeContext;

@interface LCCKTextFullScreenViewController()

@property (nonatomic, weak) UIView *backgroundView;
@property (nonatomic, weak) UITextView *displayTextView;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy, readonly) NSDictionary *textStyle;
@property (nonatomic, copy) LCCKRemoveFromWindowHandler removeFromWindowHandler;
@end

@implementation LCCKTextFullScreenViewController
@synthesize textStyle = _textStyle;

- (UITextView *)displayTextView {
    if (!_displayTextView) {
        UITextView *displayTextView = [[UITextView alloc] initWithFrame:self.view.frame];
        [displayTextView addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:LCCKTextFullScreenViewContentSizeContext];
        __unsafe_unretained typeof(self) weakSelf = self;
        [self lcck_executeAtDealloc:^{
            [displayTextView removeObserver:weakSelf forKeyPath:@"contentSize"];
        }];
        displayTextView.contentSize = self.view.bounds.size;
        displayTextView.textColor = [UIColor blackColor];
        displayTextView.editable = NO;
        displayTextView.backgroundColor = [UIColor whiteColor];
        displayTextView.dataDetectorTypes = UIDataDetectorTypeAll;
        displayTextView.textContainerInset = UIEdgeInsetsMake(0,20,0,20);
        [self.backgroundView addSubview:displayTextView];
        _displayTextView = displayTextView;
    }
    return _displayTextView;
}

- (NSDictionary *)textStyle {
    if (!_textStyle) {
        UIFont *font = kLCCKTextFont;
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentCenter;
        style.paragraphSpacing = 0.25 * font.lineHeight;
        style.hyphenationFactor = 1.0;
        _textStyle = @{NSFontAttributeName: font,
                       NSParagraphStyleAttributeName: style};
    }
    return _textStyle;
}
/**
 *  lazy load backgroundView
 *
 *  @return UIView
 */
- (UIView *)backgroundView {
    if (_backgroundView == nil) {
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.view.frame];
        backgroundView.backgroundColor = [UIColor blueColor];
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeFromWindow:)];
        [backgroundView addGestureRecognizer:recognizer];
        [self.view addSubview:backgroundView];
        _backgroundView = backgroundView;
    }
    return _backgroundView;
}

- (void)setRemoveFromWindowHandler:(LCCKRemoveFromWindowHandler)removeFromWindowHandler {
    _removeFromWindowHandler = removeFromWindowHandler;
}

- (void)removeFromWindow:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self.navigationController popViewControllerAnimated:NO];
    !_removeFromWindowHandler ?: _removeFromWindowHandler();
}

- (instancetype)initWithText:(NSString *)text {
    self = [super init];
    if (!self) {
        return nil;
    }
    _text = text;
    NSMutableAttributedString *attrS = [LCCKFaceManager emotionStrWithString:text];
    [attrS addAttributes:self.textStyle range:NSMakeRange(0, attrS.length)];
    self.displayTextView.attributedText = attrS;
    
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Life cycle

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != LCCKTextFullScreenViewContentSizeContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == LCCKTextFullScreenViewContentSizeContext) {
        UITextView *textView = object;
        CGFloat topCorrect = ([textView bounds].size.height - [textView contentSize].height * [textView zoomScale])/2.0;
        topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
        [textView setContentInset:UIEdgeInsetsMake(topCorrect,0,0,0)];
    }
}

@end
