//
//  XHDisplayTextViewController.m
//  MessageDisplayExample
//
//  Created by qtone-1 on 14-5-6.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507 本人QQ群（142557668）. All rights reserved.
//

#import "XHDisplayTextViewController.h"
#import "CYLDeallocBlockExecutor.h"

static void * const LCIMDisplayTextViewContentSizeContext = (void*)&LCIMDisplayTextViewContentSizeContext;

@interface XHDisplayTextViewController ()

@property (nonatomic, weak) UIView *backgroundView;

@property (nonatomic, weak) UITextView *displayTextView;

@end

@implementation XHDisplayTextViewController

- (UITextView *)displayTextView {
    if (!_displayTextView) {
        UITextView *displayTextView = [[UITextView alloc] initWithFrame:self.view.frame];
        displayTextView.font = [UIFont systemFontOfSize:30.0f];
        [displayTextView addObserver:self forKeyPath:@"contentSize" options:(NSKeyValueObservingOptionNew) context:LCIMDisplayTextViewContentSizeContext];
        __unsafe_unretained typeof(self) weakSelf = self;
        [self cyl_executeAtDealloc:^{
            [displayTextView removeObserver:weakSelf forKeyPath:@"contentSize"];
        }];
        displayTextView.contentSize = self.view.bounds.size;
        displayTextView.textAlignment = NSTextAlignmentCenter;
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
- (void)removeFromWindow:(UITapGestureRecognizer *)tapGestureRecognizer {
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)setMessage:(id<XHMessageModel>)message {
    _message = message;
    self.displayTextView.text = [message text];
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
    if(context != LCIMDisplayTextViewContentSizeContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if(context == LCIMDisplayTextViewContentSizeContext) {
        UITextView *textView = object;
        CGFloat topCorrect = ([textView bounds].size.height - [textView contentSize].height * [textView zoomScale])/2.0;
        topCorrect = ( topCorrect < 0.0 ? 0.0 : topCorrect );
        [textView setContentInset:UIEdgeInsetsMake(topCorrect,0,0,0)];
    }
}

@end
