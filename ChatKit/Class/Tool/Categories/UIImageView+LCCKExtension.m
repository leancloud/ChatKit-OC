//
//  UIImageView+LCCKExtension.m
//  LeanCloudChatKit-iOS
//
// v0.5.2 Created by 陈宜龙 on 16/5/16.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "UIImageView+LCCKExtension.h"
#import <objc/runtime.h>
#import "LCCKDeallocBlockExecutor.h"

const char kRadius;
const char kRoundingCorners;
const char kIsRounding;
const char kHadAddObserver;
const char kProcessedImage;

const char kBorderWidth;
const char kBorderColor;

static void * const LCCKUIImageViewExtensionContext = (void*)&LCCKUIImageViewExtensionContext;

@implementation UIImageView (LCCKExtension)

/**
 * @brief init the Rounding UIImageView, no off-screen-rendered
 */
- (instancetype)initWithRoundingRectImageView {
    self = [super init];
    if (self) {
        [self lcck_cornerRadiusRoundingRect];
    }
    return self;
}

/**
 * @brief init the UIImageView with cornerRadius, no off-screen-rendered
 */
- (instancetype)initWithCornerRadiusAdvance:(CGFloat)cornerRadius rectCornerType:(UIRectCorner)rectCornerType {
    self = [super init];
    if (self) {
        [self lcck_cornerRadiusAdvance:cornerRadius rectCornerType:rectCornerType];
    }
    return self;
}

/**
 * @brief attach border for UIImageView with width & color
 */
- (void)lcck_attachBorderWidth:(CGFloat)width color:(UIColor *)color {
    self.lcck_borderWidth = width;
    self.lcck_borderColor = color;
}

#pragma mark - Kernel

/**
 * @brief clip the cornerRadius with image, UIImageView must be setFrame before, no off-screen-rendered
 */
- (void)lcck_cornerRadiusWithImage:(UIImage *)image cornerRadius:(CGFloat)cornerRadius rectCornerType:(UIRectCorner)rectCornerType {
    CGSize size = self.bounds.size;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize cornerRadii = CGSizeMake(cornerRadius, cornerRadius);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    if (nil == UIGraphicsGetCurrentContext()) {
        return;
    }
    UIBezierPath *cornerPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:rectCornerType cornerRadii:cornerRadii];
    [cornerPath addClip];
    [image drawInRect:self.bounds];
    [self lcck_drawBorder:cornerPath];
    UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    objc_setAssociatedObject(processedImage, &kProcessedImage, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.image = processedImage;
}

/**
 * @brief clip the cornerRadius with image, draw the backgroundColor you want, UIImageView must be setFrame before, no off-screen-rendered, no Color Blended layers
 */
- (void)lcck_cornerRadiusWithImage:(UIImage *)image cornerRadius:(CGFloat)cornerRadius rectCornerType:(UIRectCorner)rectCornerType backgroundColor:(UIColor *)backgroundColor {
    CGSize size = self.bounds.size;
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize cornerRadii = CGSizeMake(cornerRadius, cornerRadius);
    
    UIGraphicsBeginImageContextWithOptions(size, YES, scale);
    if (nil == UIGraphicsGetCurrentContext()) {
        return;
    }
    UIBezierPath *cornerPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:rectCornerType cornerRadii:cornerRadii];
    UIBezierPath *backgroundRect = [UIBezierPath bezierPathWithRect:self.bounds];
    [backgroundColor setFill];
    [backgroundRect fill];
    [cornerPath addClip];
    [image drawInRect:self.bounds];
    [self lcck_drawBorder:cornerPath];
    UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    objc_setAssociatedObject(processedImage, &kProcessedImage, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.image = processedImage;
}

/**
 * @brief set cornerRadius for UIImageView, no off-screen-rendered
 */
- (void)lcck_cornerRadiusAdvance:(CGFloat)cornerRadius rectCornerType:(UIRectCorner)rectCornerType {
    self.lcck_radius = cornerRadius;
    self.lcck_roundingCorners = rectCornerType;
    self.lcck_isRounding = NO;
    
    if (!self.lcck_hadAddObserver) {
        [self addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:LCCKUIImageViewExtensionContext];
        __unsafe_unretained typeof(self) weakSelf = self;
        [self lcck_executeAtDealloc:^{
            if (weakSelf.lcck_hadAddObserver) {
                [weakSelf removeObserver:weakSelf forKeyPath:@"image"];
            }
        }];
        self.lcck_hadAddObserver = YES;
    }
}

/**
 * @brief become Rounding UIImageView, no off-screen-rendered
 */
