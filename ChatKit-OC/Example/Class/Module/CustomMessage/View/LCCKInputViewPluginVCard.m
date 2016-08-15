//
//  LCCKInputViewPluginVCard.m
//  ChatKit-OC
//
//  Created by 陈宜龙 on 16/8/12.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKInputViewPluginVCard.h"
#import "LCCKVCardMessage.h"
#import "LCCKContactListViewController.h"
#import "LCCKContactManager.h"

@implementation LCCKInputViewPluginVCard
@synthesize inputViewRef = _inputViewRef;
@synthesize sendCustomMessageHandler = _sendCustomMessageHandler;

#pragma mark -
#pragma mark - LCCKInputViewPluginSubclassing Method

+ (void)load {
    [self registerCustomInputViewPlugin];
}

+ (LCCKInputViewPluginType)classPluginType {
    return LCCKInputViewPluginTypeVCard;
}

#pragma mark -
#pragma mark - LCCKInputViewPluginDelegate Method

/**
 * 插件图标
 */
- (UIImage *)pluginIconImage {
    return [self imageInBundlePathForImageName:@"chat_bar_icons_location"];
}

/**
 * 插件名称
 */
- (NSString *)pluginTitle {
    return @"名片";
}

/**
 * 插件对应的 view，会被加载到 inputView 上
 */
- (UIView *)pluginContentView {
    return nil;
}

- (void)pluginDidClicked {
    [super pluginDidClicked];
    [self presentSelectMemberViewController];
}

- (void)presentSelectMemberViewController {
    AVIMConversation *conversation = self.conversationViewController.conversation;
    NSArray *allPersonIds;
    if (conversation.lcck_type == LCCKConversationTypeSingle) {
        allPersonIds = [[LCCKContactManager defaultManager] fetchContactPeerIds];
    } else {
        allPersonIds = conversation.members;
    }
    NSArray *users = [[LCChatKit sharedInstance] getCachedProfilesIfExists:allPersonIds shouldSameCount:YES error:nil];
    NSString *currentClientID = [[LCChatKit sharedInstance] clientId];
    LCCKContactListViewController *contactListViewController = [[LCCKContactListViewController alloc] initWithContacts:users userIds:allPersonIds excludedUserIds:@[currentClientID] mode:LCCKContactListModeSingleSelection];
    contactListViewController.title = @"发送名片";
    [contactListViewController setViewDidDismissBlock:^(LCCKBaseViewController *viewController) {
        [self.inputViewRef open];
        [self.inputViewRef beginInputing];
    }];
    [contactListViewController setSelectedContactCallback:^(UIViewController *viewController, NSString *peerId) {
        [viewController dismissViewControllerAnimated:YES completion:^{
            [self.inputViewRef open];
        }];
        if (peerId.length > 0) {
            !self.sendCustomMessageHandler ?: self.sendCustomMessageHandler(peerId, nil);
        }
    }];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:contactListViewController];
    [self.conversationViewController presentViewController:navigationController animated:YES completion:^{
        [self.inputViewRef close];
    }];
}

- (LCCKIdResultBlock)sendCustomMessageHandler {
    if (_sendCustomMessageHandler) {
        return _sendCustomMessageHandler;
    }
    LCCKIdResultBlock sendCustomMessageHandler = ^(id object, NSError *error) {
        LCCKVCardMessage *vCardMessage = [LCCKVCardMessage vCardMessageWithClientId:object];
        [self.conversationViewController sendCustomMessage:vCardMessage progressBlock:^(NSInteger percentDone) {
        } success:^(BOOL succeeded, NSError *error) {
            [self.conversationViewController sendLocalFeedbackTextMessge:@"名片发送成功"];
        } failed:^(BOOL succeeded, NSError *error) {
            [self.conversationViewController sendLocalFeedbackTextMessge:@"名片发送失败"];
        }];
        //important: avoid retain cycle!
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
