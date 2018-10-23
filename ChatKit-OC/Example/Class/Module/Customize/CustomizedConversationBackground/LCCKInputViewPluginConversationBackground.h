//
//  LCCKInputViewPluginVCard.h
//  ChatKit-OC
//
//  v0.8.5 Created by ElonChan on 16/8/12.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

static LCCKInputViewPluginType const LCCKInputViewPluginTypeConversationBackground = 2;

@interface LCCKInputViewPluginConversationBackground : LCCKInputViewPlugin<LCCKInputViewPluginSubclassing>

@property (nonatomic, weak) LCCKChatBar *inputViewRef;

@end
