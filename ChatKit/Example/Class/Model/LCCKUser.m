//
//  LCCKUser.m
//  LeanCloudChatKit-iOS
//
//  Created by 陈宜龙 on 16/3/9.
//  Copyright © 2016年 ElonChan. All rights reserved.
//

#import "LCCKUser.h"
#import <objc/runtime.h>

@interface LCCKUser ()

@property (nonatomic, copy, readwrite) NSString *userId;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSURL *avatorURL;

@end

@implementation LCCKUser

- (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatorURL:(NSURL *)avatorURL {
    self = [super init];
    if (!self) {
        return nil;
    }
    _userId = userId;
    _name = name;
    _avatorURL = avatorURL;
    return self;
}

+ (instancetype)initWithUserId:(NSString *)userId name:(NSString *)name avatorURL:(NSURL *)avatorURL {
    LCCKUser *user = [[LCCKUser alloc] initWithUserId:userId name:name avatorURL:avatorURL];
    return user;
}

- (BOOL)isEqualToUer:(LCCKUser *)user {
    return (user.userId == self.userId);
}

- (id)copyWithZone:(NSZone *)zone {
    return [[LCCKUser alloc] initWithUserId:self.userId
                                       name:self.name
                                  avatorURL:self.avatorURL
            ];
}

/*解档*/
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        
        unsigned int pCounter = 0;
        //获取类中所有成员变量名
        objc_property_t *properties = class_copyPropertyList([self class], &pCounter);
        
        for (unsigned int i = 0; i < pCounter; i++)
        {
            objc_property_t prop = properties[i];
            const char *propName = property_getName(prop);
            NSString *pUTF8 = [NSString stringWithUTF8String:propName];
            //进行解档取值，并利用KVC对属性赋值
            [self setValue:[aDecoder decodeObjectForKey:pUTF8] forKey:pUTF8];
        }
        
        free(properties);
    }
    return self;
}

/*归档*/
- (void)encodeWithCoder:(NSCoder *)aCoder {
    unsigned int pCounter = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &pCounter);
    
    for (unsigned int i = 0; i < pCounter; i++)
    {
        objc_property_t prop = properties[i];
        const char *propName = property_getName(prop);
        NSString *pUTF8 = [NSString stringWithUTF8String:propName];
        //利用KVC取值
        [aCoder encodeObject:[self valueForKey:pUTF8] forKey:pUTF8];
    }
    
    free(properties);
}

- (void)saveToDiskWithKey:(NSString *)key {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (id)loadFromDiskWithKey:(NSString *)key {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    id result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return result;
}

@end
