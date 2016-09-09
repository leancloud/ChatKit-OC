//
//  RedPacketChangeInputViewPlugin.m
//  ChatKit-OC
//
//  Created by 都基鹏 on 16/9/9.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "RedPacketChangeInputViewPlugin.h"
#import "RedpacketDemoViewController.h"
#import "RedpacketViewControl.h"

@interface RedPacketChangeInputViewPlugin()

@property (nonatomic, copy) LCCKIdResultBlock sendCustomMessageHandler;
@property (nonatomic, strong) RedpacketViewControl *redpacketControl;
@end
@implementation RedPacketChangeInputViewPlugin
@synthesize inputViewRef = _inputViewRef;
@synthesize sendCustomMessageHandler = _sendCustomMessageHandler;
+ (void)load {
    [self registerSubclass];
}

+ (LCCKInputViewPluginType)classPluginType {
    return 3;
}

#pragma mark -
#pragma mark - LCCKInputViewPluginDelegate Method

/*!
 * 插件图标
 */
- (UIImage *)pluginIconImage {
    return [self imageInBundlePathForImageName:@"chat_bar_icons_pic"];
}

/*!
 * 插件名称
 */
- (NSString *)pluginTitle {
    return @"零钱";
}

/*!
 * 插件对应的 view，会被加载到 inputView 上
 */
- (UIView *)pluginContentView {
    return nil;
}

- (void)pluginDidClicked {
    
    if ([self.conversationViewController isKindOfClass:[RedpacketDemoViewController class]]) {
        self.redpacketControl = [[RedpacketViewControl alloc] init];
        self.redpacketControl.conversationController = self.conversationViewController;
        [self.redpacketControl presentChangeMoneyViewController];
    }
}

#pragma mark -
#pragma mark - Private Methods

- (UIImage *)imageInBundlePathForImageName:(NSString *)imageName {
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
    return image;
}

@end
