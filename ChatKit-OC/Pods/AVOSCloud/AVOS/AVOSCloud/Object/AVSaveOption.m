//
//  AVSaveOption.m
//  AVOS
//
//  Created by Tang Tianyong on 1/12/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import "AVSaveOption.h"
#import "AVSaveOption_internal.h"
#import "AVQuery.h"
#import "AVQuery_Internal.h"

@implementation AVSaveOption

- (NSDictionary *)dictionary {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    if (self.fetchWhenSave)
        result[@"fetchWhenSave"] = @(YES);

    if (self.query)
        result[@"where"] = [self.query whereJSONDictionary];

    return result;
}

@end
