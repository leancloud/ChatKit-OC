//
//  AVLogger.h
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    AVLoggerLevelNone = 0,
    AVLoggerLevelInfo = 1,
    AVLoggerLevelDebug = 1 << 1,
    AVLoggerLevelError = 1 << 2,
    AVLoggerLevelAll = AVLoggerLevelInfo | AVLoggerLevelDebug | AVLoggerLevelError,
} AVLoggerLevel;

extern NSString *const AVLoggerDomainCURL;
extern NSString *const AVLoggerDomainNetwork;
extern NSString *const AVLoggerDomainIM;
extern NSString *const AVLoggerDomainStorage;
extern NSString *const AVLoggerDomainDefault;

@interface AVLogger : NSObject
+ (void)setAllLogsEnabled:(BOOL)enabled;
+ (void)setLoggerLevelMask:(NSUInteger)levelMask;
+ (void)addLoggerDomain:(NSString *)domain;
+ (void)removeLoggerDomain:(NSString *)domain;
+ (void)logFunc:(const char *)func line:(const int)line domain:(NSString *)domain level:(AVLoggerLevel)level message:(NSString *)fmt, ... NS_FORMAT_FUNCTION(5, 6);
+ (BOOL)levelEnabled:(AVLoggerLevel)level;
+ (BOOL)containDomain:(NSString *)domain;
@end

#define _AVLoggerInfo(_domain, ...) [AVLogger logFunc:__func__ line:__LINE__ domain:_domain level:AVLoggerLevelInfo message:__VA_ARGS__]
#define _AVLoggerDebug(_domain, ...) [AVLogger logFunc:__func__ line:__LINE__ domain:_domain level:AVLoggerLevelDebug message:__VA_ARGS__]
#define _AVLoggerError(_domain, ...) [AVLogger logFunc:__func__ line:__LINE__ domain:_domain level:AVLoggerLevelError message:__VA_ARGS__]

#define AVLoggerInfo(domain, ...) _AVLoggerInfo(domain, __VA_ARGS__)
#define AVLoggerDebug(domain, ...) _AVLoggerDebug(domain, __VA_ARGS__)
#define AVLoggerError(domain, ...) _AVLoggerError(domain, __VA_ARGS__)

#define AVLoggerI(...)  AVLoggerInfo(AVLoggerDomainDefault, __VA_ARGS__)
#define AVLoggerD(...) AVLoggerDebug(AVLoggerDomainDefault, __VA_ARGS__)
#define AVLoggerE(...) AVLoggerError(AVLoggerDomainDefault, __VA_ARGS__)
