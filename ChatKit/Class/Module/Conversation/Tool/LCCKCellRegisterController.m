//
//  UIself+LCCKCellRegister.m
//  LCCKChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/ChatKit-OC ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCCKCellRegisterController.h"
#import "LCCKChatMessageCell.h"
#import "LCCKChatTextMessageCell.h"
#import "LCCKChatImageMessageCell.h"
#import "LCCKChatVoiceMessageCell.h"
#import "LCCKChatSystemMessageCell.h"
#import "LCCKChatLocationMessageCell.h"

@implementation LCCKCellRegisterController

+ (void)registerLCCKChatMessageCellClassForTableView:(UITableView *)tableView {
    [tableView registerClass:[LCCKChatImageMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSelf_ImageMessage_GroupCell"];
    [tableView registerClass:[LCCKChatImageMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSelf_ImageMessage_SingleCell"];
    [tableView registerClass:[LCCKChatImageMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerOther_ImageMessage_GroupCell"];
    [tableView registerClass:[LCCKChatImageMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerOther_ImageMessage_SingleCell"];
    
    [tableView registerClass:[LCCKChatLocationMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSelf_LocationMessage_GroupCell"];
    [tableView registerClass:[LCCKChatLocationMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSelf_LocationMessage_SingleCell"];
    [tableView registerClass:[LCCKChatLocationMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerOther_LocationMessage_GroupCell"];
    [tableView registerClass:[LCCKChatLocationMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerOther_LocationMessage_SingleCell"];
    
    [tableView registerClass:[LCCKChatVoiceMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSelf_VoiceMessage_GroupCell"];
    [tableView registerClass:[LCCKChatVoiceMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSelf_VoiceMessage_SingleCell"];
    [tableView registerClass:[LCCKChatVoiceMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerOther_VoiceMessage_GroupCell"];
    [tableView registerClass:[LCCKChatVoiceMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerOther_VoiceMessage_SingleCell"];
    
    [tableView registerClass:[LCCKChatTextMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSelf_TextMessage_GroupCell"];
    [tableView registerClass:[LCCKChatTextMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSelf_TextMessage_SingleCell"];
    [tableView registerClass:[LCCKChatTextMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerOther_TextMessage_GroupCell"];
    [tableView registerClass:[LCCKChatTextMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerOther_TextMessage_SingleCell"];
    
    [tableView registerClass:[LCCKChatSystemMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSystem_SystemMessage_"];
    [tableView registerClass:[LCCKChatSystemMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSystem_SystemMessage_SingleCell"];
    [tableView registerClass:[LCCKChatSystemMessageCell class] forCellReuseIdentifier:@"LCCKChatMessageCell_OwnerSystem_SystemMessage_GroupCell"];
}

@end
