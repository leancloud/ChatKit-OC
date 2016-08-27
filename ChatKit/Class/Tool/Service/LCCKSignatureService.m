//
//  LCCKSignatureService.m
//  LeanCloudChatKit-iOS
//
//  v0.7.0 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/2/22.
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
