//
//  LCCKInputViewPluginTakePhoto.h
//  Pods
//
//  v0.8.5 Created by ElonChan on 16/8/11.
//
//

#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

@interface LCCKInputViewPluginTakePhoto : LCCKInputViewPlugin<LCCKInputViewPluginSubclassing>

@property (nonatomic, weak) LCCKChatBar *inputViewRef;

@end
