//
//  LCIMSignatureService.h
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Service for pinning signature to actions.

#import <Foundation/Foundation.h>
#import "LCIMServiceDefinition.h"

/*!
 * LCIMSignatureService Error Domain
 */
FOUNDATION_EXTERN NSString *const LCIMSignatureServiceErrorDomain;

@interface LCIMSignatureService : NSObject <LCIMSignatureService>

+ (instancetype)sharedInstance;

@end
