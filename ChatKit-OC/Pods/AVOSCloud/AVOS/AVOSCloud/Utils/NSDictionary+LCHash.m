//
//  NSDictionary+LCHash.m
//  AVOS
//
//  Created by Tang Tianyong on 7/15/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "NSDictionary+LCHash.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSDictionary (LCHash)

- (NSString *)lc_SHA1String {
    NSMutableArray *orderedKeyValues = [NSMutableArray array];
    NSArray *orderedKeys = [[self allKeys] sortedArrayUsingSelector:@selector(compare:)];

    for (NSString *key in orderedKeys) {
        [orderedKeyValues addObject:@[key, self[key]]];
    }

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:orderedKeyValues];

    unsigned int size = CC_SHA1_DIGEST_LENGTH;
    unsigned char output[size];

    CC_SHA1(data.bytes, (unsigned int)data.length, output);

    NSMutableString* hash = [NSMutableString stringWithCapacity:size * 2];

    for (unsigned int i = 0; i < size; i++) {
        [hash appendFormat:@"%02x", output[i]];
    }

    return hash;
}

@end
