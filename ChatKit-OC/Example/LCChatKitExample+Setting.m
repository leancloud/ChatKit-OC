//
//  LCChatKitExample.m
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/24.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKTabBarControllerConfig.h"
#import "LCCKUser.h"
#import "LCCKUtil.h"
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
#import "LCCKContactManager.h"
#import "LCCKExampleConstants.h"
#import "LCCKLoginViewController.h"
#import "LCChatKitExample+Setting.h"
//#import "MWPhotoBrowser.h"
#import "NSObject+LCCKHUD.h"
#import "LCCKGroupConversationDetailViewController.h"
#import "LCCKSingleConversationDetailViewController.h"

#define __OPTIMIZE__

@implementation LCChatKitExample (Setting)

- (void)lcck_setting {
    //设置用户体系
    [self lcck_setFetchProfiles];
    //设置签名机制
    //[self lcck_setGenerateSignature];
    //设置聊天列表
    [self lcck_setupConversationsList];
    //设置聊天
    [self lcck_setupConversation];
    // 其他各种设置
    [self lcck_setupOther];
    [self lcck_memberInfoChanged];
}

- (void)lcck_setupConversationsList {
    //设置最近联系人列表cell的操作
    [self lcck_setupConversationsCellOperation];
    //自定义Cell菜单
    [self lcck_setupConversationEditActionForConversationList];
}

- (void)lcck_setupConversation {
    //设置打开会话的操作
    [self lcck_setupOpenConversation];
    [self lcck_setupConversationInvalidedHandler];
    [self lcck_setupLoadLatestMessages];
    //点击图片，放大查看的设置。不设置则使用默认方式
    //[self lcck_setupPreviewImageMessage];
    [self lcck_setupLongPressMessage];
}

- (void)lcck_setupOther {
    //TabBar样式，自动设置。如果不是TabBar样式，再实现该方法
    //[self lcck_setupBadge];
    [self lcck_setupForceReconect];
    [self lcck_setupHud];
    [self lcck_setupOpenProfile];
    //开启圆角
    //[self lcck_setupAvatarImageCornerRadius];
    //筛选消息
    //[self lcck_setupFilterMessage];
    //发送消息HOOK
    //[self lcck_setupSendMessageHook];
    [self lcck_setupNotification];
    [self lcck_setupPreviewLocationMessage];
}

#pragma mark - 用户体系的设置
/**
 *  设置用户体系，里面要实现如何根据 userId 获取到一个 User 对象的逻辑。
 *  ChatKit 会在需要用到 User信息时调用设置的这个逻辑。
 */
- (void)lcck_setFetchProfiles {
#warning 注意：setFetchProfilesBlock 方法必须实现，如果不实现，ChatKit将无法显示用户头像、用户昵称。以下方法循环模拟了通过 userIds 同步查询 users 信息的过程，这里需要替换为 App 的 API 同步查询
    [[LCChatKit sharedInstance] setFetchProfilesBlock:^(NSArray<NSString *> *userIds,
                             LCCKFetchProfilesCompletionHandler completionHandler) {
         if (userIds.count == 0) {
             NSInteger code = 0;
             NSString *errorReasonText = @"User ids is nil";
             NSDictionary *errorInfo = @{
                                         @"code":@(code),
                                         NSLocalizedDescriptionKey : errorReasonText,
                                         };
             NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                                  code:code
                                              userInfo:errorInfo];
             
             !completionHandler ?: completionHandler(nil, error);
             return;
         }
         
         NSMutableArray *users = [NSMutableArray arrayWithCapacity:userIds.count];
#warning 注意：以下方法循环模拟了通过 userIds 同步查询 users 信息的过程，这里需要替换为 App 的 API 同步查询
         
         [userIds enumerateObjectsUsingBlock:^(NSString *_Nonnull clientId, NSUInteger idx,
                                               BOOL *_Nonnull stop) {
             NSPredicate *predicate = [NSPredicate predicateWithFormat:@"peerId like %@", clientId];
             //这里的LCCKContactProfiles，LCCKProfileKeyPeerId都为事先的宏定义，
             NSArray *searchedUsers = [LCCKContactProfiles filteredArrayUsingPredicate:predicate];
             if (searchedUsers.count > 0) {
                 NSDictionary *user = searchedUsers[0];
                 NSURL *avatarURL = [NSURL URLWithString:user[LCCKProfileKeyAvatarURL]];
                 LCCKUser *user_ = [LCCKUser userWithUserId:user[LCCKProfileKeyPeerId]
                                                       name:user[LCCKProfileKeyName]
                                                  avatarURL:avatarURL
                                                   clientId:clientId];
                 [users addObject:user_];
             } else {
                 //注意：如果网络请求失败，请至少提供 ClientId！
                 LCCKUser *user_ = [LCCKUser userWithClientId:clientId];
                 [users addObject:user_];
             }
         }];
        
#warning 重要：completionHandler 这个 Bock 必须执行，需要在你**获取到用户信息结束**后，将信息传给该Block！
         !completionHandler ?: completionHandler([users copy], nil);
     }];
}

