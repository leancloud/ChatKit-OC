//
//  LCCKInputViewPlugin.h
//  Pods
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/7/19.
//
//

@import Foundation;
@import UIKit;
@class LCCKChatBar;
@class LCCKConversationViewController;

#import "LCCKConstants.h"

@protocol LCCKInputViewPluginSubclassing <NSObject>
@required

/*!
 子类实现此方法用于返回该类对应的消息类型
 @return 消息类型
 */
+ (LCCKInputViewPluginType)classPluginType;

@end

@protocol LCCKInputViewPluginDelegate <NSObject>
@required

/*!
 * 加载该插件的inputView
 */
@property (nonatomic, weak) LCCKChatBar *inputViewRef;

/*!
 * 插件图标
 */
@property (nonatomic, readonly, strong) UIImage  *pluginIconImage;

/*!
 * 插件名称
 */
@property (nonatomic, readonly, copy) NSString *pluginTitle;

/*!
 * 插件对应的 view，会被加载到 inputView 上
 */
@property (nonatomic, readonly, strong) UIView *pluginContentView;

@property (nonatomic, weak) id<LCCKInputViewPluginDelegate> delegate;

/*!
 * 发送自定消息的实现
 */
@property (nonatomic, copy) LCCKIdResultBlock sendCustomMessageHandler;

/*!
 * 插件被选中运行
 */
- (void)pluginDidClicked;

@end

@interface LCCKInputViewPlugin : UIControl <LCCKInputViewPluginDelegate>

/*!
 * 插件类型，用来向对方发送当前用户正在做的操作，例如正在拍照或者正在选择地理位置，详见 LCCKInputViewPluginType 的定义
 */
@property (nonatomic, readonly) LCCKInputViewPluginType pluginType;
@property (nonatomic, readonly) LCCKConversationViewController *conversationViewController;

- (void)fillWithPluginTitle:(NSString *)pluginTitle
                    pluginIconImage:(UIImage *)pluginIconImage;

+ (void)registerSubclass;

+ (void)registerCustomInputViewPlugin;

@end