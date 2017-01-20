//
//  LCIMCacheStore.m
//  AVOS
//
//  Created by Tang Tianyong on 8/29/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "LCIMCacheStore.h"
#import "AVPersistenceUtils.h"

@interface LCIMCacheStore ()

@property (copy, readwrite) NSString *clientId;

@end

@implementation LCIMCacheStore {
    LCDatabaseQueue *_databaseQueue;
}

+ (NSString *)databasePathWithName:(NSString *)name {
    return [AVPersistenceUtils messageCacheDatabasePathWithName:name];
}

- (instancetype)initWithClientId:(NSString *)clientId {
    self = [super init];

    if (self) {
        _clientId = [clientId copy];
    }

    return self;
}

- (LCDatabaseQueue *)databaseQueue {
    @synchronized(self) {
        if (_databaseQueue)
            return _databaseQueue;

        if (self.clientId) {
            NSString *path = [[self class] databasePathWithName:self.clientId];
            _databaseQueue = [LCDatabaseQueue databaseQueueWithPath:path];

            if (_databaseQueue) {
                [self databaseQueueDidLoad];
            }
        }
    }

    return _databaseQueue;
}

- (void)databaseQueueDidLoad {
    // Stub
}

- (void)dealloc {
    [_databaseQueue close];
}

@end
