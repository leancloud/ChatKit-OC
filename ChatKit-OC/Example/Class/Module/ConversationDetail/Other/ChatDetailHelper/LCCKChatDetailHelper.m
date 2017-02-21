//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import "LCCKChatDetailHelper.h"
#import "LCCKUser.h"
#import <AVOSCloudIM/AVOSCloudIM.h>

@implementation LCCKChatDetailHelper

- (NSMutableArray *)chatDetailDataBySingleInfo:(AVIMConversation *)singleInfo {
    LCCKSettingItem *users = LCCKCreateSettingItem(@"users");
    users.type = LCCKSettingItemTypeOther;
    LCCKSettingGroup *group1 = LCCKCreateSettingGroup(nil, nil, @[users]);
    
    LCCKSettingItem *top = LCCKCreateSettingItem(@"置顶聊天");
    top.type = LCCKSettingItemTypeSwitch;
    LCCKSettingItem *screen = LCCKCreateSettingItem(@"消息免打扰");
    screen.type = LCCKSettingItemTypeSwitch;
    screen.isSwithOn = singleInfo.muted;
    LCCKSettingGroup *group2 = LCCKCreateSettingGroup(nil, nil, (@[top, screen]));
    
    LCCKSettingItem *chatFile = LCCKCreateSettingItem(@"聊天文件");
    LCCKSettingGroup *group3 = LCCKCreateSettingGroup(nil, nil, @[chatFile]);
    
    LCCKSettingItem *chatBG = LCCKCreateSettingItem(@"设置当前聊天背景");
    LCCKSettingItem *chatHistory = LCCKCreateSettingItem(@"查找聊天内容");
    LCCKSettingGroup *group4 = LCCKCreateSettingGroup(nil, nil, (@[chatBG, chatHistory]));
    
    LCCKSettingItem *clear = LCCKCreateSettingItem(@"清空聊天记录");
    clear.showDisclosureIndicator = NO;
    LCCKSettingGroup *group5 = LCCKCreateSettingGroup(nil, nil, @[clear]);
    
    LCCKSettingItem *report = LCCKCreateSettingItem(@"举报");
    LCCKSettingGroup *group6 = LCCKCreateSettingGroup(nil, nil, @[report]);
    
    NSMutableArray *data = [[NSMutableArray alloc] init];
    [data addObjectsFromArray:@[group1, group2, group3, group4, group5, group6]];
    return data;
}

- (NSMutableArray *)chatDetailDataByGroupInfo:(AVIMConversation *)groupInfo {
    LCCKSettingItem *users = LCCKCreateSettingItem(@"users");
    users.type = LCCKSettingItemTypeOther;
    LCCKSettingItem *allUsers = LCCKCreateSettingItem(([NSString stringWithFormat:@"全部群成员(%ld)", (long)groupInfo.members.count]));
    LCCKSettingGroup *group1 = LCCKCreateSettingGroup(nil, nil, (@[users, allUsers]));
    
    LCCKSettingItem *groupName = LCCKCreateSettingItem(@"群聊名称");
    groupName.subTitle = groupInfo.name;
    LCCKSettingItem *groupQR = LCCKCreateSettingItem(@"群二维码");
    groupQR.rightImagePath = @"mine_cell_myQR";
    LCCKSettingItem *groupPost = LCCKCreateSettingItem(@"群公告");
    //TODO:
//    if (groupInfo.post.length > 0) {
//        groupPost.subTitle = groupInfo.post;
//    }
//    else {
        groupPost.subTitle = @"未设置";
//    }
    LCCKSettingGroup *group2 = LCCKCreateSettingGroup(nil, nil, (@[groupName, groupQR, groupPost]));
    
    LCCKSettingItem *screen = LCCKCreateSettingItem(@"消息免打扰");
    screen.type = LCCKSettingItemTypeSwitch;
    screen.isSwithOn = groupInfo.muted;
    
    LCCKSettingItem *top = LCCKCreateSettingItem(@"置顶聊天");
    top.type = LCCKSettingItemTypeSwitch;
    LCCKSettingItem *save = LCCKCreateSettingItem(@"保存到通讯录");
    save.type = LCCKSettingItemTypeSwitch;
    LCCKSettingGroup *group3 = LCCKCreateSettingGroup(nil, nil, (@[screen, top, save]));
    
    LCCKSettingItem *myNikeName = LCCKCreateSettingItem(@"我在本群的昵称");
    NSString *nickName = nil;
    NSString *currentUserClientId = [LCChatKit sharedInstance].clientId;
    [[LCChatKit sharedInstance] getCachedProfileIfExists:currentUserClientId name:&nickName avatarURL:nil error:nil];
    myNikeName.subTitle = nickName ?: currentUserClientId;
    LCCKSettingItem *showOtherNikeName = LCCKCreateSettingItem(@"显示群成员昵称");
    showOtherNikeName.type = LCCKSettingItemTypeSwitch;
    LCCKSettingGroup *group4 = LCCKCreateSettingGroup(nil, nil, (@[myNikeName, showOtherNikeName]));
    
    LCCKSettingItem *chatFile = LCCKCreateSettingItem(@"聊天文件");
    LCCKSettingItem *chatHistory = LCCKCreateSettingItem(@"查找聊天内容");
    LCCKSettingItem *chatBG = LCCKCreateSettingItem(@"设置当前聊天背景");
    LCCKSettingItem *report = LCCKCreateSettingItem(@"举报");
    LCCKSettingGroup *group5 = LCCKCreateSettingGroup(nil, nil, (@[chatFile, chatHistory, chatBG, report]));
    
    LCCKSettingItem *clear = LCCKCreateSettingItem(@"清空聊天记录");
    clear.showDisclosureIndicator = NO;
    LCCKSettingGroup *group6 = LCCKCreateSettingGroup(nil, nil, @[clear]);
    
    NSMutableArray *data = [[NSMutableArray alloc] init];
    [data addObjectsFromArray:@[group1, group2, group3, group4, group5, group6]];
    return data;
}

@end
