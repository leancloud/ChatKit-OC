//
//  AVObjectUtils.m
//  AVOSCloud
//
//  Created by Zhu Zeng on 7/4/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <objc/runtime.h>
#import "AVObjectUtils.h"
#import "AVObject_Internal.h"
#import "AVFile.h"
#import "AVFile_Internal.h"
#import "AVObjectUtils.h"
#import "AVUser_Internal.h"
#import "AVACL_Internal.h"
#import "AVRelation.h"
#import "AVRole_Internal.h"
#import "AVInstallation_Internal.h"
#import "AVPaasClient.h"
#import "AVGeoPoint_Internal.h"
#import "AVRelation_Internal.h"
#import "AVUtils.h"

@implementation AVObjectUtils

#pragma mark - Check type

+(BOOL)isRelation:(NSString *)type
{
    return [type isEqualToString:@"Relation"];
}

/// The remote AVObject can be a pointer object or a normal object without pointer property
/// When adding AVObject, we have to check if it's a pointer or not.
+(BOOL)isRelationDictionary:(NSDictionary *)dict
{
    NSString * type = [dict objectForKey:@"__type"];
    if ([type isEqualToString:@"Relation"]) {
        return YES;
    }
    return NO;
}

+(BOOL)isPointerDictionary:(NSDictionary *)dict
{
    NSString * type = [dict objectForKey:@"__type"];
    if ([type isEqualToString:@"Pointer"]) {
        return YES;
    }
    return NO;
}

+(BOOL)isPointer:(NSString *)type
{
    return [type isEqualToString:@"Pointer"];
}

+(BOOL)isGeoPoint:(NSString *)type
{
    return [type isEqualToString:@"GeoPoint"];
}

+(BOOL)isACL:(NSString *)type
{
    return [type isEqualToString:ACLTag];
}

+(BOOL)isDate:(NSString *)type
{
    return [type isEqualToString:@"Date"];
}

+(BOOL)isData:(NSString *)type
{
    return [type isEqualToString:@"Bytes"];
}

+(BOOL)isFileFromUrulu:(NSDictionary *)dict
{
    // ugly way to check dict whether is avfile
    return ([dict objectForKey:@"mime_type"] != nil);
}

+(BOOL)isFile:(NSString *)type
{
    return [type isEqualToString:@"File"];
}

+(BOOL)isFilePointer:(NSDictionary *)dict {
    return ([[dict objectForKey:classNameTag] isEqualToString:@"_File"]);
}

+(BOOL)isAVObject:(NSDictionary *)dict
{
    // Should check for __type is Object ?
    return ([dict objectForKey:classNameTag] != nil);
}

#pragma mark - Simple objecitive-c object from server side dictionary

+(NSDateFormatter *)dateFormatter{
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:AV_DATE_FORMAT];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });
    
    return dateFormatter;
}

+(NSString *)stringFromDate:(NSDate *)date
{
    NSString *strDate = [[self.class dateFormatter] stringFromDate:date];
    return strDate;
}

+(NSDate *)dateFromString:(NSString *)string
{
    if (string == nil || [string isKindOfClass:[NSNull class]]) {
        return [NSDate date];
    }
    
    NSDate *date = [[self.class dateFormatter] dateFromString:string];

    return date;
}

+(NSDate *)dateFromDictionary:(NSDictionary *)dict
{
    return [AVObjectUtils dateFromString:[dict valueForKey:@"iso"]];
}

+(NSData *)dataFromDictionary:(NSDictionary *)dict
{
    NSString * string = [dict valueForKey:@"base64"];
    NSData * data = [NSData AVdataFromBase64String:string];
    return data;
}

+(AVGeoPoint *)geoPointFromDictionary:(NSDictionary *)dict
{
    AVGeoPoint * point = [[AVGeoPoint alloc]init];
    point.latitude = [[dict objectForKey:@"latitude"] doubleValue];
    point.longitude = [[dict objectForKey:@"longitude"] doubleValue];
    return point;
}

+(AVACL *)aclFromDictionary:(NSDictionary *)dict
{
    AVACL * acl = [AVACL ACL];
    acl.permissionsById = [dict mutableCopy];
    return acl;
}