#pragma mark - 签名机制设置

/*!
 * 参考 https://leancloud.cn/docs/realtime_v2.html#权限和认证
 * 需要使用同步请求
 */
//- (void)lcck_setGenerateSignature {
//    [[LCChatKit sharedInstance] setGenerateSignatureBlock:^(NSString *clientId, NSString     *conversationId, NSString *action, NSArray *clientIds, LCCKGenerateSignatureCompletionHandler completionHandler) {
//        NSMutableDictionary *paramsM = [NSMutableDictionary   dictionaryWithDictionary:@{@"token": [AccountManager sharedAccountManager].bestoneAccount.authentication_token}];
//        if (clientIds.count) {
//            [paramsM addEntriesFromDictionary:@{@"member_ids": clientIds}];
//        }
//        if (conversationId.length) {
//            [paramsM addEntriesFromDictionary:@{@"conversation_id": conversationId}];
//        }
//        if (action.length) {
//            [paramsM addEntriesFromDictionary:@{@"conv_action": action}];
//        }
//        
//        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
//        
//        __block AVIMSignature *signature_ = nil;
//        [HTTPSolution responseObjectWithMethod:@"GET" URLString:kSignatureURLStr parameters:[paramsM copy] wantData:NO success:^(NSURLResponse *response, id responseObject) {
//            signature_ = [[AVIMSignature alloc] init];
//            signature_.signature = responseObject[@"signature"];
//            signature_.timestamp = [responseObject[@"timestamp"] longLongValue];
//            signature_.nonce = responseObject[@"nonce"];
//            !completionHandler ?: completionHandler(signature_, nil);
//            LCCKLog(@"签名请求成功。。。。");
//            dispatch_semaphore_signal(semaphore);
//        } failure:^(NSError *error) {
//            
//            signature_ = [[AVIMSignature alloc] init];
//            signature_.error = error;
//            NSLog(@"error: %@", error.localizedDescription);
//            !completionHandler ?: completionHandler(signature_, error);
//            dispatch_semaphore_signal(semaphore);
//        }];
//        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//        LCCKLog(@"我在等待信号量增加！。。。。。");
//    }];
//}

#pragma mark - 最近联系人列表的设置

- (void)lcck_setupConversationEditActionForConversationList {
    // 自定义Cell菜单
    [[LCChatKit sharedInstance] setConversationEditActionBlock:^NSArray *(
                                               NSIndexPath *indexPath, NSArray<UITableViewRowAction *> *editActions,
                                               AVIMConversation *conversation, LCCKConversationListViewController *controller) {
         return [self lcck_exampleConversationEditActionAtIndexPath:indexPath
                                                       conversation:conversation
                                                         controller:controller];
     }];
}

/**
 *  设置联系人列表页面中，对cell的操作回调
 */
- (void)lcck_setupConversationsCellOperation { 
    //选中某个对话后的回调,设置事件响应函数
    [[LCChatKit sharedInstance] setDidSelectConversationsListCellBlock:^(
                                                                         NSIndexPath *indexPath, AVIMConversation *conversation,
                                                                         LCCKConversationListViewController *controller) {
        [[self class] exampleOpenConversationViewControllerWithConversaionId:conversation.conversationId
         fromNavigationController:controller.navigationController];
    }];
    //删除某个对话后的回调 (一般不需要做处理)
    [[LCChatKit sharedInstance] setDidDeleteConversationsListCellBlock:^(
                                                                         NSIndexPath *indexPath, AVIMConversation *conversation,
                                                                         LCCKConversationListViewController *controller){
        // TODO:
    }];
}

#pragma mark - 聊天页面的设置
/**
 *  打开一个会话的操作
 */
