//
//  LCCKInputViewPluginVCard.h
//  ChatKit-OC
//
//  v0.6.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/8/12.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <ChatKit/LCChatKit.h>

@import UIKit;
@import Foundation;

static LCCKInputViewPluginType const LCCKInputViewPluginTypeVCard = 1;

@interface LCCKInputViewPluginVCard : LCCKInputViewPlugin<LCCKInputViewPluginSubclassing>

@property (nonatomic, weak) LCCKChatBar *inputViewRef;

@end
