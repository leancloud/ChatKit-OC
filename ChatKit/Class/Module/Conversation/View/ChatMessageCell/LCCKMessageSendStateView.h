//
//  LCCKMessageSendStateView.h
//  LCCKChatBarExample
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) ( https://github.com/leancloud/ChatKit-OC ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

@import UIKit;
@import Foundation;

@protocol LCCKSendImageViewDelegate <NSObject>
@required
- (void)resendMessage:(id)sender;
@end

#import "LCCKConstants.h"

@interface LCCKMessageSendStateView : UIButton

@property (nonatomic, assign) LCCKMessageSendState messageSendState;
@property (nonatomic, weak) id<LCCKSendImageViewDelegate> delegate;

@end
