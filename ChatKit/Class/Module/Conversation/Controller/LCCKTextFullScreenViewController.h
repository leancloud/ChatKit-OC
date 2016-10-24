//
//  LCCKTextFullScreenViewController.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/23.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKBaseViewController.h"
@class LCCKMessage;
typedef void (^LCCKRemoveFromWindowHandler)(void);
@interface LCCKTextFullScreenViewController : LCCKBaseViewController

@property (nonatomic, copy, readonly) NSString *text;

- (instancetype)initWithText:(NSString *)text;
- (void)setRemoveFromWindowHandler:(LCCKRemoveFromWindowHandler)removeFromWindowHandler;
@end
