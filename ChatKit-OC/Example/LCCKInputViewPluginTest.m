//
//  LCCKInputViewPluginTest.m
//  ChatKit-OC
//
//  Created by 都基鹏 on 16/8/16.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKInputViewPluginTest.h"
#import "RedpacketDemoViewController.h"

@interface LCCKInputViewPluginTest()

@property (nonatomic, copy) LCCKIdResultBlock sendCustomMessageHandler;

@end
@implementation LCCKInputViewPluginTest
@synthesize inputViewRef = _inputViewRef;
@synthesize sendCustomMessageHandler = _sendCustomMessageHandler;
+ (void)load {
    [self registerSubclass];
}

+ (LCCKInputViewPluginType)classPluginType {
    return 2;
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
    return @"红包";
}

/*!
 * 插件对应的 view，会被加载到 inputView 上
 */
- (UIView *)pluginContentView {
    return nil;
}

- (void)pluginDidClicked {
    [super pluginDidClicked];

    if ([self.conversationViewController isKindOfClass:[RedpacketDemoViewController class]]) {
        [(RedpacketDemoViewController*)self.conversationViewController chatBarWillSendRedPacket];
    }
}

- (LCCKIdResultBlock)sendCustomMessageHandler {
    if (_sendCustomMessageHandler) {
        return _sendCustomMessageHandler;
    }
    LCCKIdResultBlock sendCustomMessageHandler = ^(id object, NSError *error) {
        [self.conversationViewController dismissViewControllerAnimated:YES completion:nil];
        if (object) {
            UIImage *image = (UIImage *)object;
            [self.conversationViewController sendImageMessage:image];
        } else {
            LCCKLog(@"%@", error.description);
        }
        _sendCustomMessageHandler = nil;
    };
    _sendCustomMessageHandler = sendCustomMessageHandler;
    return sendCustomMessageHandler;
}

#pragma mark -
#pragma mark - Private Methods

- (UIImage *)imageInBundlePathForImageName:(NSString *)imageName {
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
    return image;
}

@end