+(NSArray *)arrayFromArray:(NSArray *)array
{
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:array.count];
    for (id obj in [array copy]) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [newArray addObject:[AVObjectUtils objectFromDictionary:obj]];
        } else if ([obj isKindOfClass:[NSArray class]]) {
            NSArray * sub = [AVObjectUtils arrayFromArray:obj];
            [newArray addObject:sub];
        } else {
            [newArray addObject:obj];
        }
    }
    return newArray;
}

+(NSObject *)objectFromDictionary:(NSDictionary *)dict
{
    NSString * type = [dict valueForKey:@"__type"];
    if ([AVObjectUtils isRelation:type])
    {
        return [AVObjectUtils targetObjectFromRelationDictionary:dict];
    }
    else if ([AVObjectUtils isPointer:type] ||
             [AVObjectUtils isAVObject:dict] )
    {
        // the backend stores AVFile as AVObject, but in sdk AVFile is not subclass
        // of AVObject, have to process the situation here.
        if ([AVObjectUtils isFilePointer:dict]) {
            return [AVFile fileFromDictionary:dict];
        }
        return [AVObjectUtils avobjectFromDictionary:dict];
    }
    else if ([AVObjectUtils isFile:type])
    {
        AVFile * file = [AVFile fileFromDictionary:dict];
        return file;
    }
    else if ([AVObjectUtils isFileFromUrulu:dict])
    {
        AVFile * file = [AVFile fileFromDictionary:dict];
        return file;
    }
    else if ([AVObjectUtils isGeoPoint:type])
    {
        AVGeoPoint * point = [AVObjectUtils geoPointFromDictionary:dict];
        return point;
    }
    else if ([AVObjectUtils isDate:type])
    {
        NSDate * date = [AVObjectUtils dateFromDictionary:dict];
        return date;
    }
    else if ([AVObjectUtils isData:type])
    {
        NSData * data = [AVObjectUtils dataFromDictionary:dict];
        return data;
    }
    return dict;
}

+ (NSObject *)objectFromDictionary:(NSDictionary *)dict recursive:(BOOL)recursive {
    if (recursive) {
        NSMutableDictionary *mutableDict = [dict mutableCopy];

        for (NSString *key in [dict allKeys]) {
            id object = dict[key];

            if ([object isKindOfClass:[NSDictionary class]]) {
                object = [self objectFromDictionary:object recursive:YES];
                mutableDict[key] = object;
            }
        }

        return [self objectFromDictionary:mutableDict];
    } else {
        return [self objectFromDictionary:dict];
    }
}

+(void)copyDictionary:(NSDictionary *)dict
             toTarget:(AVObject *)target
                  key:(NSString *)key
{
    NSString * type = [dict valueForKey:@"__type"];
    if ([AVObjectUtils isRelation:type])
    {
        // 解析 {"__type":"Relation","className":"_User"}，添加第一个来判断类型
        AVObject * object = [AVObjectUtils targetObjectFromRelationDictionary:dict];
        [target addRelation:object forKey:key submit:NO];
    }
    else if ([AVObjectUtils isPointer:type])
    {
        [target setObject:[AVObjectUtils objectFromDictionary:dict] forKey:key submit:NO];
    }
    else if ([AVObjectUtils isAVObject:dict]) {
        [target setObject:[AVObjectUtils objectFromDictionary:dict] forKey:key submit:NO];
    }
    else if ([AVObjectUtils isFile:type])
    {
        AVFile * file = [AVFile fileFromDictionary:dict];
        [target setObject:file forKey:key submit:NO];
    }
    else if ([AVObjectUtils isFileFromUrulu:dict])
    {
        AVFile * file = [AVFile fileFromDictionary:dict];
        [target setObject:file forKey:key submit:NO];
    }
    else if ([AVObjectUtils isGeoPoint:type])
    {
        AVGeoPoint * point = [AVGeoPoint geoPointFromDictionary:dict];
        [target setObject:point forKey:key submit:NO];
    }
    else if ([AVObjectUtils isACL:type] ||
             [AVObjectUtils isACL:key])
    {
        [target setObject:[AVObjectUtils aclFromDictionary:dict] forKey:ACLTag submit:NO];
    }
    else if ([AVObjectUtils isDate:type])
    {
        NSDate * date = [AVObjectUtils dateFromDictionary:dict];
        [target setObject:date forKey:key submit:NO];
    }
    else if ([AVObjectUtils isData:type])
    {
        NSData * data = [AVObjectUtils dataFromDictionary:dict];
        [target setObject:data forKey:key submit:NO];
    }
    else
    {
        id object = [self objectFromDictionary:dict recursive:YES];
        [target setObject:object forKey:key submit:NO];
    }
}


