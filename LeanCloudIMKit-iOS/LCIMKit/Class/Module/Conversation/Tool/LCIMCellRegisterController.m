//
//  UIself+LCIMCellRegister.m
//  LCIMChatBarExample
//
//  Created by ElonChan ( https://github.com/leancloud/LeanCloudIMKit-iOS ) on 15/11/23.
//  Copyright © 2015年 https://LeanCloud.cn . All rights reserved.
//

#import "LCIMCellRegisterController.h"
#import "LCIMChatMessageCell.h"
#import "LCIMChatTextMessageCell.h"
#import "LCIMChatImageMessageCell.h"
#import "LCIMChatVoiceMessageCell.h"
#import "LCIMChatSystemMessageCell.h"
#import "LCIMChatLocationMessageCell.h"

@implementation LCIMCellRegisterController

+ (void)registerLCIMChatMessageCellClassForTableView:(UITableView *)tableView {
    [tableView registerClass:[LCIMChatImageMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSelf_ImageMessage_GroupCell"];
    [tableView registerClass:[LCIMChatImageMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSelf_ImageMessage_SingleCell"];
    [tableView registerClass:[LCIMChatImageMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerOther_ImageMessage_GroupCell"];
    [tableView registerClass:[LCIMChatImageMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerOther_ImageMessage_SingleCell"];
    
    [tableView registerClass:[LCIMChatLocationMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSelf_LocationMessage_GroupCell"];
    [tableView registerClass:[LCIMChatLocationMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSelf_LocationMessage_SingleCell"];
    [tableView registerClass:[LCIMChatLocationMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerOther_LocationMessage_GroupCell"];
    [tableView registerClass:[LCIMChatLocationMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerOther_LocationMessage_SingleCell"];
    
    [tableView registerClass:[LCIMChatVoiceMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSelf_VoiceMessage_GroupCell"];
    [tableView registerClass:[LCIMChatVoiceMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSelf_VoiceMessage_SingleCell"];
    [tableView registerClass:[LCIMChatVoiceMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerOther_VoiceMessage_GroupCell"];
    [tableView registerClass:[LCIMChatVoiceMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerOther_VoiceMessage_SingleCell"];
    
    [tableView registerClass:[LCIMChatTextMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSelf_TextMessage_GroupCell"];
    [tableView registerClass:[LCIMChatTextMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSelf_TextMessage_SingleCell"];
    [tableView registerClass:[LCIMChatTextMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerOther_TextMessage_GroupCell"];
    [tableView registerClass:[LCIMChatTextMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerOther_TextMessage_SingleCell"];
    
    [tableView registerClass:[LCIMChatSystemMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSystem_SystemMessage_"];
    [tableView registerClass:[LCIMChatSystemMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSystem_SystemMessage_SingleCell"];
    [tableView registerClass:[LCIMChatSystemMessageCell class] forCellReuseIdentifier:@"LCIMChatMessageCell_OwnerSystem_SystemMessage_GroupCell"];
}

@end
