//
//  LCIMContactListController.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCIMBaseTableViewController.h"

typedef enum : NSUInteger {
    LCIMContactListModeNormal,
    LCIMContactListModeSingleSelection,
    LCIMContactListModeMultipleSelection
} LCIMContactListMode;

@class LCIMContactListController;

@protocol LCIMContactListControllerDelegate <NSObject>
- (void)contactListController:(LCIMContactListController *)controller
           didSelectPeerIds:(NSArray *)peerIds;
@end

@interface LCIMContactListController : LCIMBaseTableViewController

@property (nonatomic, assign) LCIMContactListMode mode;
@property (nonatomic, strong) NSArray *excludedPersonIDs;
@property (nonatomic, weak) id<LCIMContactListControllerDelegate> delegate;

- (void)refresh;

@end