/// Add object to avobject container.
+(void)addObject:(NSObject *)object
              to:(NSObject *)parent
             key:(NSString *)key
      isRelation:(BOOL)isRelation
{
    if ([key hasPrefix:@"_"]) {
        // NSLog(@"Ingore key %@", key);
        return;
    }        
    
    if (![parent isKindOfClass:[AVObject class]]) {
        return;
    }
    AVObject * avParent = (AVObject *)parent;
    if ([object isKindOfClass:[AVObject class]]) {
        if (isRelation) {
            [avParent addRelation:(AVObject *)object forKey:key submit:NO];
        } else {
            [avParent setObject:object forKey:key submit:NO];
        }
    } else if ([object isKindOfClass:[NSArray class]]) {
        for(AVObject * item in [object copy]) {
            [avParent addObject:item forKey:key];
        }
    } else {
        [avParent setObject:object forKey:key submit:NO];
    }
}

+(NSDate *)dateFromValue:(id)value {
    NSDate * date = nil;
    if ([value isKindOfClass:[NSDictionary class]]) {
        date = [AVObjectUtils dateFromDictionary:value];
    } else if ([value isKindOfClass:[NSString class]]) {
        date = [AVObjectUtils dateFromString:value];
    }
    return date;
}

+(void)updateObjectProperty:(AVObject *)target
                        key:(NSString *)key
                      value:(NSObject *)value
{
    if ([key isEqualToString:@"createdAt"] ) {
        target.createdAt = [AVObjectUtils dateFromValue:value];
    } else if ([key isEqualToString:@"updatedAt"]) {
        target.updatedAt = [AVObjectUtils dateFromValue:value];
    } else if ([key isEqualToString:ACLTag]) {
        AVACL * acl = [AVObjectUtils aclFromDictionary:(NSDictionary *)value];
        [target setObject:acl forKey:key submit:NO];
    } else {
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary * valueDict = (NSDictionary *)value;
            [AVObjectUtils copyDictionary:valueDict toTarget:target key:key];
        } else if ([value isKindOfClass:[NSArray class]]) {
            NSArray * array = [AVObjectUtils arrayFromArray:(NSArray *)value];
            [target setObject:array forKey:key submit:NO];
        } else if ([value isEqual:[NSNull null]]) {
            [target removeObjectForKey:key];
        } else {
            [target setObject:value forKey:key submit:NO];
        }
    }
}

+(void)updateSubObjects:(AVObject *)target
                    key:(NSString *)key
                  value:(NSObject *)obj
{
    // additional properties, use setObject
    if ([obj isKindOfClass:[NSDictionary class]])
    {
        [AVObjectUtils copyDictionary:(NSDictionary *)obj toTarget:target key:key];
    }
    else if ([obj isKindOfClass:[NSArray class]])
    {
        NSArray * array = [AVObjectUtils arrayFromArray:(NSArray *)obj];
        [target setObject:array forKey:key submit:NO];
    }
    else
    {
        [target setObject:obj forKey:key submit:NO];
    }
}


#pragma mark - Update Objecitive-c object from server side dictionary
+(void)copyDictionary:(NSDictionary *)src
             toObject:(AVObject *)target
{
    [src enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([target respondsToSelector:NSSelectorFromString(key)]) {
            [AVObjectUtils updateObjectProperty:target key:key value:obj];
        } else {
            [AVObjectUtils updateSubObjects:target key:key value:obj];
        }
    }];
}

#pragma mark - Server side dictionary representation of objective-c object.
+ (NSMutableDictionary *)dictionaryFromDictionary:(NSDictionary *)dic {
    return [self dictionaryFromDictionary:dic topObject:NO];
}

/// topObject is for cloud rpc
+ (NSMutableDictionary *)dictionaryFromDictionary:(NSDictionary *)dic topObject:(BOOL)topObject{
    NSMutableDictionary *newDic = [NSMutableDictionary dictionaryWithCapacity:dic.count];
    for (NSString *key in [dic allKeys]) {
        id obj = [dic objectForKey:key];
        [newDic setObject:[AVObjectUtils dictionaryFromObject:obj topObject:topObject] forKey:key];
    }
    return newDic;
}

