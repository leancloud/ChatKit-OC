//
//  AVIMKeyedConversation.m
//  AVOS
//
//  Created by Tang Tianyong on 6/12/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMKeyedConversation.h"
#import "AVIMKeyedConversation_internal.h"
#import "AVIMClient_Internal.h"
#import "AVIMConversation.h"
#import "AVIMConversation_Internal.h"

#define LC_SEL_STR(sel) (NSStringFromSelector(@selector(sel)))

@implementation AVIMKeyedConversation

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self) {
        self.conversationId = [aDecoder decodeObjectForKey:LC_SEL_STR(conversationId)];
        self.clientId       = [aDecoder decodeObjectForKey:LC_SEL_STR(clientId)];
        self.creator        = [aDecoder decodeObjectForKey:LC_SEL_STR(creator)];
        self.createAt       = [aDecoder decodeObjectForKey:LC_SEL_STR(createAt)];
        self.updateAt       = [aDecoder decodeObjectForKey:LC_SEL_STR(updateAt)];
        self.lastMessageAt  = [aDecoder decodeObjectForKey:LC_SEL_STR(lastMessageAt)];
        self.name           = [aDecoder decodeObjectForKey:LC_SEL_STR(name)];
        self.members        = [aDecoder decodeObjectForKey:LC_SEL_STR(members)];
        self.attributes     = [aDecoder decodeObjectForKey:LC_SEL_STR(attributes)];
        self.transient      = [aDecoder decodeBoolForKey:LC_SEL_STR(transient)];
        self.muted          = [aDecoder decodeBoolForKey:LC_SEL_STR(muted)];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.conversationId forKey:LC_SEL_STR(conversationId)];
    [aCoder encodeObject:self.clientId       forKey:LC_SEL_STR(clientId)];
    [aCoder encodeObject:self.creator        forKey:LC_SEL_STR(creator)];
    [aCoder encodeObject:self.createAt       forKey:LC_SEL_STR(createAt)];
    [aCoder encodeObject:self.updateAt       forKey:LC_SEL_STR(updateAt)];
    [aCoder encodeObject:self.lastMessageAt  forKey:LC_SEL_STR(lastMessageAt)];
    [aCoder encodeObject:self.name           forKey:LC_SEL_STR(name)];
    [aCoder encodeObject:self.members        forKey:LC_SEL_STR(members)];
    [aCoder encodeObject:self.attributes     forKey:LC_SEL_STR(attributes)];
    [aCoder encodeBool:self.transient        forKey:LC_SEL_STR(transient)];
    [aCoder encodeBool:self.muted            forKey:LC_SEL_STR(muted)];
}

@end
