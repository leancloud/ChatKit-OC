//
//  LCCKSignatureService.m
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKSignatureService.h"

NSString *const LCCKSignatureServiceErrorDomain = @"LCCKSignatureServiceErrorDomain";

@implementation LCCKSignatureService
@synthesize generateSignatureBlock = _generateSignatureBlock;

- (void)setGenerateSignatureBlock:(LCCKGenerateSignatureBlock)generateSignatureBlock {
    _generateSignatureBlock = generateSignatureBlock;
}

@end
