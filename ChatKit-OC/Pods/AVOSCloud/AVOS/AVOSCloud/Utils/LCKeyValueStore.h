//
//  LCKeyValueStore.h
//  AVOS
//
//  Created by Tang Tianyong on 6/26/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LCKeyValueStore : NSObject

+ (instancetype)sharedInstance;

- (instancetype)initWithDatabasePath:(NSString *)databasePath;

- (instancetype)initWithDatabasePath:(NSString *)databasePath tableName:(NSString *)tableName;

- (NSData *)dataForKey:(NSString *)key;

- (void)setData:(NSData *)data forKey:(NSString *)key;

- (void)deleteKey:(NSString *)key;

@end
