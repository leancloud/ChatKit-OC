//
//  AVUtils.m
//  paas
//
//  Created by Zhu Zeng on 2/27/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <objc/runtime.h>
#import "AVUtils.h"
#import "AVObject.h"
#import "AVObject_Internal.h"
#import "AVGeoPoint_Internal.h"
#import "AVUser.h"
#import "AVUser_Internal.h"
#import "AVObject.h"
#import "AVRole_Internal.h"
#import "AVFile.h"
#import "AVFile_Internal.h"
#import "AVInstallation.h"
#import "AVInstallation_Internal.h"

#import "AVObjectUtils.h"
#import "AVPaasClient.h"
#import "AVGlobal.h"
#import "AVCloudQueryResult.h"
#import "AVKeychain.h"
#import "LCURLConnection.h"

#import <CommonCrypto/CommonDigest.h>
#import <AssertMacros.h>

#include<string.h>
#include<sys/socket.h>
#include<netdb.h>
#include<arpa/inet.h>

static dispatch_queue_t AVUtilsDefaultSerialQueue = NULL;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"

static void b62_divide(const unsigned char* dividend, int dividend_len,
                       unsigned char* quotient, unsigned int* remainder)
{
    unsigned int quantity;
    int i;
    
    quantity = 0;
    for (i=dividend_len-2;i>=0;i-=2) {
        quantity |= *((unsigned short*)&dividend[i]);
        *((unsigned short *)&quotient[i]) = (unsigned short)(quantity/62);
        quantity = (quantity%62)<<16;
    }
    *remainder = quantity>>16;
}

#pragma clang diagnostic pop

#define msg_id_length (((134359*(sizeof(time_t)+sizeof(int)*2))/100000)+2)

static char base62_tab[62] = {
    'A','B','C','D','E','F','G','H',
    'I','J','K','L','M','N','O','P',
    'Q','R','S','T','U','V','W','X',
    'Y','Z','a','b','c','d','e','f',
    'g','h','i','j','k','l','m','n',
    'o','p','q','r','s','t','u','v',
    'w','x','y','z','0','1','2','3',
    '4','5','6','7','8','9'
};

static int b62_encode(char* out, const void *data, int length)
{
    int i,j;
    char *start = out;
    uint64_t bitstring;
    const unsigned char *s = (const unsigned char *)data;
    for (i=0;i<length-4;i+=5) {
        bitstring =
        (uint64_t)s[i]<<32|(uint64_t)s[i+1]<<24|(uint64_t)s[i+2]<<16|
        (uint64_t)s[i+3]<<8|(uint64_t)s[i+4];
        
        for (j=0;j<7;++j) {
            *out++ = base62_tab[bitstring%62];
            bitstring /= 62;
        }
        /*
         b62_divide(quotient,len,quotient,&rem);
         *out++ = base62_tab[rem];
         for (j=1;j<len;++j) {
         b62_divide(quotient,len,quotient,&rem);
         *out++ = base62_tab[rem];
         }*/
    }
    switch (length-i) {
        case 1:
            *out++ = base62_tab[s[i]%62];
            *out++ = base62_tab[s[i]/62];
            break;
        case 2:
            bitstring = s[i]<<8|s[i+1];
            *out++ = base62_tab[bitstring%62];
            bitstring /= 62;
            *out++ = base62_tab[bitstring%62];
            *out++ = base62_tab[bitstring/62];
            break;
        case 3:
            bitstring = s[i]<<16|s[i+1]<<8|s[i];
            *out++ = base62_tab[bitstring%62];
            bitstring /= 62;
            *out++ = base62_tab[bitstring%62];
            bitstring /= 62;
            *out++ = base62_tab[bitstring%62];
            bitstring /= 62;
            *out++ = base62_tab[bitstring%62];
            *out++ = base62_tab[bitstring/62];
            break;
        case 4:
            bitstring = s[i]<<24|s[i+1]<<16|s[i+2]<<8|s[i];
            *out++ = base62_tab[bitstring%62];
            bitstring /= 62;
            *out++ = base62_tab[bitstring%62];
            bitstring /= 62;
            *out++ = base62_tab[bitstring%62];
            bitstring /= 62;
            *out++ = base62_tab[bitstring%62];
            bitstring /= 62;
            *out++ = base62_tab[bitstring%62];
            *out++ = base62_tab[bitstring/62];
            break;
    }
    return (int)(out-start);
}

