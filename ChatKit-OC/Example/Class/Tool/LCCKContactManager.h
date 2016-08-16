//
//  LCCKContactManager.h
//  LeanCloudChatKit-iOS
//
// v0.5.2 Created by 陈宜龙 on 16/3/10.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LCCKContactManager : NSObject

+ (instancetype)defaultManager;

- (NSArray *)fetchContactPeerIds;
- (BOOL)existContactForPeerId:(NSString *)peerId;
- (BOOL)addContactForPeerId:(NSString *)peerId;
- (BOOL)removeContactForPeerId:(NSString *)peerId;

@end
