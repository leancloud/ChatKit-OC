//
//  LCCKInputViewPluginVCard.h
//  ChatKit-OC
//
//  Created by 陈宜龙 on 16/8/12.
//  v0.5.0 Copyright © 2016年 ElonChan. All rights reserved.
//

#import <ChatKit/LCChatKit.h>

@import UIKit;
@import Foundation;

static LCCKInputViewPluginType const LCCKInputViewPluginTypeVCard = 1;

@interface LCCKInputViewPluginVCard : LCCKInputViewPlugin<LCCKInputViewPluginSubclassing>

@property (nonatomic, weak) LCCKChatBar *inputViewRef;

@end
