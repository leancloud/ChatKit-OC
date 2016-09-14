// AVHTTPClient.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "AVUtils.h"
#import "AVHTTPClient.h"
#import "AVHTTPRequestOperation.h"

#import <Availability.h>

#define LC_REST_REQUEST_LOG_FORMAT \
    @"\n\n" \
    @"------ BEGIN LeanCloud REST Request ------\n" \
    @"path: %@\n" \
    @"curl: %@\n" \
    @"------ END --------------------------------\n" \
    @"\n"

#ifdef _SYSTEMCONFIGURATION_H
    #import <netinet/in.h>
    #import <netinet6/in6.h>
    #import <arpa/inet.h>
    #import <ifaddrs.h>
    #import <netdb.h>
#endif

#if TARGET_OS_WATCH
    #import <WatchKit/WatchKit.h>
#elif TARGET_OS_IPHONE
    #import <UIKit/UIKit.h>
#endif

#ifdef _SYSTEMCONFIGURATION_H
NSString * const AVNetworkingReachabilityDidChangeNotification = @"cn.leancloud.networking.reachability.change";
NSString * const AVNetworkingReachabilityNotificationStatusItem = @"AVNetworkingReachabilityNotificationStatusItem";

typedef SCNetworkReachabilityRef AVNetworkReachabilityRef;
typedef void (^AVNetworkReachabilityStatusBlock)(AVNetworkReachabilityStatus status);
#else
typedef id AVNetworkReachabilityRef;
#endif

typedef void (^AVCompletionBlock)(void);

static NSString * AVBase64EncodedStringFromString(NSString *string) {
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAVBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAVBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAVBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAVBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAVBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

static NSString * AVPercentEscapedQueryStringPairMemberFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kAVCharactersToBeEscaped = @":/?&=;+!@#$()~";
    static NSString * const kAVCharactersToLeaveUnescaped = @"[].";
    
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kAVCharactersToLeaveUnescaped, (__bridge CFStringRef)kAVCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
}

#pragma mark -

@interface AVQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (id)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;
@end

@implementation AVQueryStringPair
@synthesize field = _field;
@synthesize value = _value;

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return AVPercentEscapedQueryStringPairMemberFromStringWithEncoding([self.field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@", AVPercentEscapedQueryStringPairMemberFromStringWithEncoding([self.field description], stringEncoding), AVPercentEscapedQueryStringPairMemberFromStringWithEncoding([self.value description], stringEncoding)];
    }
}

@end

#pragma mark -