- (void)lcck_setupOpenConversation {
    [[LCChatKit sharedInstance] setFetchConversationHandler:^(
                                                              AVIMConversation *conversation,
                                                              LCCKConversationViewController *aConversationController) {
        if (!conversation.createAt) { //如果没有创建时间，直接return
            return;
        }
        [[self class] lcck_showMessage:@"加载历史记录..." toView:aConversationController.view];
        //判断会话的成员是否超过两个(即是否为群聊)
        if (conversation.members.count > 2) { //设置点击rightButton为群聊Style,和对应事件
            [aConversationController configureBarButtonItemStyle:LCCKBarButtonItemStyleGroupProfile
                                                          action:^(__kindof LCCKBaseViewController *viewController, UIBarButtonItem *sender, UIEvent *event) {
                                                              LCCKGroupConversationDetailViewController *groupConversationDetailViewController = [LCCKGroupConversationDetailViewController new];
                                                              groupConversationDetailViewController.conversation = conversation;
                                                              [viewController.navigationController pushViewController:groupConversationDetailViewController animated:YES];
                                                          }];
        } else if (conversation.members.count == 2) { //设置点击rightButton为单聊的Style,和对应事件
            [aConversationController
             configureBarButtonItemStyle:LCCKBarButtonItemStyleSingleProfile
             action:^(__kindof LCCKBaseViewController *viewController, UIBarButtonItem *sender, UIEvent *event) {
                 
             
//                 NSString *title = @"打开用户详情";
                 NSArray *members = conversation.members;
                 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", @[
                                                                                                  [LCChatKit sharedInstance].clientId
                                                                                                  ]];
                 NSString *peerId = [members filteredArrayUsingPredicate:predicate][0];
                 [[LCChatKit sharedInstance] getProfileInBackgroundForUserId:peerId callback:^(id<LCCKUserDelegate> user, NSError *error) {
                     LCCKSingleConversationDetailViewController *singleConversationDetailViewController = [LCCKSingleConversationDetailViewController new];
                     singleConversationDetailViewController.conversation = conversation;
                     [viewController.navigationController pushViewController:singleConversationDetailViewController animated:YES];
                 }];
             }];
        }
        //系统对话，或暂态聊天室，成员为0，单独处理。参考：系统对话文档
        // https://leancloud.cn/docs/realtime_v2.html#%E7%B3%BB%E7%BB%9F%E5%AF%B9%E8%AF%9D_System_Conversation_
    }];
}

/**
 *  设置会话出错的回调处理
 */
- (void)lcck_setupConversationInvalidedHandler {
    [[LCChatKit sharedInstance] setConversationInvalidedHandler:^(NSString *conversationId,
                                       LCCKConversationViewController *conversationController,
                                       id<LCCKUserDelegate> administrator, NSError *error) {
         NSString *title;
         NSString *subTitle;
         //错误码参考：https://leancloud.cn/docs/realtime_v2.html#%E4%BA%91%E7%AB%AF%E9%94%99%E8%AF%AF%E7%A0%81%E8%AF%B4%E6%98%8E
         if (error.code == 4401) {
             /**
              * 下列情景下会执行
              - 当前用户被踢出群，也会执行
              - 用户不在当前群中，且未开启 `enableAutoJoin` (自动进群)
              */
             [conversationController.navigationController popToRootViewControllerAnimated:YES];
             title = @"进群失败！";
             subTitle = [NSString stringWithFormat:@"请联系管理员%@",
                         administrator.name ?: administrator.clientId];
             LCCKLog(@"%@", error.description);
             [LCCKUtil showNotificationWithTitle:title
                                        subtitle:subTitle
                                            type:LCCKMessageNotificationTypeError];
         } else if (error.code == 4304) {
             [conversationController.navigationController popToRootViewControllerAnimated:YES];
             title = @"群已满，普通群人数上限为500";
             subTitle = @"暂态聊天室无人数限制";
             [LCCKUtil showNotificationWithTitle:title
                                        subtitle:subTitle
                                            type:LCCKMessageNotificationTypeError];
         }
     }];
}

/**
 *  加载最近聊天记录的回调
 */
- (void)lcck_setupLoadLatestMessages {
    [[LCChatKit sharedInstance]
setLoadLatestMessagesHandler:^(LCCKConversationViewController *conversationController,
                                    BOOL succeeded, NSError *error) {
         [[self class] lcck_hideHUDForView:conversationController.view];
         NSString *title;
         LCCKMessageNotificationType type;
         if (succeeded) {
             title = @"聊天记录加载成功";
             type = LCCKMessageNotificationTypeSuccess;
         } else {
             title = @"聊天记录加载失败";
             type = LCCKMessageNotificationTypeError;
         }
#ifndef __OPTIMIZE__
         [LCCKUtil showNotificationWithTitle:title subtitle:nil type:type];
#else
#endif
     }];
}

/**
 *  替换默认预览图片的样式设置，不设置则使用默认设置
 */
- (void)lcck_setupPreviewImageMessage {
    [[LCChatKit sharedInstance] setPreviewImageMessageBlock:^(NSUInteger index, NSArray *allVisibleImages,
                                   NSArray *allVisibleThumbs, NSDictionary *userInfo){
         //                        [self examplePreviewImageMessageWithInitialIndex:index
         //                        allVisibleImages:allVisibleImages
         //                        allVisibleThumbs:allVisibleThumbs];
     }];
}

/**
 *  设置会话界面的长按操作
 */
