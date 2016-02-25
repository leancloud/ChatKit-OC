//
//  LCIMSignatureService.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Service for pinning signature to actions.

#import <Foundation/Foundation.h>
#import "LCIMServiceDefinition.h"

@interface LCIMSignatureService : NSObject

@property (nonatomic, copy, readonly) LCIMSignatureInfoBlock signatureInfoBlock;

/*!
 * @brief Add the ablitity to pin signature to these actions: open, start(create conversation), kick, invite.
 * @attention  If implemeted, this block will be invoked automatically for pinning signature to these actions: open, start(create conversation), kick, invite.
 */
- (void)setSignatureInfoBlock:(LCIMSignatureInfoBlock)signatureInfoBlock;

@end
