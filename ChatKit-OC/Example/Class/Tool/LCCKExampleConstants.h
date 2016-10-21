//
//  LCCKExampleConstants.h
//  ChatKit-OC
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/8/13.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#ifndef LCCKExampleConstants_h
#define LCCKExampleConstants_h

#pragma mark - 用以产生Demo中的联系人数据的宏定义
///=============================================================================
/// @name 用以产生Demo中的联系人数据的宏定义
///=============================================================================

#define LCCKProfileKeyPeerId        @"peerId"
#define LCCKProfileKeyName          @"username"
#define LCCKProfileKeyAvatarURL     @"avatarURL"
#define LCCKDeveloperPeerId @"571dae7375c4cd3379024b2f"

//TODO:add more friends
#define LCCKContactProfiles \
@[ \
    @{ LCCKProfileKeyPeerId:LCCKDeveloperPeerId, LCCKProfileKeyName:@"ChatKit-iOS小秘书", LCCKProfileKeyAvatarURL:@"http://image17-c.poco.cn/mypoco/myphoto/20151211/16/17338872420151211164742047.png" },\
    @{ LCCKProfileKeyPeerId:@"Tom", LCCKProfileKeyName:@"Tom", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/tom_and_jerry2.jpg" },\
    @{ LCCKProfileKeyPeerId:@"Jerry", LCCKProfileKeyName:@"Jerry", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/jerry.jpg" },\
    @{ LCCKProfileKeyPeerId:@"Harry", LCCKProfileKeyName:@"Harry", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/young_harry.jpg" },\
    @{ LCCKProfileKeyPeerId:@"William", LCCKProfileKeyName:@"William", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/william_shakespeare.jpg" },\
    @{ LCCKProfileKeyPeerId:@"Bob", LCCKProfileKeyName:@"Bob", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/bath_bob.jpg" },\
    @{ LCCKProfileKeyPeerId:@"RP", LCCKProfileKeyName:@"RP", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/bath_bob.jpg" },\
    @{ LCCKProfileKeyPeerId:@"RP1", LCCKProfileKeyName:@"RP1", LCCKProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/bath_bob.jpg" },\
    @{ LCCKProfileKeyPeerId:@"5771e7656be3ff0063a0dada", LCCKProfileKeyName:@"hhx2", LCCKProfileKeyAvatarURL:@"http://ac-x3o016bx.clouddn.com/jXyGZv2B2W4oc3OaEQtYDo3w7fJjgovHeXGuyfFD" },\
]

#define LCCKContactPeerIds \
    [LCCKContactProfiles valueForKeyPath:LCCKProfileKeyPeerId]

#define LCCKTestPersonProfiles \
@[ \
    @{ LCCKProfileKeyPeerId:@"Tom" },\
    @{ LCCKProfileKeyPeerId:@"Jerry" },\
    @{ LCCKProfileKeyPeerId:@"Harry" },\
    @{ LCCKProfileKeyPeerId:@"William" },\
    @{ LCCKProfileKeyPeerId:@"Bob" },\
    @{ LCCKProfileKeyPeerId:@"RP1" },\
    @{ LCCKProfileKeyPeerId:@"RP" },\
    @{ LCCKProfileKeyPeerId:@"5771e7656be3ff0063a0dada" },\
]

#define LCCKTestPeerIds \
    [LCCKTestPersonProfiles valueForKeyPath:LCCKProfileKeyPeerId]
#define __LCCKContactsOfDevelopers \
@[                                 \
    LCCKDeveloperPeerId,           \
]

#define __LCCKContactsOfSections \
@[                               \
    LCCKTestPeerIds,             \
    __LCCKContactsOfDevelopers,  \
]

#define LCCKTestConversationGroupAvatarURLs                      \
    @[                                                           \
      @"http://www.avatarsdb.com/avatars/mickey.jpg",            \
      @"http://www.avatarsdb.com/avatars/mickey_mouse.jpg",      \
      @"http://www.avatarsdb.com/avatars/all_together.jpg",      \
      @"http://www.avatarsdb.com/avatars/baby_disney.jpg",       \
      @"http://www.avatarsdb.com/avatars/donald_duck01.jpg",     \
      @"http://www.avatarsdb.com/avatars/Blue_Team_Disney.jpg",  \
      @"http://www.avatarsdb.com/avatars/mickey_mouse_smile.jpg",\
      @"http://www.avatarsdb.com/avatars/baby_pluto_dog.jpg",    \
      @"http://www.avatarsdb.com/avatars/donald_duck_angry.jpg", \
      @"http://www.avatarsdb.com/avatars/mickey_mouse_colors.jpg"\
]

#pragma mark - UI opera
///=============================================================================
/// @name UI opera
///=============================================================================

#define localize(key, default) LCCKLocalizedStrings(key)

#pragma mark - Message Bars

#define kStringMessageBarErrorTitle localize(@"message.bar.error.title")
#define kStringMessageBarErrorMessage localize(@"message.bar.error.message")
#define kStringMessageBarSuccessTitle localize(@"message.bar.success.title")
#define kStringMessageBarSuccessMessage localize(@"message.bar.success.message")
#define kStringMessageBarInfoTitle localize(@"message.bar.info.title")
#define kStringMessageBarInfoMessage localize(@"message.bar.info.message")

#pragma mark - Buttons

#define kStringButtonLabelSuccessMessage localize(@"button.label.success.message")
#define kStringButtonLabelErrorMessage localize(@"button.label.error.message")
#define kStringButtonLabelInfoMessage localize(@"button.label.info.message")
#define kStringButtonLabelHideAll localize(@"button.label.hide.all")

#pragma mark - Dict or UserDefaults Key
///=============================================================================
/// @name Dict or UserDefaults Key
///=============================================================================

static NSString *const LCCK_KEY_USERNAME = @"LCCK_KEY_USERNAME";
static NSString *const LCCK_KEY_USERID = @"LCCK_KEY_USERID";


#endif /* LCCKExampleConstants_h */
