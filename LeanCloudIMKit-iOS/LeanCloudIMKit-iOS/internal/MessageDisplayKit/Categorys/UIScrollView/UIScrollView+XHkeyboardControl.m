//
//  UIScrollView+XHkeyboardControl.m
//  MessageDisplayExample
//
//  Created by qtone-1 on 14-4-24.
//  Copyright (c) 2014年 曾宪华 开发团队(http://iyilunba.com ) 本人QQ:543413507 本人QQ群（142557668）. All rights reserved.
//

#import "UIScrollView+XHkeyboardControl.h"

#import <objc/runtime.h>

@interface UIScrollView (XHKetboradControl)

@property (nonatomic, assign) CGFloat previousKeyboardY;

@end

@implementation UIScrollView (XHkeyboardControl)

#pragma mark - Setters

- (UIView *)lcim_keyboardView {
    return objc_getAssociatedObject(self, @selector(lcim_keyboardView));
}

- (void)setLcim_keyboardView:(UIView *)lcim_keyboardView {
    objc_setAssociatedObject(self, @selector(lcim_keyboardView), lcim_keyboardView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (KeyboardWillBeDismissedBlock)lcim_keyboardWillBeDismissed {
    return objc_getAssociatedObject(self, @selector(lcim_keyboardWillBeDismissed));
}

- (void)setLcim_keyboardWillBeDismissed:(KeyboardWillBeDismissedBlock)lcim_keyboardWillBeDismissed {
    objc_setAssociatedObject(self, @selector(lcim_keyboardWillBeDismissed), lcim_keyboardWillBeDismissed, OBJC_ASSOCIATION_COPY);
}

- (KeyboardDidHideBlock)lcim_keyboardDidHide {
    return objc_getAssociatedObject(self, @selector(lcim_keyboardDidHide));
}

- (void)setLcim_keyboardDidHide:(KeyboardDidHideBlock)lcim_keyboardDidHide {
    objc_setAssociatedObject(self, @selector(lcim_keyboardDidHide), lcim_keyboardDidHide, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (KeyboardDidShowBlock)lcim_keyboardDidChange {
    return objc_getAssociatedObject(self, @selector(lcim_keyboardDidChange));
}

- (void)setLcim_keyboardDidChange:(KeyboardDidShowBlock)lcim_keyboardDidChange {
    objc_setAssociatedObject(self, @selector(lcim_keyboardDidChange), lcim_keyboardDidChange, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (KeyboardDidScrollToPointBlock)lcim_keyboardDidScrollToPoint {
    return objc_getAssociatedObject(self, @selector(lcim_keyboardDidScrollToPoint));
}

- (void)setLcim_keyboardDidScrollToPoint:(KeyboardDidScrollToPointBlock)lcim_keyboardDidScrollToPoint {
    objc_setAssociatedObject(self, @selector(lcim_keyboardDidScrollToPoint), lcim_keyboardDidScrollToPoint, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (KeyboardWillSnapBackToPointBlock)lcim_keyboardWillSnapBackToPoint {
    return objc_getAssociatedObject(self, @selector(lcim_keyboardWillSnapBackToPoint));
}

- (void)setLcim_keyboardWillSnapBackToPoint:(KeyboardWillSnapBackToPointBlock)lcim_keyboardWillSnapBackToPoint {
    objc_setAssociatedObject(self, @selector(lcim_keyboardWillSnapBackToPoint), lcim_keyboardWillSnapBackToPoint, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (KeyboardWillChangeBlock)lcim_keyboardWillChange {
    return objc_getAssociatedObject(self, @selector(lcim_keyboardWillChange));
}

- (void)setLcim_keyboardWillChange:(KeyboardWillChangeBlock)lcim_keyboardWillChange {
    objc_setAssociatedObject(self, @selector(lcim_keyboardWillChange), lcim_keyboardWillChange, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CGFloat)lcim_messageInputBarHeight {
    NSNumber *lcim_messageInputBarHeightObject = objc_getAssociatedObject(self, @selector(lcim_messageInputBarHeight));
    return [lcim_messageInputBarHeightObject floatValue];
}

- (void)setLcim_messageInputBarHeight:(CGFloat)lcim_messageInputBarHeight {
    NSNumber *lcim_messageInputBarHeightObject = [NSNumber numberWithBool:lcim_messageInputBarHeight];
    objc_setAssociatedObject(self, @selector(lcim_messageInputBarHeight), lcim_messageInputBarHeightObject, OBJC_ASSOCIATION_ASSIGN);
}

- (CGFloat)lcim_previousKeyboardY {
    NSNumber *lcim_previousKeyboardYObject = objc_getAssociatedObject(self, @selector(lcim_previousKeyboardY));
    return [lcim_previousKeyboardYObject floatValue];
}

- (void)setLcim_previousKeyboardY:(CGFloat)lcim_previousKeyboardY {
    NSNumber *lcim_previousKeyboardYObject = [NSNumber numberWithBool:lcim_previousKeyboardY];
    objc_setAssociatedObject(self, @selector(lcim_previousKeyboardY), lcim_previousKeyboardYObject, OBJC_ASSOCIATION_ASSIGN);
}

#pragma mark - Helper Method

+ (UIView *)lcim_findKeyboard {
    UIView *keyboardView = nil;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in [windows reverseObjectEnumerator])//逆序效率更高，因为键盘总在上方
    {
        keyboardView = [self lcim_findKeyboardInView:window];
        if (keyboardView)
        {
            return keyboardView;
        }
    }
    return nil;
}

+ (UIView *)lcim_findKeyboardInView:(UIView *)view {
    for (UIView *subView in [view subviews])
    {
        if (strstr(object_getClassName(subView), "UIKeyboard"))
        {
            return subView;
        }
        else
        {
            UIView *tempView = [self lcim_findKeyboardInView:subView];
            if (tempView)
            {
                return tempView;
            }
        }
    }
    return nil;
}

- (void)lcim_setupPanGestureControlKeyboardHide:(BOOL)isPanGestured {
    // 键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(lcim_handleWillShowKeyboardNotification:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(lcim_handleWillHideKeyboardNotification:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lcim_handleKeyboardWillShowHideNotification:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lcim_handleKeyboardWillShowHideNotification:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    if (isPanGestured)
        [self.panGestureRecognizer addTarget:self action:@selector(lcim_handlePanGesture:)];
}

- (void)lcim_disSetupPanGestureControlKeyboardHide:(BOOL)isPanGestured {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
    if (isPanGestured)
        [self.panGestureRecognizer removeTarget:self action:@selector(lcim_handlePanGesture:)];
}

#pragma mark - Gestures

- (void)lcim_handlePanGesture:(UIPanGestureRecognizer *)pan {
    if(!self.lcim_keyboardView || self.lcim_keyboardView.hidden)
        return;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    UIWindow *panWindow = [[UIApplication sharedApplication] keyWindow];
    CGPoint location = [pan locationInView:panWindow];
    location.y += self.lcim_messageInputBarHeight;
    CGPoint velocity = [pan velocityInView:panWindow];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            self.previousKeyboardY = self.lcim_keyboardView.frame.origin.y;
            break;
        case UIGestureRecognizerStateEnded:
            if(velocity.y > 0 && self.lcim_keyboardView.frame.origin.y > self.previousKeyboardY) {
                
                [UIView animateWithDuration:0.3
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     self.lcim_keyboardView.frame = CGRectMake(0.0f,
                                                                          screenHeight,
                                                                          self.lcim_keyboardView.frame.size.width,
                                                                          self.lcim_keyboardView.frame.size.height);
                                     
                                     if (self.lcim_keyboardWillBeDismissed) {
                                         self.lcim_keyboardWillBeDismissed();
                                     }
                                 }
                                 completion:^(BOOL finished) {
                                     self.lcim_keyboardView.hidden = YES;
                                     self.lcim_keyboardView.frame = CGRectMake(0.0f,
                                                                          self.previousKeyboardY,
                                                                          self.lcim_keyboardView.frame.size.width,
                                                                          self.lcim_keyboardView.frame.size.height);
                                     [self resignFirstResponder];
                                     
                                     if (self.lcim_keyboardDidHide) {
                                         self.lcim_keyboardDidHide();
                                     }
                                 }];
            }
            else { // gesture ended with no flick or a flick upwards, snap keyboard back to original position
                [UIView animateWithDuration:0.2
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     if (self.lcim_keyboardWillSnapBackToPoint) {
                                         self.lcim_keyboardWillSnapBackToPoint(CGPointMake(0.0f, self.previousKeyboardY));
                                     }
                                     
                                     self.lcim_keyboardView.frame = CGRectMake(0.0f,
                                                                          self.previousKeyboardY,
                                                                          self.lcim_keyboardView.frame.size.width,
                                                                          self.lcim_keyboardView.frame.size.height);
                                 }
                                 completion:NULL];
            }
            break;
            
            // gesture is currently panning, match keyboard y to touch y
        default:
            if(location.y > self.lcim_keyboardView.frame.origin.y || self.lcim_keyboardView.frame.origin.y != self.previousKeyboardY) {
                
                CGFloat newKeyboardY = self.previousKeyboardY + (location.y - self.previousKeyboardY);
                newKeyboardY = newKeyboardY < self.previousKeyboardY ? self.previousKeyboardY : newKeyboardY;
                newKeyboardY = newKeyboardY > screenHeight ? screenHeight : newKeyboardY;
                
                self.lcim_keyboardView.frame = CGRectMake(0.0f,
                                                     newKeyboardY,
                                                     self.lcim_keyboardView.frame.size.width,
                                                     self.lcim_keyboardView.frame.size.height);
                
                if (self.lcim_keyboardDidScrollToPoint) {
                    self.lcim_keyboardDidScrollToPoint(CGPointMake(0.0f, newKeyboardY));
                }
            }
            break;
    }
}

#pragma mark - Keyboard notifications

- (void)lcim_handleKeyboardWillShowHideNotification:(NSNotification *)notification {
    BOOL didShowed = YES;
    if([notification.name isEqualToString:UIKeyboardDidShowNotification]) {
        self.lcim_keyboardView = [UIScrollView lcim_findKeyboard].superview;
        self.lcim_keyboardView.hidden = NO;
        didShowed = YES;
    }
    else if([notification.name isEqualToString:UIKeyboardDidHideNotification]) {
        didShowed = NO;
        self.lcim_keyboardView.hidden = NO;
        [self resignFirstResponder];
    }
    if (self.lcim_keyboardDidChange) {
        self.lcim_keyboardDidChange(didShowed);
    }
}

- (void)lcim_handleWillShowKeyboardNotification:(NSNotification *)notification {
    self.lcim_keyboardView.hidden = NO;
    [self lcim_keyboardWillShowHide:notification];
}

- (void)lcim_handleWillHideKeyboardNotification:(NSNotification *)notification {
    [self lcim_keyboardWillShowHide:notification];
}

- (void)lcim_keyboardWillShowHide:(NSNotification *)notification {
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    if (self.lcim_keyboardWillChange) {
        self.lcim_keyboardWillChange(keyboardRect, [self lcim_animationOptionsForCurve:curve], duration, (([notification.name isEqualToString:UIKeyboardWillShowNotification]) ? YES : NO));
    }
}

- (UIViewAnimationOptions)lcim_animationOptionsForCurve:(UIViewAnimationCurve)curve {
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            return UIViewAnimationOptionCurveEaseInOut;
            
        case UIViewAnimationCurveEaseIn:
            return UIViewAnimationOptionCurveEaseIn;
            
        case UIViewAnimationCurveEaseOut:
            return UIViewAnimationOptionCurveEaseOut;
            
        case UIViewAnimationCurveLinear:
            return UIViewAnimationOptionCurveLinear;
            
        default:
            return kNilOptions;
    }
}

@end