+ (NSMutableArray *)dictionaryFromArray:(NSArray *)array {
    return [self dictionaryFromArray:array topObject:NO];
}

+ (NSMutableArray *)dictionaryFromArray:(NSArray *)array topObject:(BOOL)topObject
{
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:array.count];
    for (id obj in [array copy]) {
        [newArray addObject:[AVObjectUtils dictionaryFromObject:obj topObject:topObject]];
    }
    return newArray;
}

+(NSDictionary *)dictionaryFromAVObjectPointer:(AVObject *)object
{
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@"Pointer" forKey:@"__type"];
    [dict setObject:[object internalClassName] forKey:classNameTag];
    if ([object hasValidObjectId])
    {
        [dict setObject:object.objectId forKey:@"objectId"];
    }
    return dict;
}

/*
{
    "cid" : "67c35bc8-4183-4db0-8f5a-0ee2b0baa4d4",
    "className" : "ddd",
    "key" : "myddd"
}
*/
+(NSDictionary *)childDictionaryFromAVObject:(AVObject *)object
                                     withKey:(NSString *)key
{
    NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[object internalClassName] forKey:classNameTag];
    NSString *cid = [object objectId] != nil ? [object objectId] : [object uuid];
    [dict setObject:cid forKey:@"cid"];
    [dict setObject:key forKey:@"key"];
    return dict;
}

+ (NSSet *)allAVObjectProperties:(Class)objectClass {
    NSMutableSet *properties = [NSMutableSet set];

    [self allAVObjectProperties:objectClass properties:properties];

    return [properties copy];
}

+(void)allAVObjectProperties:(Class)objectClass
                  properties:(NSMutableSet *)properties {
    unsigned int numberOfProperties = 0;
    objc_property_t *propertyArray = class_copyPropertyList(objectClass, &numberOfProperties);
    for (NSUInteger i = 0; i < numberOfProperties; i++)
    {
        objc_property_t property = propertyArray[i];

        char *readonly = property_copyAttributeValue(property, "R");

        if (readonly) {
            free(readonly);
            continue;
        }

        NSString *key = [[NSString alloc] initWithUTF8String:property_getName(property)];
        [properties addObject:key];
    }

    if ([objectClass isSubclassOfClass:[AVObject class]] && objectClass != [AVObject class])
    {
        [AVObjectUtils allAVObjectProperties:[objectClass superclass] properties:properties];
    }
    free(propertyArray);
}

// generate object json dictionary. For AVObject, we generate the full
// json dictionary instead of pointer only. This function is different
// from dictionaryFromObject which generates pointer json only for AVObject.
+ (id)snapshotDictionary:(id)object {
    return [self snapshotDictionary:object recursive:YES];
}

+ (id)snapshotDictionary:(id)object recursive:(BOOL)recursive {
    if (recursive && [object isKindOfClass:[AVObject class]]) {
        return [AVObjectUtils objectSnapshot:object recursive:recursive];
    } else {
        return [AVObjectUtils dictionaryFromObject:object];
    }
}

+ (NSMutableDictionary *)objectSnapshot:(AVObject *)object {
    return [self objectSnapshot:object recursive:YES];
}

+ (NSMutableDictionary *)objectSnapshot:(AVObject *)object recursive:(BOOL)recursive {
    NSArray * objects = @[object.localData, object.estimatedData];
    NSMutableDictionary * result = [NSMutableDictionary dictionary];
    [result setObject:@"Object" forKey:kAVTypeTag];

    for(NSDictionary * dict in objects) {
        NSArray * keys = [dict allKeys];
        for(NSString * key in keys) {
            id valueObject = [self snapshotDictionary:[dict objectForKey:key] recursive:recursive];
            if (valueObject != nil) {
                [result setObject:valueObject forKey:key];
            }
        }
    }

    NSArray * keys = [object.relationData allKeys];

    for(NSString * key in keys) {
        NSString * childClassName = [object childClassNameForRelation:key];
        id valueObject = [self dictionaryForRelation:childClassName];
        if (valueObject != nil) {
            [result setObject:valueObject forKey:key];
        }
    }
    
    NSSet *ignoreKeys = [NSSet setWithObjects:
                         @"localData",
                         @"relationData",
                         @"estimatedData",
                         @"isPointer",
                         @"running",
                         @"operationQueue",
                         @"requestManager",
                         @"inSetter",
                         @"uuid",
                         @"submit",
                         @"hasDataForInitial",
                         @"hasDataForCloud",
                         @"fetchWhenSave",
                         @"isNew", // from AVUser
                         nil];

    NSMutableSet * properties = [NSMutableSet set];
    [self allAVObjectProperties:[object class] properties:properties];

    for (NSString * key in properties) {
        if ([ignoreKeys containsObject:key]) {
            continue;
        }
        id valueObjet = [self snapshotDictionary:[object valueForKey:key] recursive:recursive];
        if (valueObjet != nil) {
            [result setObject:valueObjet forKey:key];
        }
    }

    return result;
}