extern NSArray * AVQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray * AVQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * AVQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (AVQueryStringPair *pair in AVQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValueWithEncoding:stringEncoding]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * AVQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return AVQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * AVQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        [[[value allKeys] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] enumerateObjectsUsingBlock:^(id nestedKey, __unused NSUInteger idx, __unused BOOL *stop) {
            id nestedValue = [value objectForKey:nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:AVQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }];
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        [array enumerateObjectsUsingBlock:^(id nestedValue, __unused NSUInteger idx, __unused BOOL *stop) {
            [mutableQueryStringComponents addObjectsFromArray:AVQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }];
    } else {
        [mutableQueryStringComponents addObject:[[AVQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

@interface AVStreamingMultipartFormData : NSObject <AVMultipartFormData>
- (id)initWithURLRequest:(NSMutableURLRequest *)urlRequest
          stringEncoding:(NSStringEncoding)encoding;

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData;
@end

#pragma mark -

@interface AVHTTPClient ()
@property (readwrite, nonatomic) NSURL *baseURL;
@property (readwrite, nonatomic) NSMutableArray *registeredHTTPOperationClassNames;
@property (readwrite, nonatomic) NSMutableDictionary *defaultHeaders;
@property (readwrite, nonatomic) NSOperationQueue *operationQueue;
#ifdef _SYSTEMCONFIGURATION_H
@property (readwrite, nonatomic, assign) AVNetworkReachabilityRef networkReachability;
@property (readwrite, nonatomic, assign) AVNetworkReachabilityStatus networkReachabilityStatus;
@property (readwrite, nonatomic, copy) AVNetworkReachabilityStatusBlock networkReachabilityStatusBlock;
#endif

#ifdef _SYSTEMCONFIGURATION_H
- (void)startMonitoringNetworkReachability;
- (void)stopMonitoringNetworkReachability;
#endif
@end

@implementation AVHTTPClient
@synthesize baseURL = _baseURL;
@synthesize stringEncoding = _stringEncoding;
@synthesize parameterEncoding = _parameterEncoding;
@synthesize registeredHTTPOperationClassNames = _registeredHTTPOperationClassNames;
@synthesize defaultHeaders = _defaultHeaders;
@synthesize operationQueue = _operationQueue;
#ifdef _SYSTEMCONFIGURATION_H
@synthesize networkReachability = _networkReachability;
@synthesize networkReachabilityStatus = _networkReachabilityStatus;
@synthesize networkReachabilityStatusBlock = _networkReachabilityStatusBlock;
#endif

+ (instancetype)clientWithBaseURL:(NSURL *)url {
    return [[self alloc] initWithBaseURL:url];
}

- (id)initWithBaseURL:(NSURL *)url {
    NSParameterAssert(url);
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected
    if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    self.baseURL = url;
    
    self.stringEncoding = NSUTF8StringEncoding;
    self.parameterEncoding = AVFormURLParameterEncoding;
	
    self.registeredHTTPOperationClassNames = [NSMutableArray array];
    
	self.defaultHeaders = [NSMutableDictionary dictionary];
	
    // Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    //NSString *preferredLanguageCodes = [[NSLocale preferredLanguages] componentsJoinedByString:@", "];
    //[self setDefaultHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@, en-us;q=0.8", preferredLanguageCodes]];

#if TARGET_OS_WATCH
    [self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (%@; watchOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[WKInterfaceDevice currentDevice] model], [[WKInterfaceDevice currentDevice] systemVersion], [WKInterfaceDevice currentDevice].screenScale]];
#elif TARGET_OS_TV
    [self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (%@; tvOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)]];
#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    [self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    [self setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]]];
#endif
    
#ifdef _SYSTEMCONFIGURATION_H
    self.networkReachabilityStatus = AVNetworkReachabilityStatusUnknown;
    [self startMonitoringNetworkReachability];
#endif
    
    self.operationQueue = [[NSOperationQueue alloc] init];
	[self.operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    
    return self;
}

- (void)dealloc {
#ifdef _SYSTEMCONFIGURATION_H
    [self stopMonitoringNetworkReachability];
#endif
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, baseURL: %@, defaultHeaders: %@, registeredOperationClasses: %@, operationQueue: %@>", NSStringFromClass([self class]), self, [self.baseURL absoluteString], self.defaultHeaders, self.registeredHTTPOperationClassNames, self.operationQueue];
}

#pragma mark -

#ifdef _SYSTEMCONFIGURATION_H
static BOOL AVURLHostIsIPAddress(NSURL *url) {
    struct sockaddr_in sa_in;
    struct sockaddr_in6 sa_in6;
    
    return [url host] && (inet_pton(AF_INET, [[url host] UTF8String], &sa_in) == 1 || inet_pton(AF_INET6, [[url host] UTF8String], &sa_in6) == 1);
}

static AVNetworkReachabilityStatus AVNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL isNetworkReachable = (isReachable && !needsConnection);
    
    AVNetworkReachabilityStatus status = AVNetworkReachabilityStatusUnknown;
    if (isNetworkReachable == NO) {
        status = AVNetworkReachabilityStatusNotReachable;
    }
#if	TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = AVNetworkReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        status = AVNetworkReachabilityStatusReachableViaWiFi;
    }
    
    return status;
}

static void AVNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    AVNetworkReachabilityStatus status = AVNetworkReachabilityStatusForFlags(flags);
    AVNetworkReachabilityStatusBlock block = (__bridge AVNetworkReachabilityStatusBlock)info;
    if (block) {
        block(status);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:AVNetworkingReachabilityDidChangeNotification object:nil userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:status] forKey:AVNetworkingReachabilityNotificationStatusItem]];
    });
}

static const void * AVNetworkReachabilityRetainCallback(const void *info) {
    return (__bridge_retained const void *)([(__bridge AVNetworkReachabilityStatusBlock)info copy]);
}

static void AVNetworkReachabilityReleaseCallback(const void *info) {
    if (info) {
        CFRelease(info);
    }
}

- (void)startMonitoringNetworkReachability {
    [self stopMonitoringNetworkReachability];
    
    if (!self.baseURL) {
        return;
    }
    
    self.networkReachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [[self.baseURL host] UTF8String]);
    
    if (!self.networkReachability) {
        return;
    }
    
    __weak __typeof(&*self)weakSelf = self;
    AVNetworkReachabilityStatusBlock callback = ^(AVNetworkReachabilityStatus status) {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }
    };
    
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, AVNetworkReachabilityRetainCallback, AVNetworkReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, AVNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), (CFStringRef)NSRunLoopCommonModes);
    
    /* Network reachability monitoring does not establish a baseline for IP addresses as it does for hostnames, so if the base URL host is an IP address, the initial reachability callback is manually triggered.
     */
    if (AVURLHostIsIPAddress(self.baseURL)) {
        SCNetworkReachabilityFlags flags;
        SCNetworkReachabilityGetFlags(self.networkReachability, &flags);
        dispatch_async(dispatch_get_main_queue(), ^{
            AVNetworkReachabilityStatus status = AVNetworkReachabilityStatusForFlags(flags);
            callback(status);
        });
    }
}