#if !TARGET_OS_IOS && !TARGET_OS_WATCH && !TARGET_OS_TV
static NSData * LCSecKeyGetData(SecKeyRef key) {
    CFDataRef data = NULL;

    __Require_noErr_Quiet(SecItemExport(key, kSecFormatUnknown, kSecItemPemArmour, NULL, &data), _out);

    return (__bridge_transfer NSData *)data;

_out:
    if (data) {
        CFRelease(data);
    }

    return nil;
}
#endif

BOOL LCSecKeyIsEqual(SecKeyRef key1, SecKeyRef key2) {
#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
    return [(__bridge id)key1 isEqual:(__bridge id)key2];
#else
    return [LCSecKeyGetData(key1) isEqual:LCSecKeyGetData(key2)];
#endif
}

SecKeyRef LCGetPublicKeyFromCertificate(SecCertificateRef cert) {
    SecKeyRef result = NULL;
    SecCertificateRef certs[] = {cert};
    CFArrayRef certArr = CFArrayCreate(NULL, (const void **)certs, 1, NULL);

    SecPolicyRef policy = SecPolicyCreateBasicX509();

    SecTrustRef trust;
    __Require_noErr_Quiet(SecTrustCreateWithCertificates(certArr, policy, &trust), _out);
    __Require_noErr_Quiet(SecTrustEvaluate(trust, NULL), _out);

    result = SecTrustCopyPublicKey(trust);

_out:
    if (policy) CFRelease(policy);
    if (certArr) CFRelease(certArr);
    if (trust) CFRelease(trust);

    return result;
}

SecCertificateRef LCGetCertificateFromBase64String(NSString *base64) {
    NSData *certData = [NSData AVdataFromBase64String:base64];
    SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));

    return cert;
}

@implementation AVUtils

+ (void)initialize {
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        AVUtilsDefaultSerialQueue = dispatch_queue_create("cn.leancloud.utils", DISPATCH_QUEUE_SERIAL);
    });
}

+(void)warnMainThreadIfNecessary {
    if (getenv("GHUNIT_CLI")) return;
    
    if ([NSThread isMainThread]) {
        AVLoggerI(@"Warning: A long-running Paas operation is being executed on the main thread.");
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"

static const char *getPropertyType(objc_property_t property)
{
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T') {
            return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
        }
    }
    return "@";
}

#pragma clang diagnostic pop

+(void)copyPropertiesFrom:(NSObject *)src
                 toObject:(NSObject *)target
{
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([src class], &outCount);
    for(i = 0; i < outCount; i++) {
    	objc_property_t property = properties[i];
    	const char *propName = property_getName(property);
    	if (propName) {
    		NSString *propertyName = [NSString stringWithCString:propName encoding:NSUTF8StringEncoding];
            NSObject * valueObject = [src valueForKey:propertyName];
            [target setValue:valueObject forKey:propertyName];
    	}
    }
    free(properties);
}

+(void)copyPropertiesFromDictionary:(NSDictionary *)src
                         toNSObject:(NSObject *)target
{
    NSArray * keys = [src allKeys];
    for(NSString * key in keys)
    {
        NSObject * valueObject = [src valueForKey:key];
        if ([AVUtils containsProperty:[target class] property:key])
        {
            [target setValue:valueObject forKey:key];
        }
    }
}

+(BOOL)containsProperty:(Class)objectClass property:(NSString *)name
{
    return [AVUtils containsProperty:name inClass:objectClass containSuper:YES filterDynamic:NO];
}

+ (BOOL)containsProperty:(NSString *)name inClass:(Class)objectClass containSuper:(BOOL)containSuper filterDynamic:(BOOL)filterDynamic {
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(objectClass, &outCount);
    for(i = 0; i < outCount; i++) {
    	objc_property_t property = properties[i];
        
        if (filterDynamic) {
            char *dynamic = property_copyAttributeValue(property, "D");
            if (dynamic) {
                free(dynamic);
                continue;
            }
            
        }
        
        const char *propName = property_getName(property);
    	if (propName) {
    		NSString *propertyName = [NSString stringWithCString:propName encoding:NSUTF8StringEncoding];
            if ([name isEqualToString:propertyName])
            {
                free(properties);
                return YES;
            }
        }
    }
    free(properties);
    // isSubclassOfClass : a subclass of, or identical to, a given class.
    // 如果是 AVObject 类或者是其子类，则遍历。不遍历 NSObject。
    if (containSuper && [[objectClass superclass] isSubclassOfClass:[AVObject class]])
    {
        return [AVUtils containsProperty:name inClass:[objectClass superclass] containSuper:containSuper filterDynamic:filterDynamic];
    }
    return NO;
}

