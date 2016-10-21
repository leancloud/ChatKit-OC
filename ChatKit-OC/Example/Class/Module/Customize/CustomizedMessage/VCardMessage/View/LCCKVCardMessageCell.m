//
//  LCCKVCardMessageCell.m
//  ChatKit-OC
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/8/10.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKVCardMessageCell.h"
#import "LCCKVCardMessage.h"

#if __has_include(<SDWebImage/UIImageView+WebCache.h>)
#import <SDWebImage/UIImageView+WebCache.h>
#else
#import "UIImageView+WebCache.h"
#endif
#import "LCCKVCardView.h"

@interface LCCKVCardMessageCell ()
@property (nonatomic, weak) LCCKVCardView *vCardView;
@end

static CGFloat LCCK_MSG_SPACE_TOP = 10;
static CGFloat LCCK_MSG_SPACE_BTM = 10;
static CGFloat LCCK_MSG_SPACE_LEFT = 20;
static CGFloat LCCK_MSG_SPACE_RIGHT = 20;

@implementation LCCKVCardMessageCell

#pragma mark -
#pragma mark - Override Methods

- (void)setup {
    [self.vCardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).with.insets(UIEdgeInsetsMake(LCCK_MSG_SPACE_TOP, LCCK_MSG_SPACE_LEFT, LCCK_MSG_SPACE_BTM, LCCK_MSG_SPACE_RIGHT));
    }];
    [self updateConstraintsIfNeeded];
    [super setup];
}

- (void)configureCellWithData:(AVIMTypedMessage *)message {
    [super configureCellWithData:message];
    NSString *clientId;
    NSString *name = nil;
    NSURL *avatarURL = nil;
    clientId = [message.attributes valueForKey:@"clientId"];
    [[LCChatKit sharedInstance] getCachedProfileIfExists:clientId name:&name avatarURL:&avatarURL error:nil];
    if (!name) {
        name = clientId;
    }
    if (!name) {
        name = @"未知用户";
    }
    
    [self.vCardView configureWithAvatarURL:avatarURL title:name clientId:clientId];
}

#pragma mark -
#pragma mark - LCCKChatMessageCellSubclassing Method

+ (void)load {
    [self registerCustomMessageCell];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeVCard;
}

#pragma mark -
#pragma mark - Getter Method

- (LCCKVCardView *)vCardView {
    if (_vCardView) {
        return _vCardView;
    }
    LCCKVCardView *vCardView = [LCCKVCardView vCardView];
    [vCardView setVCardDidClickedHandler:^(NSString *clientId) {
        LCCKOpenProfileBlock openProfileBlock = [LCCKUIService sharedInstance].openProfileBlock;
        if (openProfileBlock) {
            id<LCCKUserDelegate> user;
            if (clientId.length > 0) {
                NSArray *users = [[LCChatKit sharedInstance] getCachedProfilesIfExists:@[clientId] error:nil];
                if (users.count > 0) {
                    user = users[0];
                }
            }
            openProfileBlock(clientId, user, (UIViewController *)self.delegate);
        }
    }];
    [self.contentView addSubview:(_vCardView = vCardView)];
    return _vCardView;
}

@end