- (void)stopMonitoringNetworkReachability {
    if (_networkReachability) {
        SCNetworkReachabilityUnscheduleFromRunLoop(_networkReachability, CFRunLoopGetMain(), (CFStringRef)NSRunLoopCommonModes);
        CFRelease(_networkReachability);
        _networkReachability = NULL;
    }
}

- (void)setReachabilityStatusChangeBlock:(void (^)(AVNetworkReachabilityStatus status))block {
    self.networkReachabilityStatusBlock = block;
}
#endif

#pragma mark -

- (BOOL)registerHTTPOperationClass:(Class)operationClass {
    if (![operationClass isSubclassOfClass:[AVHTTPRequestOperation class]]) {
        return NO;
    }
    
    NSString *className = NSStringFromClass(operationClass);
    [self.registeredHTTPOperationClassNames removeObject:className];
    [self.registeredHTTPOperationClassNames insertObject:className atIndex:0];
    
    return YES;
}

- (void)unregisterHTTPOperationClass:(Class)operationClass {
    NSString *className = NSStringFromClass(operationClass);
    [self.registeredHTTPOperationClassNames removeObject:className];
}

#pragma mark -

- (NSString *)defaultValueForHeader:(NSString *)header {
	return [self.defaultHeaders valueForKey:header];
}

- (void)setDefaultHeader:(NSString *)header value:(NSString *)value {
    @synchronized (self.defaultHeaders) {
        [self.defaultHeaders setValue:value forKey:header];
    }
	
}

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password {
	NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", username, password];
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Basic %@", AVBase64EncodedStringFromString(basicAuthCredentials)]];
}

- (void)setAuthorizationHeaderWithToken:(NSString *)token {
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Token token=\"%@\"", token]];
}

- (void)clearAuthorizationHeader {
	[self.defaultHeaders removeObjectForKey:@"Authorization"];
}

#pragma mark -

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    NSParameterAssert(method);
    
    if (!path) {
        path = @"";
    }
    
    NSURL *url = [NSURL URLWithString:path relativeToURL:self.baseURL];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    
    //防止元素读时线程无法访问
    NSDictionary *heads=[self.defaultHeaders copy];
    [request setAllHTTPHeaderFields:heads];
    
    if (parameters) {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingFormat:[path rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", AVQueryStringFromParametersWithEncoding(parameters, self.stringEncoding)]];
            [request setURL:url];
        } else {
            NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(self.stringEncoding));
            NSError *error = nil;
            
            switch (self.parameterEncoding) {
                case AVFormURLParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
                    [request setHTTPBody:[AVQueryStringFromParametersWithEncoding(parameters, self.stringEncoding) dataUsingEncoding:self.stringEncoding]];
                    break;
                case AVJSONParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
                    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error]];
                    break;
                case AVPropertyListParameterEncoding:;
                    [request setValue:[NSString stringWithFormat:@"application/x-plist; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
                    [request setHTTPBody:[NSPropertyListSerialization dataWithPropertyList:parameters format:NSPropertyListXMLFormat_v1_0 options:0 error:&error]];
                    break;
            }
            
            if (error) {
                NSLog(@"%@ %@: %@", [self class], NSStringFromSelector(_cmd), error);
            }
        }
    }
    
	return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AVMultipartFormData> formData))block
{
    NSParameterAssert(method);
    NSParameterAssert(![method isEqualToString:@"GET"] && ![method isEqualToString:@"HEAD"]);
    
    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:nil];
    
    __block AVStreamingMultipartFormData *formData = [[AVStreamingMultipartFormData alloc] initWithURLRequest:request stringEncoding:self.stringEncoding];
    
    if (parameters) {
        for (AVQueryStringPair *pair in AVQueryStringPairsFromDictionary(parameters)) {
            NSData *data = nil;
            if ([pair.value isKindOfClass:[NSData class]]) {
                data = pair.value;
            } else if ([pair.value isEqual:[NSNull null]]) {
                data = [NSData data];
            } else {
                data = [[pair.value description] dataUsingEncoding:self.stringEncoding];
            }
            
            if (data) {
                [formData appendPartWithFormData:data name:[pair.field description]];
            }
        }
    }
    
    if (block) {
        block(formData);
    }
    
    return [formData requestByFinalizingMultipartFormData];
}

