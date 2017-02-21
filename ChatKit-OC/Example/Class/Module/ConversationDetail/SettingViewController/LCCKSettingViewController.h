//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import <UIKit/UIKit.h>
#import "LCCKSettingCell.h"
#import "LCCKSettingSwitchCell.h"
#import "LCCKSettingGroup.h"
#import "NSObject+LCCKHUD.h"
#import <ChatKit/LCChatKit.h>

@class AVIMConversation;

#define     HEIGHT_SETTING_CELL             44.0f
#define     HEIGHT_SETTING_TOP_SPACE        15.0f
#define     HEIGHT_SETTING_BOTTOM_SPACE     12.0f

@interface LCCKSettingViewController : UITableViewController <LCCKSettingSwitchCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSMutableArray *data;

@property (nonatomic, strong) NSString *analyzeTitle;
@property (nonatomic, strong) UIImagePickerController *pickerController;

@property (nonatomic, strong) AVIMConversation *conversation;

- (void)presentSelectMemberViewControllerMemberIds:(NSArray *)memeberIds excludedUserIds:(NSArray *)excludedUserIds callback:(LCCKArrayResultBlock)callback;

@end
