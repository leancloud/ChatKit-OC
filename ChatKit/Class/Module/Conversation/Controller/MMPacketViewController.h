//
//  MMPacketViewController.h
//  ChatKit-OC
//
//  Created by lyricdon on 16/7/21.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MMPacketViewControllerDelegate <NSObject>

- (void)cancelPacket;
- (void)sendPacket:(NSInteger)money;

@end

@interface MMPacketViewController : UIViewController
@property (weak, nonatomic) id<MMPacketViewControllerDelegate> delegate;
@end