- (AVHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(AVHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AVHTTPRequestOperation *operation, NSError *error))failure
{
    AVHTTPRequestOperation *operation = nil;
    NSString *className = nil;
    NSEnumerator *enumerator = [self.registeredHTTPOperationClassNames reverseObjectEnumerator];
    while (!operation && (className = [enumerator nextObject])) {
        Class op_class = NSClassFromString(className);
        if (op_class && [op_class canProcessRequest:urlRequest]) {
            operation = [(AVHTTPRequestOperation *)[op_class alloc] initWithRequest:urlRequest];
        }
    }
    
    if (!operation) {
        operation = [[AVHTTPRequestOperation alloc] initWithRequest:urlRequest];
    }
    
    [operation setCompletionBlockWithSuccess:success failure:failure];
    
    return operation;
}

#pragma mark -

- (void)enqueueHTTPRequestOperation:(AVHTTPRequestOperation *)operation {
    if (getenv("LOG_CURL")) {
        NSLog(@"%@",[operation.request cURLCommand]);
    }
    NSString *path = operation.request.URL.path;
    AVLoggerDebug(AVLoggerDomainCURL, LC_REST_REQUEST_LOG_FORMAT, path, [operation.request cURLCommand]);
    [self.operationQueue addOperation:operation];
}

- (void)cancelAllHTTPOperationsWithMethod:(NSString *)method
                                     path:(NSString *)path
{
    NSString *URLStringToMatched = [[[self requestWithMethod:(method ?: @"GET") path:path parameters:nil] URL] absoluteString];
    
    for (NSOperation *operation in [self.operationQueue operations]) {
        if (![operation isKindOfClass:[AVHTTPRequestOperation class]]) {
            continue;
        }
        
        BOOL hasMatchingMethod = !method || [method isEqualToString:[[(AVHTTPRequestOperation *)operation request] HTTPMethod]];
        BOOL hasMatchingURL = [[[[(AVHTTPRequestOperation *)operation request] URL] absoluteString] isEqualToString:URLStringToMatched];
        
        if (hasMatchingMethod && hasMatchingURL) {
            [operation cancel];
        }
    }
}

- (void)enqueueBatchOfHTTPRequestOperationsWithRequests:(NSArray *)urlRequests
                                          progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                                        completionBlock:(void (^)(NSArray *operations))completionBlock
{
    NSMutableArray *mutableOperations = [NSMutableArray array];
    for (NSURLRequest *request in urlRequests) {
        AVHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:nil failure:nil];
        [mutableOperations addObject:operation];
    }
    
    [self enqueueBatchOfHTTPRequestOperations:mutableOperations progressBlock:progressBlock completionBlock:completionBlock];
}

- (void)enqueueBatchOfHTTPRequestOperations:(NSArray *)operations
                              progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                            completionBlock:(void (^)(NSArray *operations))completionBlock
{
    __block dispatch_group_t dispatchGroup = dispatch_group_create();
    NSBlockOperation *batchedOperation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(operations);
            }
        });
#if !OS_OBJECT_USE_OBJC
        dispatch_release(dispatchGroup);
#endif
    }];
    
    for (AVHTTPRequestOperation *operation in operations) {
        AVCompletionBlock originalCompletionBlock = [operation.completionBlock copy];
		__weak AVHTTPRequestOperation *weakOperation = operation;
        operation.completionBlock = ^{
            dispatch_queue_t queue = weakOperation.successCallbackQueue ?: dispatch_get_main_queue();
            dispatch_group_async(dispatchGroup, queue, ^{
                if (originalCompletionBlock) {
                    originalCompletionBlock();
                }
                
                __block NSUInteger numberOfFinishedOperations = 0;
                [operations enumerateObjectsUsingBlock:^(id obj, __unused NSUInteger idx, __unused BOOL *stop) {
                    if ([(NSOperation *)obj isFinished]) {
                        numberOfFinishedOperations++;
                    }
                }];
                
                if (progressBlock) {
                    progressBlock(numberOfFinishedOperations, [operations count]);
                }
                
                dispatch_group_leave(dispatchGroup);
            });
        };
        
        dispatch_group_enter(dispatchGroup);
        [batchedOperation addDependency:operation];
    }
    [self.operationQueue addOperations:operations waitUntilFinished:NO];
    [self.operationQueue addOperation:batchedOperation];
}

