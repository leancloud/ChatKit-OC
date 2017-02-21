//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import "LCCKUserGroupCell.h"
#import "LCCKUserGroupItemCell.h"
#import "LCCKUser.h"
#import <ChatKit/LCChatKit.h>

#define     USER_CELL_WIDTH         57
#define     USER_CELL_HEIGHT        75
#define     USER_CELL_ROWSPACE     15
#define     USER_CELL_COLSPACE      (([UIScreen mainScreen].bounds.size.width - USER_CELL_WIDTH * 4) / 5)

@interface LCCKUserGroupCell () <UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation LCCKUserGroupCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        [self.contentView addSubview:self.collectionView];
        [self.collectionView registerClass:[LCCKUserGroupItemCell class] forCellWithReuseIdentifier:NSStringFromClass([LCCKUserGroupItemCell class])];
        [self p_addMasonry];
    }
    return self;
}

#pragma mark - Delegate -
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([self lcck_isCreatorForCurrentGroupConversaton]) {
        return self.users.count + 2;
    }
    return self.users.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LCCKUserGroupItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([LCCKUserGroupItemCell class]) forIndexPath:indexPath];
    LCCKConversationOperationType operationType;
    LCCKUser *user;
    if (indexPath.row < self.users.count) {
        user = self.users[indexPath.row];
        operationType = LCCKConversationOperationTypeNone;
    } else if (indexPath.row == self.users.count) {
        operationType = LCCKConversationOperationTypeAdd;
        user = nil;
    } else {
        operationType = LCCKConversationOperationTypeRemove;
        user = nil;
    }
    [cell setUser:user operationType:operationType];
    [cell setClickBlock:^(LCCKUser *user) {
        if (user && _delegate && [_delegate respondsToSelector:@selector(userGroupCellDidSelectUser:)]) {
            [_delegate userGroupCellDidSelectUser:user];
        } else {
            [_delegate userGroupCellAddUserButtonDownWithOperationType:operationType];
        }
    }];
    return cell;
}

#pragma mark - Private Methods -

- (void)p_addMasonry {
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.contentView);
    }];
}

#pragma mark - Getter -

- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        [layout setItemSize:CGSizeMake(USER_CELL_WIDTH, USER_CELL_HEIGHT)];
        [layout setMinimumInteritemSpacing:USER_CELL_COLSPACE];
        [layout setSectionInset:UIEdgeInsetsMake(USER_CELL_ROWSPACE, USER_CELL_COLSPACE * 0.9, USER_CELL_ROWSPACE, USER_CELL_ROWSPACE * 0.9)];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [_collectionView setBackgroundColor:[UIColor whiteColor]];
        [_collectionView setScrollEnabled:NO];
        [_collectionView setPagingEnabled:YES];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];
        [_collectionView setShowsHorizontalScrollIndicator:NO];
        [_collectionView setShowsHorizontalScrollIndicator:NO];
        [_collectionView setScrollsToTop:NO];
    }
    return _collectionView;
}

@end
