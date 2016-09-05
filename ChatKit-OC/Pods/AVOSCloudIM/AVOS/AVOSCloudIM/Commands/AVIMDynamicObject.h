//
//  AVIMDynamicObject.h
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/4/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVIMDynamicObject : NSObject
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithMutableDictionary:(NSMutableDictionary *)dictionary;
- (instancetype)initWithJSON:(NSString *)json;
- (instancetype)initWithMessagePack:(NSData *)data;
- (NSString *)JSONString;
- (NSDictionary *)dictionary;
- (NSData *)messagePack;

- (BOOL)hasKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
@end