#pragma mark -

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(AVHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AVHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"GET" path:path parameters:parameters];
    AVHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
         success:(void (^)(AVHTTPRequestOperation *operation, id responseObject))success
         failure:(void (^)(AVHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
	AVHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
        success:(void (^)(AVHTTPRequestOperation *operation, id responseObject))success
        failure:(void (^)(AVHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"PUT" path:path parameters:parameters];
	AVHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(AVHTTPRequestOperation *operation, id responseObject))success
           failure:(void (^)(AVHTTPRequestOperation *operation, NSError *error))failure
{
	NSURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:parameters];
	AVHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)patchPath:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(AVHTTPRequestOperation *operation, id responseObject))success
          failure:(void (^)(AVHTTPRequestOperation *operation, NSError *error))failure
{
    NSURLRequest *request = [self requestWithMethod:@"PATCH" path:path parameters:parameters];
	AVHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [self enqueueHTTPRequestOperation:operation];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSURL *baseURL = [aDecoder decodeObjectForKey:@"baseURL"];
    
    self = [self initWithBaseURL:baseURL];
    if (!self) {
        return nil;
    }
    
    self.stringEncoding = [aDecoder decodeIntegerForKey:@"stringEncoding"];
    self.parameterEncoding = (AVHTTPClientParameterEncoding)[aDecoder decodeIntegerForKey:@"parameterEncoding"];
    self.registeredHTTPOperationClassNames = [aDecoder decodeObjectForKey:@"registeredHTTPOperationClassNames"];
    self.defaultHeaders = [aDecoder decodeObjectForKey:@"defaultHeaders"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.baseURL forKey:@"baseURL"];
    [aCoder encodeInteger:(NSInteger)self.stringEncoding forKey:@"stringEncoding"];
    [aCoder encodeInteger:self.parameterEncoding forKey:@"parameterEncoding"];
    [aCoder encodeObject:self.registeredHTTPOperationClassNames forKey:@"registeredHTTPOperationClassNames"];
    [aCoder encodeObject:self.defaultHeaders forKey:@"defaultHeaders"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AVHTTPClient *HTTPClient = [[[self class] allocWithZone:zone] initWithBaseURL:self.baseURL];
    
    HTTPClient.stringEncoding = self.stringEncoding;
    HTTPClient.parameterEncoding = self.parameterEncoding;
    HTTPClient.registeredHTTPOperationClassNames = [self.registeredHTTPOperationClassNames copyWithZone:zone];
    HTTPClient.defaultHeaders = [self.defaultHeaders copyWithZone:zone];
#ifdef _SYSTEMCONFIGURATION_H
    HTTPClient.networkReachabilityStatusBlock = self.networkReachabilityStatusBlock;
#endif
    return HTTPClient;
}

@end

#pragma mark -

static NSString * const kAVMultipartFormBoundary = @"Boundary+0xAbCdEfGbOuNdArY";

static NSString * const kAVMultipartFormCRLF = @"\r\n";

static inline NSString * AVMultipartFormInitialBoundary() {
    return [NSString stringWithFormat:@"--%@%@", kAVMultipartFormBoundary, kAVMultipartFormCRLF];
}

static inline NSString * AVMultipartFormEncapsulationBoundary() {
    return [NSString stringWithFormat:@"%@--%@%@", kAVMultipartFormCRLF, kAVMultipartFormBoundary, kAVMultipartFormCRLF];
}

static inline NSString * AVMultipartFormFinalBoundary() {
    return [NSString stringWithFormat:@"%@--%@--%@", kAVMultipartFormCRLF, kAVMultipartFormBoundary, kAVMultipartFormCRLF];
}

static inline NSString * AVContentTypeForPathExtension(NSString *extension) {
#ifdef __UTTYPE__
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    return (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
#else
    return @"application/octet-stream";
#endif
}

NSUInteger const kAVUploadStream3GSuggestedPacketSize = 1024 * 16;
NSTimeInterval const kAVUploadStream3GSuggestedDelay = 0.2;

@interface AVHTTPBodyPart : NSObject
@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, assign) unsigned long long bodyContentLength;

@property (nonatomic, assign) BOOL hasInitialBoundary;
@property (nonatomic, assign) BOOL hasFinalBoundary;

@property (nonatomic, readonly, getter = hasBytesAvailable) BOOL bytesAvailable;
@property (nonatomic, readonly) unsigned long long contentLength;

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)length;
@end

@interface AVMultipartBodyStream : NSInputStream <NSStreamDelegate>
@property (nonatomic, assign) NSUInteger numberOfBytesInPacket;
@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, readonly) unsigned long long contentLength;
@property (nonatomic, readonly, getter = isEmpty) BOOL empty;

- (id)initWithStringEncoding:(NSStringEncoding)encoding;
- (void)setInitialAndFinalBoundaries;
- (void)appendHTTPBodyPart:(AVHTTPBodyPart *)bodyPart;
@end

