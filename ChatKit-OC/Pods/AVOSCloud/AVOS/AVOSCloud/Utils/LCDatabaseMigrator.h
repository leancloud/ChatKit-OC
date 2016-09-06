//
//  LCDatabaseMigrator.h
//  AVOS
//
//  Created by Tang Tianyong on 6/1/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCDatabaseCommon.h"

/*!
 * Database migration object.
 */
@interface LCDatabaseMigration : NSObject

/*!
 * The job of current migration.
 */
@property (readonly) LCDatabaseJob block;

+ (instancetype)migrationWithBlock:(LCDatabaseJob)block;

- (instancetype)initWithBlock:(LCDatabaseJob)block;

@end

/*!
 * SQLite database migrator.
 */
@interface LCDatabaseMigrator : NSObject

@property (readonly) NSString *databasePath;

- (instancetype)initWithDatabasePath:(NSString *)databasePath;

/*!
 * Migrate database with migrations.
 * @param migrations An array of object confirms LCDatabaseMigration protocol.
 * NOTE: migration can not be removed, only can be added.
 * @return void.
 */
- (void)executeMigrations:(NSArray *)migrations;

@end