- (void)lcck_setupLongPressMessage
{
    [LCChatKit.sharedInstance setLongPressMessageBlock:^NSArray<LCCKMenuItem *> *(LCCKMessage *message, NSDictionary *userInfo) {
        
        AVIMMessageMediaType mediaType = message.mediaType;
        BOOL isNormalMediaTypeMessage = ({
            (mediaType == kAVIMMessageMediaTypeText ||
             mediaType == kAVIMMessageMediaTypeImage ||
             mediaType == kAVIMMessageMediaTypeAudio ||
             mediaType == kAVIMMessageMediaTypeVideo ||
             mediaType == kAVIMMessageMediaTypeLocation ||
             mediaType == kAVIMMessageMediaTypeFile);
        });
        LCCKMessageOwnerType ownerType = [userInfo[LCCKLongPressMessageUserInfoKeyMessageOwner] unsignedIntegerValue];
        LCCKConversationViewController *fromController = userInfo[LCCKLongPressMessageUserInfoKeyFromController];
        LCCKChatMessageCell *messageCell = userInfo[LCCKLongPressMessageUserInfoKeyMessageCell];
        
        NSMutableArray *menuItems = [NSMutableArray array];
        
        if (mediaType == kAVIMMessageMediaTypeText) {
            LCCKMenuItem *copyItem = [[LCCKMenuItem alloc] initWithTitle:LCCKLocalizedStrings(@"copy") block:^{
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                [pasteboard setString:[message text]];
            }];
            [menuItems addObject:copyItem];
            if (fromController && ownerType == LCCKMessageOwnerTypeSelf) {
                LCCKMenuItem *modifyItem = [[LCCKMenuItem alloc] initWithTitle:LCCKLocalizedStrings(@"modify") block:^{
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@?", LCCKLocalizedStrings(@"modify")] message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:LCCKLocalizedStrings(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
                    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                        textField.text = messageCell.message.text;
                    }];
                    UIAlertAction *modifyAction = [UIAlertAction actionWithTitle:LCCKLocalizedStrings(@"modify") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        LCCKMessage *oldMessage = messageCell.message;
                        LCCKMessage *newMessage = [[LCCKMessage alloc] initWithText:alert.textFields[0].text senderId:oldMessage.senderId sender:oldMessage.sender timestamp:oldMessage.timestamp serverMessageId:oldMessage.serverMessageId];
                        [fromController modifyMessage:messageCell newMessage:newMessage callback:^(BOOL succeeded, NSError *error) {
                            if (succeeded) {
                                LCCKLog(@"消息修改成功");
                            }
                        }];
                    }];
                    [alert addAction:modifyAction];
                    [fromController presentViewController:alert animated:true completion:nil];
                }];
                [menuItems addObject:modifyItem];
            }
        }
        
        if (fromController && isNormalMediaTypeMessage) {
            LCCKMenuItem *transpondItem = [[LCCKMenuItem alloc] initWithTitle:LCCKLocalizedStrings(@"transpond") block:^{
                [self lcck_transpondMessage:message toConversationViewController:fromController];
            }];
            [menuItems addObject:transpondItem];
        }
        
        if (fromController && ownerType == LCCKMessageOwnerTypeSelf && isNormalMediaTypeMessage) {
            LCCKMenuItem *recallItem = [[LCCKMenuItem alloc] initWithTitle:LCCKLocalizedStrings(@"recall") block:^{
                [fromController recallMessage:messageCell callback:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        LCCKLog(@"消息撤回成功");
                    }
                }];
            }];
            [menuItems addObject:recallItem];
        }
        
        return menuItems;
    }];
}

#pragma mark -  其他的设置
/**
 *  设置Badge
 */
- (void)lcck_setupBadge {
    //    TabBar样式，自动设置。如果不是TabBar样式，请实现该 Blcok 来设置 Badge 红标。
    [[LCChatKit sharedInstance] setMarkBadgeWithTotalUnreadCountBlock:^(
                                                                        NSInteger totalUnreadCount, UIViewController *controller) {
        [self lcck_exampleMarkBadgeWithTotalUnreadCount:totalUnreadCount controller:controller];
    }];
}

/**
 *  强制重连
 */