#pragma mark -

@interface AVStreamingMultipartFormData ()
@property (readwrite, nonatomic, copy) NSMutableURLRequest *request;
@property (readwrite, nonatomic, strong) AVMultipartBodyStream *bodyStream;
@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;
@end

@implementation AVStreamingMultipartFormData
@synthesize request = _request;
@synthesize bodyStream = _bodyStream;
@synthesize stringEncoding = _stringEncoding;

- (id)initWithURLRequest:(NSMutableURLRequest *)urlRequest
          stringEncoding:(NSStringEncoding)encoding
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.request = urlRequest;
    self.stringEncoding = encoding;
    self.bodyStream = [[AVMultipartBodyStream alloc] initWithStringEncoding:encoding];
    
    return self;
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    
    if (![fileURL isFileURL]) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedStringFromTable(@"Expected URL to be a file URL", @"AVNetworking", nil) forKey:NSLocalizedFailureReasonErrorKey];
        if (error != NULL) {
            *error = [[NSError alloc] initWithDomain:AVNetworkingErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        
        return NO;
    } else if ([fileURL checkResourceIsReachableAndReturnError:error] == NO) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:NSLocalizedStringFromTable(@"File URL not reachable.", @"AVNetworking", nil) forKey:NSLocalizedFailureReasonErrorKey];
        if (error != NULL) {
            *error = [[NSError alloc] initWithDomain:AVNetworkingErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        
        return NO;
    }
    
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, [fileURL lastPathComponent]] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:AVContentTypeForPathExtension([fileURL pathExtension]) forKey:@"Content-Type"];
    
    AVHTTPBodyPart *bodyPart = [[AVHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = mutableHeaders;
    bodyPart.inputStream = [NSInputStream inputStreamWithURL:fileURL];
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:nil];
    bodyPart.bodyContentLength = [[fileAttributes objectForKey:NSFileSize] unsignedLongLongValue];
    
    [self.bodyStream appendHTTPBodyPart:bodyPart];
    
    return YES;
}

- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType
{
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name
{
    NSParameterAssert(name);
    
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithHeaders:(NSDictionary *)headers
                         body:(NSData *)body
{
    NSParameterAssert(body);
    
    AVHTTPBodyPart *bodyPart = [[AVHTTPBodyPart alloc] init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = headers;
    bodyPart.bodyContentLength = [body length];
    bodyPart.inputStream = [NSInputStream inputStreamWithData:body];
    
    [self.bodyStream appendHTTPBodyPart:bodyPart];
}

- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay
{
    self.bodyStream.numberOfBytesInPacket = numberOfBytes;
    self.bodyStream.delay = delay;
}

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData {
    if ([self.bodyStream isEmpty]) {
        return self.request;
    }
    
    // Reset the initial and final boundaries to ensure correct Content-Length
    [self.bodyStream setInitialAndFinalBoundaries];
    
    [self.request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kAVMultipartFormBoundary] forHTTPHeaderField:@"Content-Type"];
    [self.request setValue:[NSString stringWithFormat:@"%llu", [self.bodyStream contentLength]] forHTTPHeaderField:@"Content-Length"];
    [self.request setHTTPBodyStream:self.bodyStream];
    
    return self.request;
}

@end

#pragma mark -

@interface AVMultipartBodyStream ()
@property (nonatomic, assign) NSStreamStatus streamStatus;
@property (nonatomic, strong) NSError *streamError;

@property (nonatomic, assign) NSStringEncoding stringEncoding;
@property (nonatomic, strong) NSMutableArray *HTTPBodyParts;
@property (nonatomic, strong) NSEnumerator *HTTPBodyPartEnumerator;
@property (nonatomic, strong) AVHTTPBodyPart *currentHTTPBodyPart;
@end

@implementation AVMultipartBodyStream
@synthesize streamStatus = _streamStatus;
@synthesize streamError = _streamError;
@synthesize stringEncoding = _stringEncoding;
@synthesize HTTPBodyParts = _HTTPBodyParts;
@synthesize HTTPBodyPartEnumerator = _HTTPBodyPartEnumerator;
@synthesize currentHTTPBodyPart = _currentHTTPBodyPart;
@synthesize numberOfBytesInPacket = _numberOfBytesInPacket;
@synthesize delay = _delay;

- (id)initWithStringEncoding:(NSStringEncoding)encoding {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.stringEncoding = encoding;
    self.HTTPBodyParts = [NSMutableArray array];
    self.numberOfBytesInPacket = NSIntegerMax;
    
    return self;
}

- (void)setInitialAndFinalBoundaries {
    if ([self.HTTPBodyParts count] > 0) {
        for (AVHTTPBodyPart *bodyPart in self.HTTPBodyParts) {
            bodyPart.hasInitialBoundary = NO;
            bodyPart.hasFinalBoundary = NO;
        }
        
        [[self.HTTPBodyParts objectAtIndex:0] setHasInitialBoundary:YES];
        [[self.HTTPBodyParts lastObject] setHasFinalBoundary:YES];
    }
}

- (void)appendHTTPBodyPart:(AVHTTPBodyPart *)bodyPart {
    [self.HTTPBodyParts addObject:bodyPart];
}

- (BOOL)isEmpty {
    return [self.HTTPBodyParts count] == 0;
}

#pragma mark - NSInputStream

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)length {
    if ([self streamStatus] == NSStreamStatusClosed) {
        return 0;
    }
    NSInteger bytesRead = 0;
    
    while ((NSUInteger)bytesRead < MIN(length, self.numberOfBytesInPacket)) {
        if (!self.currentHTTPBodyPart || ![self.currentHTTPBodyPart hasBytesAvailable]) {
            if (!(self.currentHTTPBodyPart = [self.HTTPBodyPartEnumerator nextObject])) {
                break;
            }
        } else {
            bytesRead += [self.currentHTTPBodyPart read:&buffer[bytesRead] maxLength:(length - (NSUInteger)bytesRead)];
            if (self.delay > 0.0f) {
                [NSThread sleepForTimeInterval:self.delay];
            }
        }
    }
    return bytesRead;
}

- (BOOL)getBuffer:(__unused uint8_t **)buffer length:(__unused NSUInteger *)len {
    return NO;
}

- (BOOL)hasBytesAvailable {
    return [self streamStatus] == NSStreamStatusOpen;
}

#pragma mark - NSStream

- (void)open {
    if (self.streamStatus == NSStreamStatusOpen) {
        return;
    }
    
    self.streamStatus = NSStreamStatusOpen;
    
    [self setInitialAndFinalBoundaries];
    self.HTTPBodyPartEnumerator = [self.HTTPBodyParts objectEnumerator];
}

- (void)close {
    self.streamStatus = NSStreamStatusClosed;
}

- (id)propertyForKey:(__unused NSString *)key {
    return nil;
}

- (BOOL)setProperty:(__unused id)property forKey:(__unused NSString *)key {
    return NO;
}

- (void)scheduleInRunLoop:(__unused NSRunLoop *)aRunLoop
                  forMode:(__unused NSString *)mode
{}

- (void)removeFromRunLoop:(__unused NSRunLoop *)aRunLoop
                  forMode:(__unused NSString *)mode
{}

- (unsigned long long)contentLength {
    unsigned long long length = 0;
    for (AVHTTPBodyPart *bodyPart in self.HTTPBodyParts) {
        length += [bodyPart contentLength];
    }
    
    return length;
}

#pragma mark - Undocumented CFReadStream Bridged Methods

- (void)_scheduleInCFRunLoop:(__unused CFRunLoopRef)aRunLoop
                     forMode:(__unused CFStringRef)aMode
{}

- (void)_unscheduleFromCFRunLoop:(__unused CFRunLoopRef)aRunLoop
                         forMode:(__unused CFStringRef)aMode
{}

- (BOOL)_setCFClientFlags:(__unused CFOptionFlags)inFlags
                 callback:(__unused CFReadStreamClientCallBack)inCallback
                  context:(__unused CFStreamClientContext *)inContext {
    return NO;
}

@end

#pragma mark -

typedef enum {
    AVEncapsulationBoundaryPhase = 1,
    AVHeaderPhase                = 2,
    AVBodyPhase                  = 3,
    AVFinalBoundaryPhase         = 4,
} AVHTTPBodyPartReadPhase;

@interface AVHTTPBodyPart () {
    AVHTTPBodyPartReadPhase _phase;
    unsigned long long _phaseReadOffset;
}

- (BOOL)transitionToNextPhase;
@end

@implementation AVHTTPBodyPart
@synthesize stringEncoding = _stringEncoding;
@synthesize headers = _headers;
@synthesize bodyContentLength = _bodyContentLength;
@synthesize inputStream = _inputStream;
@synthesize hasInitialBoundary = _hasInitialBoundary;
@synthesize hasFinalBoundary = _hasFinalBoundary;

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    [self transitionToNextPhase];
    
    return self;
}

- (void)dealloc {
    if (_inputStream) {
        [_inputStream close];
        _inputStream = nil;
    }
}

