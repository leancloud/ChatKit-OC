//
//  LCCKSignatureService.m
//  LeanCloudChatKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKSignatureService.h"

NSString *const LCCKSignatureServiceErrorDomain = @"LCCKSignatureServiceErrorDomain";

@interface LCCKSignatureService ()

@property (nonatomic, copy, readwrite) LCCKGenerateSignatureBlock generateSignatureBlock;

@end

@implementation LCCKSignatureService

- (void)setGenerateSignatureBlock:(LCCKGenerateSignatureBlock)generateSignatureBlock {
    _generateSignatureBlock = generateSignatureBlock;
}

@end
