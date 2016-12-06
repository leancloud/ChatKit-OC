//
//  AVPersistenceUtils.m
//  paas
//
//  Created by Summer on 13-3-25.
//  Copyright (c) 2013年 AVOS. All rights reserved.
//

#import "AVPersistenceUtils.h"
#import "AVUtils.h"

#define LCRootDirName @"LeanCloud"
#define LCMessageCacheDirName @"MessageCache"

@implementation AVPersistenceUtils

#pragma mark - Base Path

/// Base path, all paths depend it
+ (NSString *)homeDirectoryPath {
#if AV_IOS_ONLY
    return NSHomeDirectory();
#else
    return [self osxBaseDirectoryPath];
#endif
}

/// ~/Library/Application Support/LeanCloud/appId
+ (NSString *)osxBaseDirectoryPath {
    NSAssert([AVOSCloud getApplicationId] != nil, @"Please call +[AVOSCloud setApplicationId:clientKey:] first.");
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = [paths firstObject];
    directoryPath = [directoryPath stringByAppendingPathComponent:LCRootDirName];
    directoryPath = [directoryPath stringByAppendingPathComponent:[AVOSCloud getApplicationId]];
    [self createDirectoryIfNeeded:directoryPath];
    return directoryPath;
}

#pragma mark - ~/Documents

// ~/Documents
+ (NSString *)appDocumentPath {
    static NSString *path = nil;
    
    if (!path) {
        path = [[self homeDirectoryPath] stringByAppendingPathComponent:@"Documents"];
    }
    
    return path;
}

// ~/Documents/LeanCloud
+ (NSString *)leanDocumentPath {
    NSString *path = [self appDocumentPath];
    
    path = [path stringByAppendingPathComponent:LCRootDirName];
    
    [self createDirectoryIfNeeded:path];
    
    return path;
}

// ~/Documents/LeanCloud/keyvalue
+ (NSString *)keyValueDatabasePath {
    return [[self leanDocumentPath] stringByAppendingPathComponent:@"keyvalue"];
}

// ~/Documents/LeanCloud/CommandCache
+ (NSString *)commandCacheDatabasePath {
    return [[self leanDocumentPath] stringByAppendingPathComponent:@"CommandCache"];
}

+ (NSString *)clientSessionTokenCacheDatabasePath {
    return [[self leanDocumentPath] stringByAppendingPathComponent:@"ClientSessionToken"];
}

#pragma mark - ~/Library/Caches

// ~/Library/Caches
+ (NSString *)appCachePath {
    static NSString *path = nil;
    
    if (!path) {
        path = [[self homeDirectoryPath] stringByAppendingPathComponent:@"Library"];
        path = [path stringByAppendingPathComponent:@"Caches"];
    }
    
    return path;
}

// ~/Library/Caches/AVPaasCache, for AVCacheManager
+ (NSString *)avCacheDirectory {
    NSString *ret = [[AVPersistenceUtils appCachePath] stringByAppendingPathComponent:@"AVPaasCache"];
    [self createDirectoryIfNeeded:ret];
    return ret;
}

// ~/Library/Caches/AVPaasFiles
+ (NSString *)avFileDirectory {
    NSString *ret = [[AVPersistenceUtils appCachePath] stringByAppendingPathComponent:@"AVPaasFiles"];
    [self createDirectoryIfNeeded:ret];
    return ret;
}

// ~/Library/Caches/LeanCloud/MessageCache
+ (NSString *)messageCachePath {
    NSString *path = [self appCachePath];
    
    path = [path stringByAppendingPathComponent:LCRootDirName];
    path = [path stringByAppendingPathComponent:LCMessageCacheDirName];
    
    [self createDirectoryIfNeeded:path];
    
    return path;
}

// ~/Library/Caches/LeanCloud/MessageCache/databaseName
+ (NSString *)messageCacheDatabasePathWithName:(NSString *)name {
    if (name) {
        return [[self messageCachePath] stringByAppendingPathComponent:name];
    }
    
    return nil;
}