- (NSString *)stringForHeaders {
    NSMutableString *headerString = [NSMutableString string];
    for (NSString *field in [self.headers allKeys]) {
        [headerString appendString:[NSString stringWithFormat:@"%@: %@%@", field, [self.headers valueForKey:field], kAVMultipartFormCRLF]];
    }
    [headerString appendString:kAVMultipartFormCRLF];
    
    return [NSString stringWithString:headerString];
}

- (unsigned long long)contentLength {
    unsigned long long length = 0;
    
    NSData *encapsulationBoundaryData = [([self hasInitialBoundary] ? AVMultipartFormInitialBoundary() : AVMultipartFormEncapsulationBoundary()) dataUsingEncoding:self.stringEncoding];
    length += [encapsulationBoundaryData length];
    
    NSData *headersData = [[self stringForHeaders] dataUsingEncoding:self.stringEncoding];
    length += [headersData length];
    
    length += _bodyContentLength;
    
    NSData *closingBoundaryData = ([self hasFinalBoundary] ? [AVMultipartFormFinalBoundary() dataUsingEncoding:self.stringEncoding] : [NSData data]);
    length += [closingBoundaryData length];
    
    return length;
}

- (BOOL)hasBytesAvailable {
    // Allows `read:maxLength:` to be called again if `AVMultipartFormFinalBoundary` doesn't fit into the avaiable buffer
    if (_phase == AVFinalBoundaryPhase) {
        return YES;
    }
    
    switch (self.inputStream.streamStatus) {
        case NSStreamStatusNotOpen:
        case NSStreamStatusOpening:
        case NSStreamStatusOpen:
        case NSStreamStatusReading:
        case NSStreamStatusWriting:
            return YES;
        case NSStreamStatusAtEnd:
        case NSStreamStatusClosed:
        case NSStreamStatusError:
            return NO;
    }
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)length {
    NSInteger bytesRead = 0;
    
    if (_phase == AVEncapsulationBoundaryPhase) {
        NSData *encapsulationBoundaryData = [([self hasInitialBoundary] ? AVMultipartFormInitialBoundary() : AVMultipartFormEncapsulationBoundary()) dataUsingEncoding:self.stringEncoding];
        bytesRead += [self readData:encapsulationBoundaryData intoBuffer:&buffer[bytesRead] maxLength:(length - (NSUInteger)bytesRead)];
    }
    
    if (_phase == AVHeaderPhase) {
        NSData *headersData = [[self stringForHeaders] dataUsingEncoding:self.stringEncoding];
        bytesRead += [self readData:headersData intoBuffer:&buffer[bytesRead] maxLength:(length - (NSUInteger)bytesRead)];
    }
    
    if (_phase == AVBodyPhase) {
        if ([self.inputStream hasBytesAvailable]) {
            bytesRead += [self.inputStream read:&buffer[bytesRead] maxLength:(length - (NSUInteger)bytesRead)];
        }
        
        if (![self.inputStream hasBytesAvailable]) {
            [self transitionToNextPhase];
        }
    }
    
    if (_phase == AVFinalBoundaryPhase) {
        NSData *closingBoundaryData = ([self hasFinalBoundary] ? [AVMultipartFormFinalBoundary() dataUsingEncoding:self.stringEncoding] : [NSData data]);
        bytesRead += [self readData:closingBoundaryData intoBuffer:&buffer[bytesRead] maxLength:(length - (NSUInteger)bytesRead)];
    }

    return bytesRead;
}

- (NSInteger)readData:(NSData *)data
           intoBuffer:(uint8_t *)buffer
            maxLength:(NSUInteger)length
{
    NSRange range = NSMakeRange((NSUInteger)_phaseReadOffset, MIN([data length] - ((NSUInteger)_phaseReadOffset), length));
    [data getBytes:buffer range:range];
    
    _phaseReadOffset += range.length;
    
    if (((NSUInteger)_phaseReadOffset) >= [data length]) {
        [self transitionToNextPhase];
    }
    
    return (NSInteger)range.length;
}

- (BOOL)transitionToNextPhase {
    if (![[NSThread currentThread] isMainThread]) {
        [self performSelectorOnMainThread:@selector(transitionToNextPhase) withObject:nil waitUntilDone:YES];
        return YES;
    }
    
    switch (_phase) {
        case AVEncapsulationBoundaryPhase:
            _phase = AVHeaderPhase;
            break;
        case AVHeaderPhase:
            [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
            [self.inputStream open];
            _phase = AVBodyPhase;
            break;
        case AVBodyPhase:
            [self.inputStream close];
            _phase = AVFinalBoundaryPhase;
            break;
        case AVFinalBoundaryPhase:
        default:
            _phase = AVEncapsulationBoundaryPhase;
            break;
    }
    _phaseReadOffset = 0;
    
    return YES;
}

@end
