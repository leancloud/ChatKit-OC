//
//  NSMutableDictionary+LCCKWeakReference.m
//  Kuber
//
//  Created by Kuber on 16/4/29.
//  Copyright © 2016年 Huaxu Technology. All rights reserved.
//

#import "NSMutableDictionary+LCCKWeakReference.h"
#import "LCCKWeakReference.h"

@implementation NSMutableDictionary (LCCKWeakReference)

- (void)lcckweak_setObject:(id)anObject forKey:(NSString *)aKey {
    [self setObject:makeLCCKWeakReference(anObject) forKey:aKey];
}

- (void)lcckweak_setObjectWithDictionary:(NSDictionary *)dictionary {
    for (NSString *key in dictionary.allKeys) {
        [self setObject:makeLCCKWeakReference(dictionary[key]) forKey:key];
    }
}

- (id)lcckweak_getObjectForKey:(NSString *)key {
    return weakReferenceNonretainedObjectValue(self[key]);
}

@end
