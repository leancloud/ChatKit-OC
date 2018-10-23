//
//  LCCKContactListViewController.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

#if __has_include(<ChatKit/LCChatKit.h>)
    #import <ChatKit/LCChatKit.h>
#else
    #import "LCChatKit.h"
#endif

@class LCCKContact;

typedef enum : NSUInteger {
    LCCKContactListModeNormal,
    LCCKContactListModeSingleSelection,
    LCCKContactListModeMultipleSelection
} LCCKContactListMode;
NS_ASSUME_NONNULL_BEGIN

typedef void (^LCCKSelectedContactCallback)(UIViewController *viewController, NSString *peerId);
typedef void (^LCCKSelectedContactsCallback)(UIViewController *viewController, NSArray<NSString *> *peerIds);

/*!
 * @return 删除是否成功
 */
typedef BOOL (^LCCKDeleteContactCallback)(UIViewController *viewController, NSString *peerId);

@interface LCCKContactListViewController : LCCKBaseTableViewController

/*!
 * 不参与展示的名单，可以是黑名单或者当前用户。该数组是client id的集合。
 */
@property (nonatomic) NSSet *excludedUserIds;

@property (nonatomic, assign, readonly) LCCKContactListMode mode;
@property (nonatomic, copy) NSSet<LCCKContact *> *contacts;
@property (nonatomic, copy) NSSet<NSString *> *userIds;

- (void)setDeleteContactCallback:(LCCKDeleteContactCallback)deleteContactCallback;
- (LCCKDeleteContactCallback)deleteContactCallback;

- (void)setSelectedContactCallback:(LCCKSelectedContactCallback)selectedContactCallback;
- (LCCKSelectedContactCallback)selectedContactCallback;
- (void)setSelectedContactsCallback:(LCCKSelectedContactsCallback)selectedContactsCallback;
- (LCCKSelectedContactsCallback)selectedContactsCallback;
- (instancetype)initWithContacts:(NSSet<LCCKContact *> *)contacts
                            mode:(LCCKContactListMode)mode;

- (instancetype)initWithContacts:(NSSet<LCCKContact *> *)contacts
                 excludedUserIds:(NSSet * __nullable)excludedUserIds
                            mode:(LCCKContactListMode)mode;

- (instancetype)initWithUserIds:(NSSet<NSString *> *)userIds
                           mode:(LCCKContactListMode)contactListMode;

- (instancetype)initWithUserIds:(NSSet<NSString *> *)userIds
                 excludedUserIds:(NSSet * __nullable)excludedUserIds
                            mode:(LCCKContactListMode)contactListMode;
/*!
 * @param 你可以使用 contacts 和 userIds 两个参数来进行联系人列表初始化，区别是前者可以为空，后者不可以为空。如果同时传了两个参数，那么前者优先级大于后者。如果只传了后者，ChatKit 会自行进行网络请求获取到对应的 contacts。
 * @param excludedUserIds 是黑名单，不希望出现在联系人列表里的用户id，最常见的是将自己的id放在这里。
 * @param contactListMode 主要分为：单选、多选、点击即跳转。
 */
- (instancetype)initWithContacts:(NSSet<LCCKContact *> * __nullable)contacts
                         userIds:(NSSet<NSString *> *)userIds
                 excludedUserIds:(NSSet * __nullable)excludedUserIds
                            mode:(LCCKContactListMode)contactListMode;
NS_ASSUME_NONNULL_END

@end
