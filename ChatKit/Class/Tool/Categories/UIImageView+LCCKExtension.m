//
//  UIImageView+LCCKExtension.m
//  LeanCloudChatKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/5/16.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "UIImageView+LCCKExtension.h"
#import <objc/runtime.h>
#import "LCCKDeallocBlockExecutor.h"

#pragma mark -
#pragma mark - Private Methods

@interface UIImage (__Privete_CornerRadius)

@property (nonatomic, assign) BOOL lcck_cornerRadius;
@end

@implementation UIImage (__Privete_CornerRadius)

- (BOOL)lcck_cornerRadius {
    NSNumber *lcck_cornerRadiusObject = objc_getAssociatedObject(self, @selector(lcck_cornerRadius));
    return [lcck_cornerRadiusObject boolValue];
}

- (void)setLcck_cornerRadius:(BOOL)lcck_cornerRadius {
    NSNumber *lcck_cornerRadiusObject = [NSNumber numberWithBool:lcck_cornerRadius];
    objc_setAssociatedObject(self, @selector(lcck_cornerRadius), lcck_cornerRadiusObject, OBJC_ASSOCIATION_ASSIGN);
};

@end


#pragma mark -
#pragma mark - Helper Class Method

@interface LCCKImageObserver : NSObject

@property (nonatomic, assign) UIImageView *originImageView;
@property (nonatomic, strong) UIImage *originImage;
@property (nonatomic, assign) CGFloat cornerRadius;

- (instancetype)initWithImageView:(UIImageView *)imageView;

@end

@implementation LCCKImageObserver

- (instancetype)initWithImageView:(UIImageView *)imageView{
    if (self = [super init]) {
        self.originImageView = imageView;
        [imageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
        [imageView addObserver:self forKeyPath:@"contentMode" options:NSKeyValueObservingOptionNew context:nil];
            __unsafe_unretained typeof(self) weakSelf = self;
            [self lcck_executeAtDealloc:^{
            [weakSelf.originImageView removeObserver:weakSelf forKeyPath:@"image"];
            [weakSelf.originImageView removeObserver:weakSelf forKeyPath:@"contentMode"];
                }];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString*, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"image"]) {
        UIImage *newImage = change[@"new"];
        if (![newImage isKindOfClass:[UIImage class]] || newImage.lcck_cornerRadius) {
            return;
        }
        [self updateImageView];
    }
    if ([keyPath isEqualToString:@"contentMode"]) {
        self.originImageView.image = self.originImage;
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    if (_cornerRadius == cornerRadius) {
        return;
    }
    _cornerRadius = cornerRadius;
    if (_cornerRadius > 0) {
        [self updateImageView];
    }
}

- (void)updateImageView {
    self.originImage = self.originImageView.image;
    if (!self.originImage) {
        return;
    }
    
    UIImage *image = nil;
    UIGraphicsBeginImageContextWithOptions(self.originImageView.bounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef currnetContext = UIGraphicsGetCurrentContext();
    if (currnetContext) {
        CGContextAddPath(currnetContext, [UIBezierPath bezierPathWithRoundedRect:self.originImageView.bounds cornerRadius:self.cornerRadius].CGPath);
        CGContextClip(currnetContext);
        [self.originImageView.layer renderInContext:currnetContext];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    if ([image isKindOfClass:[UIImage class]]) {
        image.lcck_cornerRadius = YES;
        self.originImageView.image = image;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateImageView];
        });
    }
}

@end


#pragma mark -
#pragma mark - public Methods

@implementation UIImageView (LCCKExtension)

- (CGFloat)lcck_cornerRadius {
    return [self lcck_imageObserver].cornerRadius;
}

- (void)setLcck_cornerRadius:(CGFloat)aliCornerRadius {
    [self lcck_imageObserver].cornerRadius = aliCornerRadius;
}

- (LCCKImageObserver *)lcck_imageObserver {
    LCCKImageObserver *imageObserver = objc_getAssociatedObject(self, @selector(imageObserver));
    if (!imageObserver) {
        imageObserver = [[LCCKImageObserver alloc] initWithImageView:self];
        objc_setAssociatedObject(self, @selector(imageObserver), imageObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return imageObserver;
}

@end
