//
//  LCIMSignatureService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMSignatureService.h"

NSString *const LCIMSignatureServiceErrorDomain = @"LCIMSignatureServiceErrorDomain";

@interface LCIMSignatureService ()

@property (nonatomic, copy, readwrite) LCIMGenerateSignatureBlock generateSignatureBlock;

@end

@implementation LCIMSignatureService

/**
 * create a singleton instance of LCIMSignatureService
 */
+ (instancetype)sharedInstance {
    static LCIMSignatureService *_sharedLCIMSignatureService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLCIMSignatureService = [[self alloc] init];
    });
    return _sharedLCIMSignatureService;
}

- (void)setGenerateSignatureBlock:(LCIMGenerateSignatureBlock)generateSignatureBlock {
    _generateSignatureBlock = generateSignatureBlock;
}

@end