- (void)lcck_cornerRadiusRoundingRect {
    self.lcck_isRounding = YES;
    
    if (!self.lcck_hadAddObserver) {
        [self addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:LCCKUIImageViewExtensionContext];
        __unsafe_unretained typeof(self) weakSelf = self;
        [self lcck_executeAtDealloc:^{
            if (weakSelf.lcck_hadAddObserver) {
                [weakSelf removeObserver:weakSelf forKeyPath:@"image"];
            }
        }];
        self.lcck_hadAddObserver = YES;
    }
}

#pragma mark - Private
- (void)lcck_drawBorder:(UIBezierPath *)path {
    if (0 != self.lcck_borderWidth && nil != self.lcck_borderColor) {
        [path setLineWidth:2 * self.lcck_borderWidth];
        [self.lcck_borderColor setStroke];
        [path stroke];
    }
}

- (void)lcck_validateFrame {
    if (self.frame.size.width == 0) {
        [self.class lcck_swizzleMethod:@selector(layoutSubviews) anotherMethod:@selector(lcck_layoutSubviews)];
    }
}

+ (void)lcck_swizzleMethod:(SEL)oneSel anotherMethod:(SEL)anotherSel {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method oneMethod = class_getInstanceMethod(self, oneSel);
        Method anotherMethod = class_getInstanceMethod(self, anotherSel);
        method_exchangeImplementations(oneMethod, anotherMethod);
    });
}

- (void)lcck_layoutSubviews {
    [super layoutSubviews];
    if (self.lcck_isRounding) {
        [self lcck_cornerRadiusWithImage:self.image cornerRadius:self.frame.size.width/2 rectCornerType:UIRectCornerAllCorners];
    } else if (0 != self.lcck_radius && 0 != self.lcck_roundingCorners && nil != self.image) {
        [self lcck_cornerRadiusWithImage:self.image cornerRadius:self.lcck_radius rectCornerType:self.lcck_roundingCorners];
    }
}

#pragma mark - KVO for .image
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(context != LCCKUIImageViewExtensionContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    if ((context == LCCKUIImageViewExtensionContext) && ([keyPath isEqualToString:@"image"])){
        UIImage *newImage = change[NSKeyValueChangeNewKey];
        if ([newImage isMemberOfClass:[NSNull class]]) {
            return;
        }
        
        if ([objc_getAssociatedObject(newImage, &kProcessedImage) intValue] == 1) {
            return;
        }
        [self lcck_validateFrame];
        if (self.lcck_isRounding) {
            [self lcck_cornerRadiusWithImage:newImage cornerRadius:self.frame.size.width/2 rectCornerType:UIRectCornerAllCorners];
        } else if (0 != self.lcck_radius && 0 != self.lcck_roundingCorners && nil != self.image) {
            [self lcck_cornerRadiusWithImage:newImage cornerRadius:self.lcck_radius rectCornerType:self.lcck_roundingCorners];
        }
    }
}

#pragma mark property
- (CGFloat)lcck_borderWidth {
    return [objc_getAssociatedObject(self, &kBorderWidth) floatValue];
}

- (void)setLcck_borderWidth:(CGFloat)borderWidth {
    objc_setAssociatedObject(self, &kBorderWidth, @(borderWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)lcck_borderColor {
    return objc_getAssociatedObject(self, &kBorderColor);
}

- (void)setLcck_borderColor:(UIColor *)borderColor {
    objc_setAssociatedObject(self, &kBorderColor, borderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)lcck_hadAddObserver {
    return [objc_getAssociatedObject(self, &kHadAddObserver) boolValue];
}

- (void)setLcck_hadAddObserver:(BOOL)hadAddObserver {
    objc_setAssociatedObject(self, &kHadAddObserver, @(hadAddObserver), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)lcck_isRounding {
    return [objc_getAssociatedObject(self, &kIsRounding) boolValue];
}

- (void)setLcck_isRounding:(BOOL)isRounding {
    objc_setAssociatedObject(self, &kIsRounding, @(isRounding), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIRectCorner)lcck_roundingCorners {
    return [objc_getAssociatedObject(self, &kRoundingCorners) unsignedLongValue];
}

- (void)setLcck_roundingCorners:(UIRectCorner)roundingCorners {
    objc_setAssociatedObject(self, &kRoundingCorners, @(roundingCorners), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)lcck_radius {
    return [objc_getAssociatedObject(self, &kRadius) floatValue];
}

- (void)setLcck_radius:(CGFloat)radius {
    objc_setAssociatedObject(self, &kRadius, @(radius), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
