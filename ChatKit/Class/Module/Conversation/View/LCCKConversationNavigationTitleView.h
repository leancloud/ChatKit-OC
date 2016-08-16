//
//  LCCKConversationNavigationTitleView.h
//  Pods
//
// v0.5.2 Created by 陈宜龙 on 16/7/19.
//
//

#import <UIKit/UIKit.h>

@class AVIMConversation;

@interface LCCKConversationNavigationTitleView : UIView

@property (nonatomic, assign) BOOL showRemindMuteImageView;

- (instancetype)initWithConversation:(AVIMConversation *)conversation navigationController:(UINavigationController *)navigationController;

@end
