//
//  LCDatabaseMigrator.m
//  AVOS
//
//  Created by Tang Tianyong on 6/1/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "LCDatabaseMigrator.h"
#import "LCDatabaseCoordinator.h"
#import "LCDatabase.h"
#import "LCDatabaseAdditions.h"

#import <libkern/OSAtomic.h>

@interface LCDatabaseMigrator () {
    LCDatabaseCoordinator *_coordinator;
    OSSpinLock _coordinatorLock;
}

@property (readonly) LCDatabaseCoordinator *coordinator;

@end

@implementation LCDatabaseMigrator

- (instancetype)init {
    self = [super init];

    if (self) {
        _coordinatorLock = OS_SPINLOCK_INIT;
    }

    return self;
}

- (instancetype)initWithDatabasePath:(NSString *)databasePath {
    self = [super init];

    if (self) {
        _databasePath = [databasePath copy];
    }

    return self;
}

- (NSInteger)versionOfDatabase {
    __block NSInteger version = 0;

    [self.coordinator executeJob:^(LCDatabase *db) {
        version = (NSInteger)[db userVersion];
    }];

    return version;
}

- (void)applyMigrations:(NSArray *)migrations
            fromVersion:(uint32_t)fromVersion
               database:(LCDatabase *)database
{
    for (LCDatabaseMigration *migration in migrations) {
        if (migration.block) {
            migration.block(database);
        }

        [database setUserVersion:++fromVersion];
    }
}

- (void)executeMigrations:(NSArray *)migrations {
    uint32_t newVersion = (uint32_t)[migrations count];
    uint32_t oldVersion = (uint32_t)[self versionOfDatabase];

    if (oldVersion < newVersion) {
        NSArray *restMigrations = [migrations subarrayWithRange:NSMakeRange(oldVersion, newVersion - oldVersion)];

        [self.coordinator
         executeTransaction:^(LCDatabase *db) {
             [self applyMigrations:restMigrations fromVersion:oldVersion database:db];
         }
         fail:^(LCDatabase *db) {
             [db setUserVersion:oldVersion];
         }];
    }
}

#pragma mark - Lazy loading

- (LCDatabaseCoordinator *)coordinator {
    OSSpinLockLock(&_coordinatorLock);

    if (!_coordinator) {
        _coordinator = [[LCDatabaseCoordinator alloc] initWithDatabasePath:_databasePath];
    }

    OSSpinLockUnlock(&_coordinatorLock);

    return _coordinator;
}

@end

@implementation LCDatabaseMigration

+ (instancetype)migrationWithBlock:(LCDatabaseJob)block {
    return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(LCDatabaseJob)block {
    self = [super init];

    if (self) {
        _block = [block copy];
    }

    return self;
}

@end