- (void)lcck_setupForceReconect {
    [[LCChatKit sharedInstance] setForceReconnectSessionBlock:
     ^(NSError *aError, BOOL granted, __kindof UIViewController *viewController, LCCKReconnectSessionCompletionHandler completionHandler) {
         
         BOOL isSingleSignOnOffline = (aError.code == 4111);
         
         if (isSingleSignOnOffline) {
             
             // - 用户允许重连请求，发起重连或强制登录
             if (granted == YES) {
                 
                 NSString *title = @"正在重连聊天服务...";
                 
                 // 从系统偏好读取用户已经保存的信息
                 NSUserDefaults *defaultsGet = [NSUserDefaults standardUserDefaults];
                 NSString *clientId = [defaultsGet stringForKey:LCCK_KEY_USERID];
                 
                 [[self class] lcck_showMessage:title toView:viewController.view];
                 [[LCChatKit sharedInstance] openWithClientId:clientId
                                                        force:granted
                                                     callback:
                  ^(BOOL succeeded, NSError *error) {
                      [[self class] lcck_hideHUDForView:viewController.view];
                      //completionHandler用来提示重连成功的HUD
                      !completionHandler ?: completionHandler(succeeded, error);
                  }];
                 return;
             }
             
             // 一旦出现单点登录被踢错误，必须退出到登录界面重新登录
             // - 退回登录页面
             [[self class] lcck_clearLocalClientInfo];
             LCCKLoginViewController *loginViewController = [[LCCKLoginViewController alloc] init];
             [loginViewController setClientIDHandler:^(NSString *clientID) {
                 [LCCKUtil showProgressText:@"open client ..." duration:10.0f];
                 [LCChatKitExample invokeThisMethodAfterLoginSuccessWithClientId:clientID
                                                                         success:
                  ^{
                      [LCCKUtil hideProgress];
                      LCCKTabBarControllerConfig *tabBarControllerConfig =
                      [[LCCKTabBarControllerConfig alloc] init];
                      [UIApplication sharedApplication].keyWindow.rootViewController =
                      tabBarControllerConfig.tabBarController;
                  }
                                                                          failed:
                  ^(NSError *error) {
                      [LCCKUtil hideProgress];
                      NSLog(@"%@", error);
                  }];
             }];
             [[self class] lcck_tryPresentViewControllerViewController:loginViewController];
             //completionHandler用来提示重连成功的HUD，此处可以不用执行
             !completionHandler ?: completionHandler(YES, nil);
             return;
         }
     }];
}
/**
 *  各个情况的hud提示设置
 */
- (void)lcck_setupHud {
    [[LCChatKit sharedInstance] setHUDActionBlock:^(UIViewController *viewController, UIView *view, NSString *title,
                         LCCKMessageHUDActionType type) {
         switch (type) {
             case LCCKMessageHUDActionTypeShow:
                 [[self class] lcck_showMessage:title toView:view];
                 break;
                 
             case LCCKMessageHUDActionTypeHide:
                 [[self class] lcck_hideHUDForView:view];
                 break;
                 
             case LCCKMessageHUDActionTypeError:
                 [[self class] lcck_showError:title toView:view];
                 break;
                 
             case LCCKMessageHUDActionTypeSuccess:
                 [[self class] lcck_showSuccess:title toView:view];
                 break;
         }
     }];
}

/**
 *  打开用户主页的设置
 */
- (void)lcck_setupOpenProfile {
    [[LCChatKit sharedInstance] setOpenProfileBlock:^(NSString *userId, id<LCCKUserDelegate> user,
                                                      __kindof UIViewController *parentController) {
        if (!userId) {
            [LCCKUtil showNotificationWithTitle:@"用户不存在"
                                       subtitle:nil
                                           type:LCCKMessageNotificationTypeError];
            return;
        }
        [self lcck_exampleOpenProfileForUser:user userId:userId parentController:parentController];
    }];
}

/**
 *   头像开启圆角设置
 */
- (void)lcck_setupAvatarImageCornerRadius {
    [[LCChatKit sharedInstance] setAvatarImageViewCornerRadiusBlock:^CGFloat(CGSize avatarImageViewSize) {
         if (avatarImageViewSize.height > 0) {
             return avatarImageViewSize.height / 2;
         }
         return 5;
     }];
}

/**
 *  筛选消息的设置
 */
