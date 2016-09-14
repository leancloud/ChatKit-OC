//
//  NSFileManager+LCCKExtension.h
//  Pods
//
//  Created by 陈宜龙 on 16/8/24.
//
//

#import <Foundation/Foundation.h>

@interface NSFileManager (LCCKExtension)

/**
 Get URL of Documents directory.
 
 @return Documents directory URL.
 */
+ (NSURL *)lcck_documentsURL;

/**
 Get path of Documents directory.
 
 @return Documents directory path.
 */
+ (NSString *)lcck_documentsPath;

/**
 Get URL of Library directory.
 
 @return Library directory URL.
 */
+ (NSURL *)lcck_libraryURL;

/**
 Get path of Library directory.
 
 @return Library directory path.
 */
+ (NSString *)lcck_libraryPath;

/**
 Get URL of Caches directory.
 
 @return Caches directory URL.
 */
+ (NSURL *)lcck_cachesURL;

/**
 Get path of Caches directory.
 
 @return Caches directory path.
 */
+ (NSString *)lcck_cachesPath;

/**
 Adds a special filesystem flag to a file to avoid iCloud backup it.
 
 @param path Path to a file to set an attribute.
 */
+ (BOOL)lcck_addSkipBackupAttributeToFile:(NSString *)lcck_path;

/**
 Get available disk space.
 
 @return An amount of available disk space in Megabytes.
 */
+ (double)lcck_availableDiskSpace;

@end
