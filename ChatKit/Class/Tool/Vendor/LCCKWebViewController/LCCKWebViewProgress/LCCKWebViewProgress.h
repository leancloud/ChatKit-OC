//
//  LCCKWebViewProgress.h
//
//  Created by Satoshi Aasano on 4/20/13.
//  Copyright (c) 2013 Satoshi Asano. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

#undef njk_weak
#if __has_feature(objc_arc_weak)
#define njk_weak weak
#else
#define njk_weak unsafe_unretained
#endif

extern const float LCCKInitialProgressValue;
extern const float LCCKInteractiveProgressValue;
extern const float LCCKFinalProgressValue;

typedef void (^LCCKWebViewProgressBlock)(float progress);
@protocol LCCKWebViewProgressDelegate;
@interface LCCKWebViewProgress : NSObject<UIWebViewDelegate>
@property (nonatomic, njk_weak) id<LCCKWebViewProgressDelegate>progressDelegate;
@property (nonatomic, njk_weak) id<UIWebViewDelegate>webViewProxyDelegate;
@property (nonatomic, copy) LCCKWebViewProgressBlock progressBlock;
@property (nonatomic, readonly) float progress; // 0.0..1.0

- (void)reset;
@end

@protocol LCCKWebViewProgressDelegate <NSObject>
- (void)webViewProgress:(LCCKWebViewProgress *)webViewProgress updateProgress:(float)progress;
@end

