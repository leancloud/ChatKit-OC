//
//  AVIMConversationUpdateBuilder.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 1/8/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMConversationUpdateBuilder.h"
#import "AVIMConversationUpdateBuilder_Internal.h"
#import "AVIMDynamicObject.h"
#import "AVIMConversation_Internal.h"
#import "AVIMBlockHelper.h"

@implementation AVIMConversationUpdateBuilder

-(instancetype)init {
    if ((self = [super init])) {
        self.object = [[AVIMDynamicObject alloc] init];
    }
    return self;
}

- (NSDictionary *)dictionary {
    return [self.object dictionary];
}

-(NSString *)name {
    return [self.object objectForKey:KEY_NAME];
}

-(void)setName:(NSString *)name {
    [self.object setObject:name forKey:KEY_NAME];
}

-(NSDictionary *)attributes {
    return [[self.object objectForKey:KEY_ATTR] dictionary];
}

-(void)setAttributes:(NSDictionary *)attributes {
    AVIMDynamicObject *attrs = [[AVIMDynamicObject alloc] initWithDictionary:attributes];
    [self.object setObject:attrs forKey:KEY_ATTR];
}

-(void)setObject:(id)object forKey:(NSString *)key {
    AVIMDynamicObject *o = [self.object objectForKey:KEY_ATTR];
    if (!o) {
        o = [[AVIMDynamicObject alloc] init];
        [self.object setObject:o forKey:KEY_ATTR];
    }
    [o setObject:object forKey:key];
}

-(id)objectForKey:(NSString *)key {
    AVIMDynamicObject *o = [self.object objectForKey:KEY_ATTR];
    return [o objectForKey:key];
}

-(void)removeObjectForKey:(NSString *)key {
    AVIMDynamicObject *o = [self.object objectForKey:KEY_ATTR];
    [o removeObjectForKey:key];
}

@end
