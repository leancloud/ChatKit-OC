//
//  AVLogger.m
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVLogger.h"

NSString *const AVLoggerDomainCURL = @"LOG_CURL";
NSString *const AVLoggerDomainNetwork = @"LOG_NETWORK";
NSString *const AVLoggerDomainStorage = @"LOG_STORAGE";
NSString *const AVLoggerDomainIM = @"LOG_IM";
NSString *const AVLoggerDomainDefault = @"LOG_DEFAULT";

static NSMutableSet *loggerDomain = nil;
static NSUInteger loggerLevelMask = AVLoggerLevelNone;
static NSArray *loggerDomains = nil;

@implementation AVLogger

+ (void)load {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        loggerDomains = @[
                          AVLoggerDomainCURL,
                          AVLoggerDomainNetwork,
                          AVLoggerDomainIM,
                          AVLoggerDomainStorage,
                          AVLoggerDomainDefault
                          ];
    });
#ifdef DEBUG
    [self setAllLogsEnabled:YES];
#else
    [self setAllLogsEnabled:NO];
#endif
}

+ (void)setAllLogsEnabled:(BOOL)enabled {
    if (enabled) {
        for (NSString *loggerDomain in loggerDomains) {
            [AVLogger addLoggerDomain:loggerDomain];
        }
        [AVLogger setLoggerLevelMask:AVLoggerLevelAll];
    } else {
        for (NSString *loggerDomain in loggerDomains) {
            [AVLogger removeLoggerDomain:loggerDomain];
        }
        [AVLogger setLoggerLevelMask:AVLoggerLevelNone];
    }

    [self setCertificateInspectionEnabled:enabled];
}

+ (void)setCertificateInspectionEnabled:(BOOL)enabled {
    if (enabled) {
        setenv("CURL_INSPECT_CERT", "YES", 1);
    } else {
        unsetenv("CURL_INSPECT_CERT");
    }
}

+ (void)setLoggerLevelMask:(NSUInteger)levelMask {
    loggerLevelMask = levelMask;
}

+ (void)addLoggerDomain:(NSString *)domain {
    if (!loggerDomain) {
        loggerDomain = [[NSMutableSet alloc] init];
    }
    [loggerDomain addObject:domain];
}

+ (void)removeLoggerDomain:(NSString *)domain {
    [loggerDomain removeObject:domain];
}

+ (BOOL)levelEnabled:(AVLoggerLevel)level {
    return loggerLevelMask & level;
}

+ (BOOL)containDomain:(NSString *)domain {
    return [loggerDomain containsObject:domain];
}

+ (void)logFunc:(const char *)func line:(int)line domain:(NSString *)domain level:(AVLoggerLevel)level message:(NSString *)fmt, ... {
    if (!domain || [loggerDomain containsObject:domain]) {
        if (level & loggerLevelMask) {
            NSString *levelString = nil;
            switch (level) {
                case AVLoggerLevelInfo:
                    levelString = @"INFO";
                    break;
                case AVLoggerLevelDebug:
                    levelString = @"DEBUG";
                    break;
                case AVLoggerLevelError:
                    levelString = @"ERROR";
                    break;
                    
                default:
                    levelString = @"UNKNOW";
                    break;
            }
            va_list args;
            va_start(args, fmt);
            NSString *message = [[NSString alloc] initWithFormat:fmt arguments:args];
            va_end(args);
            NSLog(@"[%@] %s [Line %d] %@", levelString, func, line, message);
        }
    }
}

@end
