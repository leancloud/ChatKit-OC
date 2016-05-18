//
//  LCCKSignatureService.h
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Service for pinning signature to actions.

#import <Foundation/Foundation.h>
#import "LCCKServiceDefinition.h"

/*!
 * LCCKSignatureService Error Domain
 */
FOUNDATION_EXTERN NSString *const LCCKSignatureServiceErrorDomain;

@interface LCCKSignatureService : LCCKSingleton <LCCKSignatureService>

@end
