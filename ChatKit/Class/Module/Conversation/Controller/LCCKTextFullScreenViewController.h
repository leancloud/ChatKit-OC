//
//  LCCKTextFullScreenViewController.h
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/23.
//  v0.5.0 Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKBaseViewController.h"
@class LCCKMessage;
typedef void (^LCCKRemoveFromWindowHandler)(void);
@interface LCCKTextFullScreenViewController : LCCKBaseViewController

@property (nonatomic, copy, readonly) NSString *text;

- (instancetype)initWithText:(NSString *)text;
- (void)setRemoveFromWindowHandler:(LCCKRemoveFromWindowHandler)removeFromWindowHandler;
@end
