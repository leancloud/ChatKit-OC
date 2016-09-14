//
//  JNKeychain.m
//
//  Created by Jeremias Nunez on 5/10/13.
//  Copyright (c) 2013 Jeremias Nunez. All rights reserved.
//
//  jeremias.np@gmail.com

#define CHECK_OSSTATUS_ERROR(x) (x == noErr) ? YES : NO

#import "AVKeychain.h"
#import "AVLogger.h"

@interface AVKeychain ()

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)key;

@end

@implementation AVKeychain

#pragma mark - Private
+ (NSMutableDictionary *)getKeychainQuery:(NSString *)key
{
    // see http://developer.apple.com/library/ios/#DOCUMENTATION/Security/Reference/keychainservices/Reference/reference.html
    return [@{(__bridge id)kSecClass            : (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService      : key,
              (__bridge id)kSecAttrAccount      : key,
              (__bridge id)kSecAttrAccessible   : (__bridge id)kSecAttrAccessibleAfterFirstUnlock
              } mutableCopy];
}

#pragma mark - Public
+ (BOOL)saveValue:(id)value forKey:(NSString*)key
{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    // delete any previous value with this key (we could use SecItemUpdate but its unnecesarily more complicated)
    [self deleteValueForKey:key];
    
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:value] forKey:(__bridge id)kSecValueData];
    
    OSStatus result = SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
    return CHECK_OSSTATUS_ERROR(result);
}

+ (BOOL)deleteValueForKey:(NSString *)key
{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    return CHECK_OSSTATUS_ERROR(result);
}

+ (id)loadValueForKey:(NSString *)key
{
    id value = nil;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    CFDataRef keyData = NULL;
    
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            value = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        } @catch (NSException *e) {
            AVLoggerInfo(nil, @"Unarchive of %@ from keychain failed: %@", key, e);
            value = nil;
        }
    }
    
    if (keyData) {
        CFRelease(keyData);
    }
    
    return value;
}

@end
