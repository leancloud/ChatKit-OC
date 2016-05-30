//
//  NSMutableDictionary+LCCKWeakReference.h
//  Kuber
//
//  Created by Kuber on 16/4/29.
//  Copyright © 2016年 Huaxu Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (LCCKWeakReference)

- (void)lcckweak_setObject:(id)anObject forKey:(NSString *)aKey;

- (void)lcckweak_setObjectWithDictionary:(NSDictionary *)dic;

- (id)lcckweak_getObjectForKey:(NSString *)key;

@end
