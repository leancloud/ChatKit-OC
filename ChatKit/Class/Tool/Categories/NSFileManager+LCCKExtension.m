//
//  NSFileManager+LCCKExtension.m
//  Pods
//
//  Created by 陈宜龙 on 16/8/24.
//
//

#import "NSFileManager+LCCKExtension.h"
#include <sys/xattr.h>

@implementation NSFileManager (LCCKExtension)

+ (NSURL *)lcck_URLForDirectory:(NSSearchPathDirectory)directory {
    return [self.defaultManager URLsForDirectory:directory inDomains:NSUserDomainMask].lastObject;
}

+ (NSString *)lcck_pathForDirectory:(NSSearchPathDirectory)directory {
    return NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES)[0];
}

+ (NSURL *)lcck_documentsURL {
    return [self lcck_URLForDirectory:NSDocumentDirectory];
}

+ (NSString *)lcck_documentsPath {
    return [self lcck_pathForDirectory:NSDocumentDirectory];
}

+ (NSURL *)lcck_libraryURL {
    return [self lcck_URLForDirectory:NSLibraryDirectory];
}

+ (NSString *)lcck_libraryPath {
    return [self lcck_pathForDirectory:NSLibraryDirectory];
}

+ (NSURL *)lcck_cachesURL {
    return [self lcck_URLForDirectory:NSCachesDirectory];
}

+ (NSString *)lcck_cachesPath {
    return [self lcck_pathForDirectory:NSCachesDirectory];
}

+ (BOOL)lcck_addSkipBackupAttributeToFile:(NSString *)path {
    return [[NSURL.alloc initFileURLWithPath:path] setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:nil];
}

+ (double)lcck_availableDiskSpace {
    NSDictionary *attributes = [self.defaultManager attributesOfFileSystemForPath:self.lcck_documentsPath error:nil];
    return [attributes[NSFileSystemFreeSize] unsignedLongLongValue] / (double)0x100000;
}

@end
