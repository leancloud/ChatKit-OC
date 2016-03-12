//
//  LCIMContactManager.m
//  LeanCloudIMKit-iOS
//
//  Created by 陈宜龙 on 16/3/10.
//  Copyright © 2016年 EloncChan. All rights reserved.
//

#import "LCIMContactManager.h"
#import "LCIMConstants.h"

#define __LCIMContactsOfDevelopers \
@[ \
    @"uid1", \
    @"uid2", \
    @"uid3", \
    @"uid4", \
    @"uid5", \
    @"uid6", \
    @"uid7", \
    @"uid8", \
    @"uid9", \
    @"uid10", \
]

#define __LCIMContactsOfSections \
@[ \
    LCIMWorkerPeerIds, \
    __LCIMContactsOfDevelopers, \
]

@interface LCIMContactManager ()

@property (strong, nonatomic) NSMutableArray *contactIDs;

@end

@implementation LCIMContactManager
/**
 * create a singleton instance of LCIMContactManager
 */
+ (instancetype)defaultManager {
    static LCIMContactManager *_sharedLCIMContactManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLCIMContactManager = [[self alloc] init];
    });
    return _sharedLCIMContactManager;
}


- (NSMutableArray *)contactIDs {
    if (!_contactIDs) {
        _contactIDs = [NSMutableArray arrayWithContentsOfFile:[self storeFilePath]];
        if (!_contactIDs) {
            _contactIDs = [NSMutableArray array];
            for (NSArray *contacts in __LCIMContactsOfSections) {
                [_contactIDs addObjectsFromArray:contacts];
            }
            [_contactIDs writeToFile:[self storeFilePath] atomically:YES];
        }
    }
    return _contactIDs;
}

- (NSArray *)fetchContactPeerIds {
    return self.contactIDs;
}
- (BOOL)existContactForPeerId:(NSString *)peerId {
    return [self.contactIDs containsObject:peerId];
}

- (BOOL)addContactForPeerId:(NSString *)peerId {
    if (!peerId) {
        return NO;
    }
    [self.contactIDs addObject:peerId];
    return [self saveContactIDs];
}
- (BOOL)removeContactForPeerId:(NSString *)peerId {
    if (!peerId) {
        return NO;
    }
    if (![self existContactForPeerId:peerId]) {
        return NO;
    }
    
    [self.contactIDs removeObject:peerId];
    
    return [self saveContactIDs];
}

- (BOOL)saveContactIDs {
    if (_contactIDs) {
        return [_contactIDs writeToFile:[self storeFilePath] atomically:YES];
    }
    return YES;
}

- (NSString *)storeFilePath {
    NSString* path = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"LCIMContacts.plist"];
    return path;
}

@end
