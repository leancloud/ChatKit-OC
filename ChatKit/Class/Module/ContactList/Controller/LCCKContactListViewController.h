//
//  LCCKContactListViewController.h
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/22.
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
@property (nonatomic, copy) NSArray *excludedUserIds;

@property (nonatomic, assign, readonly) LCCKContactListMode mode;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, readonly) NSArray<LCCKContact *> *contacts;
- (void)setDeleteContactCallback:(LCCKDeleteContactCallback)deleteContactCallback;
- (LCCKDeleteContactCallback)deleteContactCallback;

- (void)setSelectedContactCallback:(LCCKSelectedContactCallback)selectedContactCallback;
- (LCCKSelectedContactCallback)selectedContactCallback;
- (void)setSelectedContactsCallback:(LCCKSelectedContactsCallback)selectedContactsCallback;
- (LCCKSelectedContactsCallback)selectedContactsCallback;
- (instancetype)initWithMode:(LCCKContactListMode)mode;
- (instancetype)initWithExcludedUserIds:(NSArray *)excludedUserIds
                           mode:(LCCKContactListMode)mode;
- (instancetype)initWithContacts:(NSArray<LCCKContact *> *)contacts
                 excludedUserIds:(NSArray *)excludedUserIds
                            mode:(LCCKContactListMode)mode;
- (instancetype)initWithContacts:(NSArray<LCCKContact *> *)contacts
                         userIds:(NSArray<NSString *> *)userIds
                 excludedUserIds:(NSArray *)excludedUserIds
                            mode:(LCCKContactListMode)mode;
//TODO:
 @property (nonatomic, copy) NSArray<NSString *> *userIds;
// - (instancetype)initWithUserIds:(NSArray<NSString *> *)userIds
//                excludedUserIds:(NSArray *)excludedUserIds
//                           mode:(LCCKContactListMode)mode;

@end