+ (BOOL)isDynamicProperty:(NSString *)name
                  inClass:(Class)objectClass
                 withType:(Class)targetClass
             containSuper:(BOOL)containSuper {
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(objectClass, &outCount);
    for(i = 0; i < outCount; i++) {
    	objc_property_t property = properties[i];
        const char *propName = property_getName(property);
    	if (propName == nil) {
            continue;
        }
        NSString *propertyName = [NSString stringWithCString:propName encoding:NSUTF8StringEncoding];
        if ([propertyName isEqualToString:name]) {
            char *dynamic = property_copyAttributeValue(property, "D");
            const char * attributes = property_getAttributes(property);
            NSString *attributesName = [NSString stringWithCString:attributes encoding:NSUTF8StringEncoding];
            NSString * className = NSStringFromClass(targetClass);
            NSRange range = [attributesName rangeOfString:className];
            if (range.location <= 3 && range.length == className.length && dynamic) {
                free(dynamic);
                free(properties);
                return true;
            }
            if (dynamic) {
                free(dynamic);
            }
        }
    }
    free(properties);
    if (containSuper && [objectClass isSubclassOfClass:[AVObject class]])
    {
        return [AVUtils isDynamicProperty:name inClass:[objectClass superclass] withType:targetClass containSuper:containSuper];
    }
    return NO;
}

+(NSString *)jsonStringFromDictionary:(NSDictionary *)dictionary
{
    if (!dictionary) return @"{}";
    NSData* data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+(NSString *)jsonStringFromArray:(NSArray *)array
{
    if (!array) return @"[]";
    NSData* data = [NSJSONSerialization dataWithJSONObject:array
                                                   options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+(void)performSelectorIfCould:(id)target
                     selector:(SEL)selector
                       object:(id)arg1
                       object:(id)arg2
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([target respondsToSelector:selector])
    {
        [target performSelector:selector withObject:arg1 withObject:arg2];
    }
#pragma clang diagnostic pop
}

+ (NSString *)generateUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString * string = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    string = [string lowercaseString];
    CFRelease(theUUID);
    return string;
}

+ (NSString *)generateCompactUUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuid);
    CFRelease(uuid);
    char buf[24];
    memset(buf, 0, sizeof(buf));
    int len = b62_encode(buf, &bytes, sizeof(bytes));
    assert(len == 23);
    return [[NSString alloc] initWithFormat:@"%s", buf];
}

+ (NSString *)deviceUUIDKey {
    static NSString *const suffix = @"@leancloud";
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

    if (bundleIdentifier) {
        return [bundleIdentifier stringByAppendingString:suffix];
    } else {
        return suffix; /* Bundle identifier is nil in unit test. */
    }
}

+ (NSString *)deviceUUID {
    static NSString *UUID = nil;

    if (!UUID) {
        dispatch_sync(AVUtilsDefaultSerialQueue, ^{
            NSString *key = [self deviceUUIDKey];

            NSString *savedUUID = [AVKeychain loadValueForKey:key];

            if (savedUUID) {
                UUID = savedUUID;
            } else {
                NSString *tempUUID = [self generateUUID];

                if (tempUUID) {
                    [AVKeychain saveValue:tempUUID forKey:key];
                    UUID = tempUUID;
                }
            }
        });
    }

    return UUID;
}

#pragma mark - Safe way to call block

#define safeBlock(first_param) \
if (block) { \
    if ([NSThread isMainThread]) { \
        block(first_param, error); \
    } else {\
        dispatch_async(dispatch_get_main_queue(), ^{ \
            block(first_param, error); \
        }); \
    } \
}

+ (void)callBooleanResultBlock:(AVBooleanResultBlock)block
                         error:(NSError *)error
{
    safeBlock(error == nil);
}