#pragma mark - ~/Libraray/Private Documents

// ~/Library
+ (NSString *)libraryDirectory {
    static NSString *path = nil;
    if (!path) {
        path = [[self homeDirectoryPath] stringByAppendingPathComponent:@"Library"];
    }
    return path;
}

// ~/Library/Private Documents/AVPaas
+ (NSString *)privateDocumentsDirectory {
    NSString *ret = [[AVPersistenceUtils libraryDirectory] stringByAppendingPathComponent:@"Private Documents/AVPaas"];
    [self createDirectoryIfNeeded:ret];
    return ret;
}

#pragma mark -  Private Documents Concrete Path

+ (NSString *)currentUserArchivePath {
    NSString * path = [[AVPersistenceUtils privateDocumentsDirectory] stringByAppendingString:@"/currentUser"];
    return path;
}

+ (NSString *)currentUserClassArchivePath {
    NSString *path = [[AVPersistenceUtils privateDocumentsDirectory] stringByAppendingString:@"/currentUserClass"];
    return path;
}

+ (NSString *)currentInstallationArchivePath {
    NSString *path = [[AVPersistenceUtils privateDocumentsDirectory] stringByAppendingString:@"/currentInstallation"];
    return path;
}

+ (NSString *)eventuallyPath {
    NSString *ret = [[AVPersistenceUtils privateDocumentsDirectory] stringByAppendingPathComponent:@"OfflineRequests"];
    [self createDirectoryIfNeeded:ret];
    return ret;
}

#pragma mark - File Utils

+ (BOOL)saveJSON:(id)JSON toPath:(NSString *)path {
    if ([JSON isKindOfClass:[NSDictionary class]] || [JSON isKindOfClass:[NSArray class]]) {
        return [NSKeyedArchiver archiveRootObject:JSON toFile:path];
    }
    
    return NO;
}

+ (id)getJSONFromPath:(NSString *)path {
    id JSON = nil;
    @try {
        JSON=[NSKeyedUnarchiver unarchiveObjectWithFile:path];
        
        if ([JSON isMemberOfClass:[NSDictionary class]] || [JSON isMemberOfClass:[NSArray class]]) {
            return JSON;
        }
    }
    @catch (NSException *exception) {
        //deal with the previous file version
        if ([[exception name] isEqualToString:NSInvalidArgumentException]) {
            JSON = [NSMutableDictionary dictionaryWithContentsOfFile:path];
            
            if (!JSON) {
                JSON = [NSMutableArray arrayWithContentsOfFile:path];
            }
        }
    }
    
    return JSON;
}

+(BOOL)removeFile:(NSString *)path
{
    NSError * error = nil;
    BOOL ret = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    return ret;
}

+(BOOL)fileExist:(NSString *)path
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+(BOOL)createFile:(NSString *)path
{
    BOOL ret = [[NSFileManager defaultManager] createFileAtPath:path contents:[NSData data] attributes:nil];
    return ret;
}

+ (void)createDirectoryIfNeeded:(NSString *)path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
}

+ (BOOL)deleteFilesInDirectory:(NSString *)dirPath moreThanDays:(NSInteger)numberOfDays {
    BOOL success = NO;
    
    NSDate *nowDate = [NSDate date];
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    NSError *error = nil;
    NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:dirPath error:&error];
    if (error == nil) {
        for (NSString *path in directoryContents) {
            NSString *fullPath = [dirPath stringByAppendingPathComponent:path];
            NSDate *lastModified = [AVPersistenceUtils lastModified:fullPath];
            if ([nowDate timeIntervalSinceDate:lastModified] < numberOfDays * 24 * 3600)
                continue;
            
            BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
            if (!removeSuccess) {
                AVLoggerE(@"remove error happened");
                success = NO;
            }
        }
    } else {
        AVLoggerE(@"remove error happened");
        success = NO;
    }
    
    return success;
}

// assume the file is exist
+ (NSDate *)lastModified:(NSString *)fullPath {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:NULL];
    return [fileAttributes fileModificationDate];
}

@end