- (void)lcck_setupFilterMessage {
    //注意：在 `[RedpacketConfig lcck_setting]` 中已经设置过该 `setFilterMessagesBlock:` ，注意不要重复设置。
    //这里演示如何筛选新的消息记录，以及新接收到的消息，以群定向消息为例：
    [[LCChatKit sharedInstance] setFilterMessagesBlock:^(AVIMConversation *conversation,
                              NSArray<AVIMTypedMessage *> *messages,
                              LCCKFilterMessagesCompletionHandler completionHandler) {
         if (conversation.lcck_type == LCCKConversationTypeSingle) {
             completionHandler(messages, nil);
             return;
         }
         //群聊
         NSMutableArray *filterMessages = [NSMutableArray arrayWithCapacity:messages.count];
         for (AVIMTypedMessage *typedMessage in messages) {
             if ([typedMessage.clientId isEqualToString:[LCChatKit sharedInstance].clientId]) {
                 [filterMessages addObject:typedMessage];
                 continue;
             }
             NSArray *visiableForPartClientIds = [typedMessage.attributes
                                                  valueForKey:LCCKCustomMessageOnlyVisiableForPartClientIds];
             if (!visiableForPartClientIds) {
                 [filterMessages addObject:typedMessage];
             } else if (visiableForPartClientIds.count > 0) {
                 BOOL visiableForCurrentClientId =
                 [visiableForPartClientIds containsObject:[LCChatKit sharedInstance].clientId];
                 if (visiableForCurrentClientId) {
                     [filterMessages addObject:typedMessage];
                 } else {
                     AVIMTextMessage* otherMsg = [AVIMTextMessage messageWithText:@"这是群定向消息，仅部分群成员可见" attributes:typedMessage.attributes];
//                     typedMessage.text = @"这是群定向消息，仅部分群成员可见";
//                     typedMessage.mediaType = kAVIMMessageMediaTypeText;
                     [filterMessages addObject:otherMsg];
                 }
             }
         }
         completionHandler([filterMessages copy], nil);
     }];
}

- (void)lcck_setupSendMessageHook {
    [[LCChatKit sharedInstance] setSendMessageHookBlock:^(LCCKConversationViewController *conversationController, __kindof AVIMTypedMessage *message, LCCKSendMessageHookCompletionHandler completionHandler) {
        if ([message.clientId isEqualToString:@"Jerry"]) {
            NSInteger code = 0;
            NSString *errorReasonText = @"不允许Jerry发送消息";
            NSDictionary *errorInfo = @{
                                        @"code":@(code),
                                        NSLocalizedDescriptionKey : errorReasonText,
                                        };
            NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                                 code:code
                                             userInfo:errorInfo];
            
            completionHandler(NO, error);
            [conversationController sendLocalFeedbackTextMessge:errorReasonText];
        } else {
            completionHandler(YES, nil);
        }
    }];
}

/**
 *  设置收到ChatKit的通知处理
 */
- (void)lcck_setupNotification {
    [[LCChatKit sharedInstance] setShowNotificationBlock:^(UIViewController *viewController, NSString *title,
                                NSString *subtitle, LCCKMessageNotificationType type) {
         [self lcck_exampleShowNotificationWithTitle:title subtitle:subtitle type:type];
     }];
}

/**
 *  设置预览定位样式
 */
- (void)lcck_setupPreviewLocationMessage {
    [[LCChatKit sharedInstance] setPreviewLocationMessageBlock:^(CLLocation *location, NSString *geolocations,
                                      NSDictionary *userInfo) {
         [self lcck_examplePreViewLocationMessageWithLocation:location geolocations:geolocations];
     }];
}

#pragma mark - private

- (void)lcck_exampleShowNotificationWithTitle:(NSString *)title
                                     subtitle:(NSString *)subtitle
                                         type:(LCCKMessageNotificationType)type {
    [LCCKUtil showNotificationWithTitle:title subtitle:subtitle type:type];
}

- (void)lcck_exampleOpenProfileForUser:(id<LCCKUserDelegate>)user
                                userId:(NSString *)userId
                      parentController:(__kindof UIViewController *)parentController {
    NSString *currentClientId = [LCChatKit sharedInstance].clientId;
    NSString *title = [NSString stringWithFormat:@"打开用户主页 \nClientId是 : %@", userId];
    NSString *subtitle = [NSString stringWithFormat:@"name是 : %@", user.name];
    if ([userId isEqualToString:currentClientId]) {
        title = [NSString stringWithFormat:@"打开自己的主页 \nClientId是 : %@", userId];
        subtitle = [NSString stringWithFormat:@"我自己的name是 : %@", user.name];
    }
    else if ([parentController isKindOfClass:[LCCKConversationViewController class]]) {
        LCCKConversationViewController *conversationViewController_ =
        [[LCCKConversationViewController alloc] initWithPeerId:user.clientId ?: userId];
        [[self class] lcck_pushToViewController:conversationViewController_ fromViewController:parentController];
        return;
    }
    [LCCKUtil showNotificationWithTitle:title
                               subtitle:subtitle
                                   type:LCCKMessageNotificationTypeMessage];
}

- (void)lcck_examplePreViewLocationMessageWithLocation:(CLLocation *)location
                                          geolocations:(NSString *)geolocations {
    NSString *title = [NSString stringWithFormat:@"打开地理位置：%@", geolocations];
    NSString *subTitle =
    [NSString stringWithFormat:@"纬度：%@\n经度：%@", @(location.coordinate.latitude),
     @(location.coordinate.longitude)];
    [LCCKUtil showNotificationWithTitle:title
                               subtitle:subTitle
                                   type:LCCKMessageNotificationTypeMessage];
}