+ (void)callIntegerResultBlock:(AVIntegerResultBlock)block
                        number:(NSInteger)number
                         error:(NSError *)error {
    safeBlock(number);
}

+ (void)callArrayResultBlock:(AVArrayResultBlock)block
                       array:(NSArray *)array
                       error:(NSError *)error {
    safeBlock(array);
}

+ (void)callObjectResultBlock:(AVObjectResultBlock)block
                       object:(AVObject *)object
                        error:(NSError *)error {
    safeBlock(object);
}

+ (void)callUserResultBlock:(AVUserResultBlock)block
                       user:(AVUser *)user
                      error:(NSError *)error {
    safeBlock(user);
}

+ (void)callIdResultBlock:(AVIdResultBlock)block
                   object:(id)object
                    error:(NSError *)error {
    safeBlock(object);
}

+ (void)callImageResultBlock:(AVImageResultBlock)block
                       image:(UIImage *)image
                       error:(NSError *)error
{
    safeBlock(image);
}

+ (void)callFileResultBlock:(AVFileResultBlock)block
                     AVFile:(AVFile *)file
                      error:(NSError *)error
{
    safeBlock(file);
}

+ (void)callProgressBlock:(AVProgressBlock)block
                  percent:(NSInteger)percentDone {
    if (block) {
        if ([NSThread isMainThread]) {
            block(percentDone);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{ 
                block(percentDone); 
            });
        }
    }
}

+(void)callSetResultBlock:(AVSetResultBlock)block
                      set:(NSSet *)set
                    error:(NSError *)error
{
    if (block) {
        if ([NSThread isMainThread]) {
            block(set, error);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(set, error);
            });
        }
    }
}

+(void)callCloudQueryResultBlock:(AVCloudQueryCallback)block
                          result:(AVCloudQueryResult *)result
                           error:error {
    safeBlock(result);
}

+ (dispatch_queue_t)asynchronousTaskQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;

    if (queue)
        return queue;

    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("avos.common.dispatchQueue", DISPATCH_QUEUE_CONCURRENT);
    });

    return queue;
}

+ (void)asynchronize:(void (^)())task {
    NSAssert(task != nil, @"Task cannot be nil.");

    dispatch_async([self asynchronousTaskQueue], ^{
        task();
    });
}

#pragma mark - String Util
+ (NSString *)MIMEType:(NSString *)filePathOrName {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filePathOrName pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    
    CFRelease(UTI);
    return MIMEType ? (__bridge_transfer NSString *)MIMEType : @"application/octet-stream";
}

+ (NSString *)MIMETypeFromPath:(NSString *)fullPath
{
    NSURL* fileUrl = [NSURL fileURLWithPath:fullPath];
    NSURLRequest* fileUrlRequest = [[NSURLRequest alloc] initWithURL:fileUrl cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:.1];
    NSError* error = nil;
    NSURLResponse* response = nil;
    [LCURLConnection sendSynchronousRequest:fileUrlRequest returningResponse:&response error:&error];
    NSString* mimeType = [response MIMEType];
    return mimeType;
}

+(NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return nil;
}

+ (NSString*)MD5ForFile:(NSString*)filePath{
    
    int chunkSizeForReadingData=1024*8;
    
    
    
    CFReadStreamRef readStream = NULL;
    
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) return nil;
    
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,fileURL);
    if (!readStream) return nil;
    
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) return nil;
    
    
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    
    didSucceed = !hasMoreData;
    
    NSString *result = nil;
    if (didSucceed) {
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(digest, &hashObject);
        
        char hash[2 * sizeof(digest) + 1];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
        }
        result = [NSString stringWithCString:(const char *)hash encoding:NSUTF8StringEncoding];
    }
    
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

+ (NSString*)SHAForFile:(NSString *)filePath {
    int chunkSizeForReadingData=1024*8;
    return [self SHAForFile:filePath chunkSizeForReadingData:chunkSizeForReadingData];
}

