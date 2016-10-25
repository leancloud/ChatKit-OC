//
//  AVSignature.h
//  paas
//
//  Created by yang chaozhong on 5/15/14.
//  Copyright (c) 2014 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVSignature : NSObject

@property (nonatomic, copy,   nullable) NSString *signature;
@property (nonatomic, assign)           int64_t   timestamp;
@property (nonatomic, copy,   nullable) NSString *nonce;
@property (nonatomic, copy,   nullable) NSString *action AV_DEPRECATED("2.6.4");
@property (nonatomic, strong, nullable) NSArray  *signedPeerIds;
@property (nonatomic, strong, nullable) NSError  *error;

@end

@protocol AVSignatureDelegate <NSObject>
@optional
- (AVSignature *)signatureForPeerWithPeerId:(NSString *)peerId watchedPeerIds:(NSArray *)watchedPeerIds action:(NSString *)action;
- (AVSignature *)signatureForGroupWithPeerId:(NSString *)peerId groupId:(NSString *)groupId groupPeerIds:(NSArray *)groupPeerIds action:(NSString *)action;


- (AVSignature *)createSignature:(NSString *)peerId watchedPeerIds:(NSArray *)watchedPeerIds AV_DEPRECATED("2.6.4");
- (AVSignature *)createSessionSignature:(NSString *)peerId watchedPeerIds:(NSArray *)watchedPeerIds action:(NSString *)action AV_DEPRECATED("2.6.4");
- (AVSignature *)createGroupSignature:(NSString *)peerId groupPeerIds:(NSArray *)groupPeerIds action:(NSString *)action AV_DEPRECATED("2.6.4");
- (AVSignature *)createGroupSignature:(NSString *)peerId groupId:(NSString *)groupId groupPeerIds:(NSArray *)groupPeerIds action:(NSString *)action AV_DEPRECATED("2.6.4");
@end

NS_ASSUME_NONNULL_END
