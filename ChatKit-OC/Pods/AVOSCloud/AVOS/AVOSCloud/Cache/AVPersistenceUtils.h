//
//  AVPersistenceUtils.h
//  paas
//
//  Created by Summer on 13-3-25.
//  Copyright (c) 2013年 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>   

@interface AVPersistenceUtils : NSObject

+ (NSString *)avCacheDirectory;
+ (NSString *)avFileDirectory;

+ (NSString *)currentUserArchivePath;
+ (NSString *)currentUserClassArchivePath;
+ (NSString *)currentInstallationArchivePath;

+ (NSString *)eventuallyPath;

+ (NSString *)messageCachePath;
+ (NSString *)messageCacheDatabasePathWithName:(NSString *)name;

+ (NSString *)keyValueDatabasePath;
+ (NSString *)commandCacheDatabasePath;
+ (NSString *)clientSessionTokenCacheDatabasePath;

+ (BOOL)saveJSON:(id)JSON toPath:(NSString *)path;
+ (id)getJSONFromPath:(NSString *)path;

+(BOOL)removeFile:(NSString *)path;
+(BOOL)fileExist:(NSString *)path;
+(BOOL)createFile:(NSString *)path;

+ (BOOL)deleteFilesInDirectory:(NSString *)dirPath moreThanDays:(NSInteger)numberOfDays;
+ (NSDate *)lastModified:(NSString *)fullPath;

@end