+ (NSString*)SHAForFile:(NSString *)filePath chunkSizeForReadingData:(size_t)chunkSizeForReadingData {
    
    CFReadStreamRef readStream = NULL;
    
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) return nil;
    
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,fileURL);
    if (!readStream) return nil;
    
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) return nil;
    
    
    // Initialize the hash object
    CC_SHA1_CTX hashObject;
    CC_SHA1_Init(&hashObject);
    
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_SHA1_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    
    didSucceed = !hasMoreData;
    
    NSString *result = nil;
    if (didSucceed) {
        unsigned char digest[CC_SHA1_DIGEST_LENGTH];
        CC_SHA1_Final(digest, &hashObject);
        
        char hash[2 * sizeof(digest) + 1];
        for (size_t i = 0; i < sizeof(digest); ++i) {
            snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
        }
        result = [NSString stringWithCString:(const char *)hash encoding:NSUTF8StringEncoding];
    }
    
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}

#pragma mark - Network Util

#if !TARGET_OS_WATCH

+ (BOOL)networkIsReachableOrBetter {
    return [[self class] networkEqualOrHigherThan:AVNetworkReachabilityStatusReachableViaWWAN];
}

+ (BOOL)networkIs3GOrBetter {
    return [[self class] networkEqualOrHigherThan:AVNetworkReachabilityStatusReachableViaWWAN];
}

+ (BOOL)networkIsWifiOrBetter {
    return [[self class] networkEqualOrHigherThan:AVNetworkReachabilityStatusReachableViaWiFi];
}

+ (BOOL)networkEqualOrHigherThan:(AVNetworkReachabilityStatus)status {
    return [AVPaasClient sharedInstance].clientImpl.networkReachabilityStatus >= status;
}

#endif

@end



//
// Mapping from 6 bit pattern to ASCII character.
//
static unsigned char base64EncodeLookup[65] =
"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

//
// Definition for "masked-out" areas of the base64DecodeLookup mapping
//
#define xx 65

//
// Mapping from ASCII character to 6 bit pattern.
//
static unsigned char base64DecodeLookup[256] =
{
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 62, xx, xx, xx, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, xx, xx, xx, xx, xx, xx,
    xx,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, xx, xx, xx, xx, xx,
    xx, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
};

//
// Fundamental sizes of the binary and base64 encode/decode units in bytes
//
#define BINARY_UNIT_SIZE 3
#define BASE64_UNIT_SIZE 4

