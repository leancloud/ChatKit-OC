//
//  AVCommandDictionary.m
//  AVOS
//
//  Created by Qihe Bian on 7/22/14.
//
//

#import "AVCommandDictionary.h"

@interface AVCommandDictionary () {
    NSMutableDictionary *_fileds;
}

@end
@implementation AVCommandDictionary
- (instancetype)init {
    if ((self = [super init])) {
        _fileds = [NSMutableDictionary dictionary];
    }
    return self;
}
- (void)setObject:(id)object forKey:(NSString *)key {
    if (object && key) {
        [_fileds setObject:object forKey:key];
    }
}

- (void)removeObjectForKey:(NSString *)key {
    if (key) {
        [_fileds removeObjectForKey:key];
    }
}

- (NSString *)JSONString {
    @try {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:_fileds options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            return nil;
        } else {
            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }
    @catch (NSException *exception) {
        return nil;
    }
}
@end