+(AVObject *)avObjectForClass:(NSString *)className {
    if (className == nil) {
        return nil;
    }
    AVObject *object = nil;
    Class classObject = [[AVPaasClient sharedInstance] classFor:className];
    if (classObject != nil && [classObject isSubclassOfClass:[AVObject class]]) {
        if ([classObject respondsToSelector:@selector(object)]) {
            object = [classObject performSelector:@selector(object)];
        }
    } else {
        if ([AVObjectUtils isUserClass:className]) {
            object = [AVUser user];
        } else if ([AVObjectUtils isInstallationClass:className]) {
            object = [AVInstallation installation];
        } else if ([AVObjectUtils isRoleClass:className]) {
            // TODO
            object = [AVRole role];
        } else {
            object = [AVObject objectWithClassName:className];
        }
    }
    return object;
}

+(AVObject *)avObjectFromDictionary:(NSDictionary *)src
                          className:(NSString *)className {
    if (src == nil || className == nil || src.count == 0) {
        return nil;
    }
    AVObject *object = [AVObjectUtils avObjectForClass:className];
    [AVObjectUtils copyDictionary:src toObject:object];
    if ([AVObjectUtils isPointerDictionary:src]) {
        object.isPointer = YES;
    }
    return object;
}

+(AVObject *)avobjectFromDictionary:(NSDictionary *)dict {
    NSString * className = [dict objectForKey:classNameTag];
    return [AVObjectUtils avObjectFromDictionary:dict className:className];
}

// create relation target object instead of relation object.
+(AVObject *)targetObjectFromRelationDictionary:(NSDictionary *)dict
{
    AVObject * object = [AVObjectUtils avObjectForClass:[dict valueForKey:classNameTag]];
    return object;
}

+(NSDictionary *)dictionaryFromGeoPoint:(AVGeoPoint *)point
{
    return [AVGeoPoint dictionaryFromGeoPoint:point];
}

+(NSDictionary *)dictionaryFromDate:(NSDate *)date
{
    NSString *strDate = [AVObjectUtils stringFromDate:date];
    return @{@"__type": @"Date", @"iso":strDate};
}

+(NSDictionary *)dictionaryFromData:(NSData *)data
{
    NSString *base64 = [data AVbase64EncodedString];
    return @{@"__type": @"Bytes", @"base64":base64};
}

+(NSDictionary *)dictionaryFromFile:(AVFile *)file
{
    return [AVFile dictionaryFromFile:file];
}

+(NSDictionary *)dictionaryFromACL:(AVACL *)acl {
    return acl.permissionsById;
}

+(NSDictionary *)dictionaryFromRelation:(AVRelation *)relation {
    if (relation.targetClass) {
        return [AVObjectUtils dictionaryForRelation:relation.targetClass];
    }
    return nil;
}

+(NSDictionary *)dictionaryForRelation:(NSString *)className {
    return  @{@"__type": @"Relation", @"className":className};
}

// Generate server side dictionary representation of input NSObject
+ (id)dictionaryFromObject:(id)obj {
    return [self dictionaryFromObject:obj topObject:NO];
}