//
// NewBase64Decode
//
// Decodes the base64 ASCII string in the inputBuffer to a newly malloced
// output buffer.
//
//  inputBuffer - the source ASCII string for the decode
//	length - the length of the string or -1 (to specify strlen should be used)
//	outputLength - if not-NULL, on output will contain the decoded length
//
// returns the decoded buffer. Must be free'd by caller. Length is given by
//	outputLength.
//
void *avNewBase64Decode(
                        const char *inputBuffer,
                        size_t length,
                        size_t *outputLength)
{
	if (length == -1)
	{
		length = strlen(inputBuffer);
	}
	
	size_t outputBufferSize =
    ((length+BASE64_UNIT_SIZE-1) / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE;
	unsigned char *outputBuffer = (unsigned char *)malloc(outputBufferSize);
	
	size_t i = 0;
	size_t j = 0;
	while (i < length)
	{
		//
		// Accumulate 4 valid characters (ignore everything else)
		//
		unsigned char accumulated[BASE64_UNIT_SIZE];
		size_t accumulateIndex = 0;
		while (i < length)
		{
			unsigned char decode = base64DecodeLookup[inputBuffer[i++]];
			if (decode != xx)
			{
				accumulated[accumulateIndex] = decode;
				accumulateIndex++;
				
				if (accumulateIndex == BASE64_UNIT_SIZE)
				{
					break;
				}
			}
		}
		
		//
		// Store the 6 bits from each of the 4 characters as 3 bytes
		//
		// (Uses improved bounds checking suggested by Alexandre Colucci)
		//
		if(accumulateIndex >= 2)
			outputBuffer[j] = (accumulated[0] << 2) | (accumulated[1] >> 4);
		if(accumulateIndex >= 3)
			outputBuffer[j + 1] = (accumulated[1] << 4) | (accumulated[2] >> 2);
		if(accumulateIndex >= 4)
			outputBuffer[j + 2] = (accumulated[2] << 6) | accumulated[3];
		j += accumulateIndex - 1;
	}
	
	if (outputLength)
	{
		*outputLength = j;
	}
	return outputBuffer;
}

//
// NewBase64Encode
//
// Encodes the arbitrary data in the inputBuffer as base64 into a newly malloced
// output buffer.
//
//  inputBuffer - the source data for the encode
//	length - the length of the input in bytes
//  separateLines - if zero, no CR/LF characters will be added. Otherwise
//		a CR/LF pair will be added every 64 encoded chars.
//	outputLength - if not-NULL, on output will contain the encoded length
//		(not including terminating 0 char)
//
// returns the encoded buffer. Must be free'd by caller. Length is given by
//	outputLength.
//
char *avNewBase64Encode(
                        const void *buffer,
                        size_t length,
                        bool separateLines,
                        size_t *outputLength)
{
	const unsigned char *inputBuffer = (const unsigned char *)buffer;
	
#define MAX_NUM_PADDING_CHARS 2
#define OUTPUT_LINE_LENGTH 64
#define INPUT_LINE_LENGTH ((OUTPUT_LINE_LENGTH / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE)
#define CR_LF_SIZE 2
	
	//
	// Byte accurate calculation of final buffer size
	//
	size_t outputBufferSize =
    ((length / BINARY_UNIT_SIZE)
     + ((length % BINARY_UNIT_SIZE) ? 1 : 0))
    * BASE64_UNIT_SIZE;
	if (separateLines)
	{
		outputBufferSize +=
        (outputBufferSize / OUTPUT_LINE_LENGTH) * CR_LF_SIZE;
	}
	
	//
	// Include space for a terminating zero
	//
	outputBufferSize += 1;
    
	//
	// Allocate the output buffer
	//
	char *outputBuffer = (char *)malloc(outputBufferSize);
	if (!outputBuffer)
	{
		return NULL;
	}
    
	size_t i = 0;
	size_t j = 0;
	const size_t lineLength = separateLines ? INPUT_LINE_LENGTH : length;
	size_t lineEnd = lineLength;
	
	while (true)
	{
		if (lineEnd > length)
		{
			lineEnd = length;
		}
        
		for (; i + BINARY_UNIT_SIZE - 1 < lineEnd; i += BINARY_UNIT_SIZE)
		{
			//
			// Inner loop: turn 48 bytes into 64 base64 characters
			//
			outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
			outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
                                                   | ((inputBuffer[i + 1] & 0xF0) >> 4)];
			outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i + 1] & 0x0F) << 2)
                                                   | ((inputBuffer[i + 2] & 0xC0) >> 6)];
			outputBuffer[j++] = base64EncodeLookup[inputBuffer[i + 2] & 0x3F];
		}
		
		if (lineEnd == length)
		{
			break;
		}
		
		//
		// Add the newline
		//
		outputBuffer[j++] = '\r';
		outputBuffer[j++] = '\n';
		lineEnd += lineLength;
	}
	
	if (i + 1 < length)
	{
		//
		// Handle the single '=' case
		//
		outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
		outputBuffer[j++] = base64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
                                               | ((inputBuffer[i + 1] & 0xF0) >> 4)];
		outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i + 1] & 0x0F) << 2];
		outputBuffer[j++] =	'=';
	}
	else if (i < length)
	{
		//
		// Handle the double '=' case
		//
		outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
		outputBuffer[j++] = base64EncodeLookup[(inputBuffer[i] & 0x03) << 4];
		outputBuffer[j++] = '=';
		outputBuffer[j++] = '=';
	}
	outputBuffer[j] = 0;
	
	//
	// Set the output length and return the buffer
	//
	if (outputLength)
	{
		*outputLength = j;
	}
	return outputBuffer;
}

@implementation NSData (Base64)

//
// dataFromBase64String:
//
// Creates an NSData object containing the base64 decoded representation of
// the base64 string 'aString'
//
// Parameters:
//    aString - the base64 string to decode
//
// returns the autoreleased NSData representation of the base64 string
//
+ (NSData *)AVdataFromBase64String:(NSString *)aString
{
	NSData *data = [aString dataUsingEncoding:NSASCIIStringEncoding];
	size_t outputLength;
	void *outputBuffer = avNewBase64Decode([data bytes], [data length], &outputLength);
	NSData *result = [NSData dataWithBytes:outputBuffer length:outputLength];
	free(outputBuffer);
	return result;
}

