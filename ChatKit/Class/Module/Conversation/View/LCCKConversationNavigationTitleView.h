//
//  LCCKConversationNavigationTitleView.h
//  Pods
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/7/19.
//
//

#import <UIKit/UIKit.h>

@class AVIMConversation;

@interface LCCKConversationNavigationTitleView : UIView

@property (nonatomic, assign) BOOL showRemindMuteImageView;

- (instancetype)initWithConversation:(AVIMConversation *)conversation navigationController:(UINavigationController *)navigationController;

@end