/// topObject means get the top level AVObject with Pointer child if any AVObject. Used for cloud rpc.
+ (id)dictionaryFromObject:(id)obj topObject:(BOOL)topObject
{
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return [AVObjectUtils dictionaryFromDictionary:obj topObject:topObject];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        return [AVObjectUtils dictionaryFromArray:obj topObject:topObject];
    } else if ([obj isKindOfClass:[AVObject class]]) {
        if (topObject) {
            return [AVObjectUtils objectSnapshot:obj recursive:NO];
        } else {
            return [AVObjectUtils dictionaryFromAVObjectPointer:obj];
        }
    } else if ([obj isKindOfClass:[AVGeoPoint class]]) {
        return [AVObjectUtils dictionaryFromGeoPoint:obj];
    } else if ([obj isKindOfClass:[NSDate class]]) {
        return [AVObjectUtils dictionaryFromDate:obj];
    } else if ([obj isKindOfClass:[NSData class]]) {
        return [AVObjectUtils dictionaryFromData:obj];
    } else if ([obj isKindOfClass:[AVFile class]]) {
        return [AVObjectUtils dictionaryFromFile:obj];
    } else if ([obj isKindOfClass:[AVACL class]]) {
        return [AVObjectUtils dictionaryFromACL:obj];
    } else if ([obj isKindOfClass:[AVRelation class]]) {
        return [AVObjectUtils dictionaryFromRelation:obj];
    }
    // string or other?
    return obj;
}

+(void)setupRelation:(AVObject *)parent
      withDictionary:(NSDictionary *)relationMap
{
    for(NSString * key in [relationMap allKeys]) {
        NSArray * array = [relationMap objectForKey:key];
        for(NSDictionary * item in [array copy]) {
            NSObject * object = [AVObjectUtils objectFromDictionary:item];
            if ([object isKindOfClass:[AVObject class]]) {
                [parent addRelation:(AVObject *)object forKey:key submit:NO];
            }
        }
    }
}

#pragma mark - batch request from operation list
+(BOOL)isUserClass:(NSString *)className
{
    return [className isEqualToString:[AVUser userTag]];
}

+(BOOL)isRoleClass:(NSString *)className
{
    return [className isEqualToString:[AVRole className]];
}

+(BOOL)isFileClass:(NSString *)className
{
    return [className isEqualToString:[AVFile className]];
}

+(BOOL)isInstallationClass:(NSString *)className
{
    return [className isEqualToString:[AVInstallation className]];
}

+(NSString *)classEndPoint:(NSString *)className
                   objectId:(NSString *)objectId
{
    if (objectId == nil)
    {
        return [NSString stringWithFormat:@"classes/%@", className];
    }
    return [NSString stringWithFormat:@"classes/%@/%@", className, objectId];
}

+(NSString *)userObjectPath:(NSString *)objectId
{
    if (objectId == nil)
    {
        return [AVUser endPoint];
    }
    return [NSString stringWithFormat:@"%@/%@", [AVUser endPoint], objectId];
}


+(NSString *)roleObjectPath:(NSString *)objectId
{
    if (objectId == nil)
    {
        return [AVRole endPoint];
    }
    return [NSString stringWithFormat:@"%@/%@", [AVRole endPoint], objectId];
}

+(NSString *)installationObjectPath:(NSString *)objectId
{
    if (objectId == nil)
    {
        return [AVInstallation endPoint];
    }
    return [NSString stringWithFormat:@"%@/%@", [AVInstallation endPoint], objectId];
}

+(NSString *)objectPath:(NSString *)className
                   objectId:(NSString *)objectId
{
    //FIXME: 而且等于nil也没问题 只不过不应该再发请求
    //NSAssert(objectClass!=nil, @"className should not be nil!");
    if ([AVObjectUtils isUserClass:className])
    {
        return [AVObjectUtils userObjectPath:objectId];
    }
    else if ([AVObjectUtils isRoleClass:className])
    {
        return [AVObjectUtils roleObjectPath:objectId];
    }
    else if ([AVObjectUtils isInstallationClass:className])
    {
        return [AVObjectUtils installationObjectPath:objectId];
    }
    return [AVObjectUtils classEndPoint:className objectId:objectId];
}

+(NSString *)batchPath {
    return @"batch";
}

+(NSString *)batchSavePath
{
    return @"batch/save";
}

+(BOOL)safeAdd:(NSDictionary *)dict
       toArray:(NSMutableArray *)array
{
    if (dict != nil) {
        [array addObject:dict];
        return YES;
    }
    return NO;
}

+(BOOL)hasAnyKeys:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary * dict = (NSDictionary *)object;
        return ([dict count] > 0);
    }
    return NO;
}

@end