//
// base64EncodedString
//
// Creates an NSString object that contains the base 64 encoding of the
// receiver's data. Lines are broken at 64 characters long.
//
// returns an autoreleased NSString being the base 64 representation of the
//	receiver.
//
- (NSString *)AVbase64EncodedString
{
	size_t outputLength=0;
	char *outputBuffer =
    avNewBase64Encode([self bytes], [self length], true, &outputLength);
	
	NSString *result =
    [[NSString alloc]
     initWithBytes:outputBuffer
     length:outputLength
     encoding:NSASCIIStringEncoding];
	free(outputBuffer);
	return result;
}

@end


@implementation NSString (MD5)

- (NSString *)AVMD5String {
    const char *cstr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), result);
    
    //???: 为什么要返回大写MD5 一般都是小写
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end


#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>

#define PASSWORD @"QxciDjdHjuAIf8VCsqhmGK3OZV7pBQTZ"

const NSUInteger kAVAlgorithmKeySize = kCCKeySizeAES256;
const NSUInteger kAVPBKDFRounds = 10000;  // ~80ms on an iPhone 4

static Byte saltBuff[] = {0,1,2,3,4,5,6,7,8,9,0xA,0xB,0xC,0xD,0xE,0xF};

static Byte ivBuff[]   = {0xA,1,0xB,5,4,0xF,7,9,0x17,3,1,6,8,0xC,0xD,91};

@implementation NSString (AVAES256)

+ (NSData *)AVAESKeyForPassword:(NSString *)password{                  //Derive a key from a text password/passphrase
    
    NSMutableData *derivedKey = [NSMutableData dataWithLength:kAVAlgorithmKeySize];
    
    NSData *salt = [NSData dataWithBytes:saltBuff length:kCCKeySizeAES128];
    
    int result = CCKeyDerivationPBKDF(kCCPBKDF2,        // algorithm算法
                                      password.UTF8String,  // password密码
                                      password.length,      // passwordLength密码的长度
                                      salt.bytes,           // salt内容
                                      salt.length,          // saltLen长度
                                      kCCPRFHmacAlgSHA1,    // PRF
                                      kAVPBKDFRounds,         // rounds循环次数
                                      derivedKey.mutableBytes, // derivedKey
                                      derivedKey.length);   // derivedKeyLen derive:出自
    
    NSAssert(result == kCCSuccess,
             @"Unable to create AES key for spassword: %d", result);
    return derivedKey;
}

/*加密方法*/
- (NSString *)AVAES256Encrypt {
    NSData *plainText = [self dataUsingEncoding:NSUTF8StringEncoding];
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
	NSUInteger dataLength = [plainText length];
    
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
    bzero(buffer, sizeof(buffer));
	
	size_t numBytesEncrypted = 0;
    
	CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,kCCOptionPKCS7Padding,
                                          [[[self class] AVAESKeyForPassword:PASSWORD] bytes], kCCKeySizeAES256,
										  ivBuff /* initialization vector (optional) */,
										  [plainText bytes], dataLength, /* input */
										  buffer, bufferSize, /* output */
										  &numBytesEncrypted);
	if (cryptStatus == kCCSuccess) {
        NSData *encryptData = [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
		return [encryptData AVbase64EncodedString];
	}
	
	free(buffer); //free the buffer;
	return nil;
}

- (NSString *)AVAES256Decrypt{
    NSData *cipherData = [NSData AVdataFromBase64String:self];
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
	NSUInteger dataLength = [cipherData length];
	
	size_t bufferSize = dataLength + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
    
	size_t numBytesDecrypted = 0;
	CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
										  [[[self class] AVAESKeyForPassword:PASSWORD] bytes], kCCKeySizeAES256,
										  ivBuff ,/* initialization vector (optional) */
										  [cipherData bytes], dataLength, /* input */
										  buffer, bufferSize, /* output */
										  &numBytesDecrypted);
	
	if (cryptStatus == kCCSuccess) {
        NSData *encryptData = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
		return [[NSString alloc] initWithData:encryptData encoding:NSUTF8StringEncoding];
	}
	
	free(buffer); //free the buffer;
	return nil;
}

@end



@implementation NSDate (AVServerTimezone)

+(NSDate *)serverTimeZoneDateFromString:(NSString*)fullTimeString {
    static NSDateFormatter *dateFormatter = nil;
    
    static int serverTimeZone=8*3600;
    if (dateFormatter==nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:serverTimeZone]];
    }
    
    NSDate *bdate = [dateFormatter dateFromString:fullTimeString];
    
    return bdate;
}

@end