/**
 *  设置tabBar当中，聊天列表下标的未读消息
 *
 *  @param totalUnreadCount 未读消息数量
 *  @param controller       聊天列表的控制器名
 */
- (void)lcck_exampleMarkBadgeWithTotalUnreadCount:(NSInteger)totalUnreadCount
                                       controller:(UIViewController *)controller {
    if (totalUnreadCount > 0) {
        NSString *badgeValue = [NSString stringWithFormat:@"%ld", (long)totalUnreadCount];
        if (totalUnreadCount > 99) {
            badgeValue = LCCKBadgeTextForNumberGreaterThanLimit;
        }
        [controller tabBarItem].badgeValue = badgeValue;
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:totalUnreadCount];
    } else {
        [controller tabBarItem].badgeValue = nil;
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
}

+ (void)lcck_exampleChangeGroupAvatarURLsForConversationId:(NSString *)conversationId
                                              shouldInsert:(BOOL)shouldInsert 
{
}

/**
 *  自定义会话的菜单
 *
 *  @param indexPath    点击菜单的index
 *  @param conversation 会话
 *  @param controller   最近联系人列表的控制器
 *
 *  @return 返回UITableViewRowAction类型的数组
 */
- (NSArray *)lcck_exampleConversationEditActionAtIndexPath:(NSIndexPath *)indexPath
                                              conversation:(AVIMConversation *)conversation
                                                controller:(LCCKConversationListViewController *)controller {
    // 如果需要自定义其他会话的菜单，在此编辑
    return [self lcck_rightButtonsAtIndexPath:indexPath conversation:conversation controller:controller];
}

- (NSArray *)lcck_rightButtonsAtIndexPath:(NSIndexPath *)indexPath
                             conversation:(AVIMConversation *)conversation
                               controller:(LCCKConversationListViewController *)controller {
    NSString *title = nil;
    UITableViewRowActionHandler handler = nil;
    [self lcck_markReadStatusAtIndexPath:indexPath
                                   title:&title
                                  handle:&handler
                            conversation:conversation
                              controller:controller];
    UITableViewRowAction *actionItemMore =
    [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                       title:title
                                     handler:handler];
    actionItemMore.backgroundColor = [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0];
    UITableViewRowAction *actionItemDelete = [UITableViewRowAction
                                              rowActionWithStyle:UITableViewRowActionStyleDefault
                                              title:@"删除"
                                              handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                  [[LCChatKit sharedInstance] deleteRecentConversationWithConversationId:conversation.conversationId];
                                              }];
    
    UITableViewRowAction *actionItemChangeGroupAvatar = [UITableViewRowAction
                                                         rowActionWithStyle:UITableViewRowActionStyleDefault
                                                         title:@"改群头像"
                                                         handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
                                                             [[self class] lcck_exampleChangeGroupAvatarURLsForConversationId:conversation.conversationId
                                                              shouldInsert:NO];
                                                         }];
    actionItemChangeGroupAvatar.backgroundColor = [UIColor colorWithRed:251 / 255.f green:186 / 255.f blue:11 / 255.f alpha:1.0];
    if (conversation.lcck_type == LCCKConversationTypeSingle) {
        return @[ actionItemDelete, actionItemMore ];
    }
    return @[ actionItemDelete, actionItemMore, actionItemChangeGroupAvatar ];
}

typedef void (^UITableViewRowActionHandler)(UITableViewRowAction *action, NSIndexPath *indexPath);

- (void)lcck_markReadStatusAtIndexPath:(NSIndexPath *)indexPath
                                 title:(NSString **)title
                                handle:(UITableViewRowActionHandler *)handler
                          conversation:(AVIMConversation *)conversation
                            controller:(LCCKConversationListViewController *)controller {
    NSString *conversationId = conversation.conversationId;
    if (title) {
        *title = @"标记为已读";
    }
    *handler = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [controller.tableView setEditing:NO animated:YES];
        [[LCChatKit sharedInstance] updateUnreadCountToZeroWithConversationId:conversationId];
    };
//    if (conversation.lcck_unreadCount > 0) {
//    } else {
//        if (title) {
//            *title = @"标记为未读";
//        }
//        *handler = ^(UITableViewRowAction *action, NSIndexPath *indexPath) {
//            [controller.tableView setEditing:NO animated:YES];
//            [[LCChatKit sharedInstance] increaseUnreadCountWithConversationId:conversationId];
//        };
//    }
}

#pragma mark 页面跳转

+ (void)lcck_pushToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController {
    if (!fromViewController) {
        UITabBarController *tabBarController = [self cyl_tabBarController];
        UINavigationController *navigationController = tabBarController.selectedViewController;
        fromViewController = navigationController;
    }
    [fromViewController
     cyl_popSelectTabBarChildViewControllerAtIndex:0
     completion:^(__kindof UIViewController
                  *selectedChildTabBarController) {
         [selectedChildTabBarController.navigationController pushViewController:toViewController
                                                                       animated:YES];
     }];
}

