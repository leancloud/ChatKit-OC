//
//  LCIMSignatureService.m
//  LeanCloudIMKit-iOS
//
//  Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCIMSignatureService.h"

@interface LCIMSignatureService ()

@property (nonatomic, copy, readwrite) LCIMSignatureInfoBlock signatureInfoBlock;

@end

@implementation LCIMSignatureService

- (void)setSignatureInfoBlock:(LCIMSignatureInfoBlock)signatureInfoBlock {
    _signatureInfoBlock = signatureInfoBlock;
}

@end
