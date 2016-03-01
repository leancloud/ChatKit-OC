//
//  LCIMSignatureService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMSignatureService.h"

@interface LCIMSignatureService ()

@property (nonatomic, copy, readwrite) LCIMGenerateSignatureBlock generateSignatureBlock;

@end

@implementation LCIMSignatureService

- (void)setGenerateSignatureBlock:(LCIMGenerateSignatureBlock)generateSignatureBlock {
    _generateSignatureBlock = generateSignatureBlock;
}

@end