+ (void)lcck_pushToViewController:(UIViewController *)viewController {
    [self lcck_pushToViewController:viewController fromViewController:nil];
}

+ (void)lcck_tryPresentViewControllerViewController:(UIViewController *)viewController {
    if (viewController) {
        UIViewController *rootViewController =
        [[UIApplication sharedApplication].delegate window].rootViewController;
        if ([rootViewController isKindOfClass:[UINavigationController class]]) {
            rootViewController =
            [(UINavigationController *)rootViewController visibleViewController];
        }
        [rootViewController dismissViewControllerAnimated:NO completion:nil];
        [rootViewController presentViewController:viewController animated:YES completion:nil];
    }
}

#pragma mark 清除Client信息
+ (void)lcck_clearLocalClientInfo {
    // 在系统偏好保存信息
    NSUserDefaults *defaultsSet = [NSUserDefaults standardUserDefaults];
    [defaultsSet setObject:nil forKey:LCCK_KEY_USERID];
    [defaultsSet synchronize];
}

- (void)lcck_transpondMessage:(LCCKMessage *)message toConversationViewController:(LCCKConversationViewController *)conversationViewController
{
    LCCKLog(@"消息转发");
}

// MARK: - Member Info Changed

- (void)lcck_memberInfoChanged
{
    [[LCChatKit sharedInstance] setMemberInfoChangedBlock:^(AVIMConversation *conversation, NSString *byClientId, NSString *clientId, AVIMConversationMemberRole role) {
        NSString *roleString = @"Member";
        if (role == AVIMConversationMemberRoleOwner) {
            roleString = @"Owner";
        } else if (role == AVIMConversationMemberRoleManager) {
            roleString = @"Manager";
        }
        LCCKLog(@"conversation id: %@, by client id: %@, client id: %@, role: %@", conversation.conversationId, byClientId, clientId, roleString);
    }];
}

/**
 * 演示如何自定义预览图片样式
 *
- (void)examplePreviewImageMessageWithInitialIndex:(NSUInteger)index allVisibleImages:(NSArray *)allVisibleImages allVisibleThumbs:(NSArray *)allVisibleThumbs {
    // Browser
    NSMutableArray *photos = [[NSMutableArray alloc] initWithCapacity:[allVisibleImages count]];
    NSMutableArray *thumbs = [[NSMutableArray alloc] initWithCapacity:[allVisibleThumbs count]];
    MWPhoto *photo;
    MWPhoto *thumb;
    BOOL displayActionButton = YES;
    BOOL displaySelectionButtons = NO;
    BOOL displayNavArrows = NO;
    BOOL enableGrid = YES;
    BOOL startOnGrid = NO;
    BOOL autoPlayOnAppear = NO;
    for (NSUInteger index = 0; index < allVisibleImages.count; index++) {
        id image_ = allVisibleImages[index];
        if ([image_ isKindOfClass:[UIImage class]]) {
            photo = [MWPhoto photoWithImage:image_];
        } else {
            photo = [MWPhoto photoWithURL:image_];
        }
        [photos addObject:photo];
        
        id thumb_ = allVisibleThumbs[index];
        if ([thumb_ isKindOfClass:[UIImage class]]) {
            thumb = [MWPhoto photoWithImage:thumb_];
        } else {
            thumb = [MWPhoto photoWithURL:thumb_];
        }
        [thumbs addObject:thumb];
    }
    // Options
    startOnGrid = NO;
    displayNavArrows = YES;
    self.photos = photos;
    self.thumbs = thumbs;
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = displayActionButton;
    browser.displayNavArrows = displayNavArrows;
    browser.displaySelectionButtons = displaySelectionButtons;
    browser.alwaysShowControls = displaySelectionButtons;
    browser.zoomPhotosToFill = YES;
    browser.enableGrid = enableGrid;
    browser.startOnGrid = startOnGrid;
    browser.enableSwipeToDismiss = NO;
    browser.autoPlayOnAppear = autoPlayOnAppear;
    [browser setCurrentPhotoIndex:index];
    // Reset selections
    if (displaySelectionButtons) {
        _selections = [[NSMutableArray alloc] initWithCapacity:[allVisibleImages count]];
        for (int i = 0; i < photos.count; i++) {
            [_selections addObject:[NSNumber numberWithBool:NO]];
        }
    }
    [[self class] pushToViewController:browser];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _thumbs.count)
        return [_thumbs objectAtIndex:index];
    return nil;
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return [[_selections objectAtIndex:index] boolValue];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
}
 
*/

@end
