//
//  LCCKMessageSendStateView.h
//  LCCKChatBarExample
//
//  v0.8.5 Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol LCCKSendImageViewDelegate <NSObject>
@required
- (void)resendMessage:(id)sender;
@end

#import "LCCKConstants.h"

@interface LCCKMessageSendStateView : UIButton

@property (nonatomic, assign) LCCKMessageSendState messageSendState;
@property (nonatomic, weak) id<LCCKSendImageViewDelegate> delegate;

@end
