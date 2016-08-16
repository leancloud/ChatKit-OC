//
//  LCCKTextFullScreenViewController.h
//  LeanCloudChatKit-iOS
//
// v0.5.2 Created by 陈宜龙 on 16/3/23.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKBaseViewController.h"
@class LCCKMessage;
typedef void (^LCCKRemoveFromWindowHandler)(void);
@interface LCCKTextFullScreenViewController : LCCKBaseViewController

@property (nonatomic, copy, readonly) NSString *text;

- (instancetype)initWithText:(NSString *)text;
- (void)setRemoveFromWindowHandler:(LCCKRemoveFromWindowHandler)removeFromWindowHandler;
@end
