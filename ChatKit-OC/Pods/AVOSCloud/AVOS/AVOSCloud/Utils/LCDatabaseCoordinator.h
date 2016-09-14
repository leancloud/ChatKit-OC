//
//  LCDatabaseCoordinator.h
//  AVOS
//
//  Created by Tang Tianyong on 6/1/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LCDatabaseCommon.h"

@interface LCDatabaseCoordinator : NSObject

@property (readonly) NSString *databasePath;

- (instancetype)initWithDatabasePath:(NSString *)databasePath;

- (void)executeTransaction:(LCDatabaseJob)job fail:(LCDatabaseJob)fail;

- (void)executeJob:(LCDatabaseJob)job;

@end
