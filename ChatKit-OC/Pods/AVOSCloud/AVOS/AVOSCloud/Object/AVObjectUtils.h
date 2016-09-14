//
//  AVObjectUtils.h
//  AVOSCloud
//
//  Created by Zhu Zeng on 7/4/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVGlobal.h"
#import "AVGeoPoint.h"
#import "AVACL.h"
#import "AVObject.h"

@interface AVObjectUtils : NSObject


#pragma mark - Simple objecitive-c object from cloud side dictionary
+(NSString *)stringFromDate:(NSDate *)date;
+(NSDate *)dateFromDictionary:(NSDictionary *)dict;
+(NSDate *)dateFromString:(NSString *)string;
+(NSData *)dataFromDictionary:(NSDictionary *)dict;
+(AVGeoPoint *)geoPointFromDictionary:(NSDictionary *)dict;
+(AVACL *)aclFromDictionary:(NSDictionary *)dict;
+(NSObject *)objectFromDictionary:(NSDictionary *)dict;
+(NSArray *)arrayFromArray:(NSArray *)array;

#pragma mark - Update Objecitive-c object from server side dictionary
+(void)copyDictionary:(NSDictionary *)src
             toObject:(AVObject *)target;

#pragma mark - Cloud side dictionary representation of objective-c object.
+(NSMutableDictionary *)dictionaryFromDictionary:(NSDictionary *)dic;
+(NSMutableArray *)dictionaryFromArray:(NSArray *)array;
+(NSDictionary *)dictionaryFromAVObjectPointer:(AVObject *)object;
+(NSDictionary *)dictionaryFromGeoPoint:(AVGeoPoint *)point;
+(NSDictionary *)dictionaryFromDate:(NSDate *)date;
+(NSDictionary *)dictionaryFromData:(NSData *)data;
+(NSDictionary *)dictionaryFromFile:(AVFile *)file;
+(NSDictionary *)dictionaryFromACL:(AVACL *)acl;
+ (id)dictionaryFromObject:(id)obj;
+ (id)dictionaryFromObject:(id)obj topObject:(BOOL)topObject;
+(NSDictionary *)childDictionaryFromAVObject:(AVObject *)object
                                     withKey:(NSString *)key;

#pragma mark - Object snapshot, usually for local cache.

+ (id)snapshotDictionary:(id)object;
+ (id)snapshotDictionary:(id)object recursive:(BOOL)recursive;

+ (NSMutableDictionary *)objectSnapshot:(AVObject *)object;
+ (NSMutableDictionary *)objectSnapshot:(AVObject *)object recursive:(BOOL)recursive;

+(AVObject *)avobjectFromDictionary:(NSDictionary *)dict;
+(AVObject *)avObjectForClass:(NSString *)className;
+(AVObject *)targetObjectFromRelationDictionary:(NSDictionary *)dict;

+(NSSet *)allAVObjectProperties:(Class)objectClass;

#pragma mark - Rebuild Relation
+(void)setupRelation:(AVObject *)parent
      withDictionary:(NSDictionary *)relationMap;


#pragma mark - batch request from operation list
+(BOOL)isUserClass:(NSString *)className;
+(BOOL)isRoleClass:(NSString *)className;
+(BOOL)isFileClass:(NSString *)className;
+(BOOL)isInstallationClass:(NSString *)className;
+(NSString *)objectPath:(NSString *)className
                   objectId:(NSString *)objectId;

#pragma mark - Array utils
+(BOOL)safeAdd:(NSDictionary *)dict
       toArray:(NSMutableArray *)array;

#pragma mark - key utils
+(BOOL)hasAnyKeys:(id)object;

+(NSString *)batchPath;
+(NSString *)batchSavePath;

@end
