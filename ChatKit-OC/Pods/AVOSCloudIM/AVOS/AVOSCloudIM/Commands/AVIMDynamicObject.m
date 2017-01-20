//
//  AVIMDynamicObject.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 12/4/14.
//  Copyright (c) 2014 LeanCloud Inc. All rights reserved.
//

#import "AVIMDynamicObject.h"
#include <objc/runtime.h>
#import "AVLogger.h"
#import "AVMPMessagePack.h"

static void *methodResolvedKey = &methodResolvedKey;
static void *methodMapKey = &methodMapKey;

@interface AVIMPropertyAttribute : NSObject {
    objc_property_t _property;
}
@property(nonatomic)BOOL isReadonly;
@property(nonatomic)BOOL isCopy;
@property(nonatomic)BOOL isRetain;
@property(nonatomic)BOOL isNonatomic;
@property(nonatomic)BOOL isDynamic;
@property(nonatomic)BOOL isWeak;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *getter;
@property(nonatomic, strong)NSString *setter;
@property(nonatomic)char typeCode;

@end
@implementation AVIMPropertyAttribute
- (instancetype)initWithProperty:(objc_property_t)property {
    if ((self = [super init])) {
        _property = property;
        [self parseProperty];
    }
    return self;
}

//Code
//Meaning
//R
//The property is read-only (readonly).
//C
//The property is a copy of the value last assigned (copy).
//&
//The property is a reference to the value last assigned (retain).
//N
//The property is non-atomic (nonatomic).
//G<name>
//The property defines a custom getter selector name. The name follows the G (for example, GcustomGetter,).
//S<name>
//The property defines a custom setter selector name. The name follows the S (for example, ScustomSetter:,).
//D
//The property is dynamic (@dynamic).
//W
//The property is a weak reference (__weak).
//P
//The property is eligible for garbage collection.
//t<encoding>
//Specifies the type using old-style encoding.
- (void)parseProperty {
    const char * attrs = property_getAttributes( _property );
    if (!attrs) {
        return;
    }
    NSString *attrsString = [NSString stringWithFormat:@"%s", attrs];
    NSArray *attrArray = [attrsString componentsSeparatedByString:@","];
    for (NSString *attr in attrArray) {
        char a = [attr characterAtIndex:0];
        switch (a) {
            case 'T':
                _typeCode = [attr characterAtIndex:1];
                break;
            case 'R':
                _isReadonly = YES;
                break;
            case 'C':
                _isCopy = YES;
                break;
            case '&':
                _isRetain = YES;
                break;
            case 'N':
                _isNonatomic = YES;
                break;
            case 'D':
                _isDynamic = YES;
                break;
            case 'W':
                _isWeak = YES;
                break;
            case 'G':
                _getter = [attr substringFromIndex:1];
                break;
            case 'S':
                _setter = [attr substringFromIndex:1];
                break;
                
            default:
                break;
        }
    }
    const char *name = property_getName(_property);
    if (name) {
        _name = [[NSString alloc] initWithUTF8String:name];
    }
    if (!_getter) {
        _getter = _name;
    }
    if (!_isReadonly && !_setter && _name) {
        NSString *nameString = _name;
        _setter = [[NSString alloc] initWithFormat:@"set%@%@:",
                   [[nameString substringToIndex:1] uppercaseString],
                   [nameString substringFromIndex:1]];
    }
}
@end
#pragma mark - Util
// @selector(setDisplayName:) -> @"displayName"
static AVIMPropertyAttribute *attributeFromSelector(Class class, SEL selector) {
    if (class == [AVIMDynamicObject class] || !class) {
        return nil;
    }
    NSDictionary *methodMap = objc_getAssociatedObject(class, methodMapKey);
    
    NSString *SELString = NSStringFromSelector(selector);
    AVIMPropertyAttribute *attr = [methodMap objectForKey:SELString];
    if (attr) {
        return attr;
    } else {
        return attributeFromSelector(class_getSuperclass(class), selector);
    }
}

#pragma mark - Runtime
// @
static id getter(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    id result = nil;
    if (attr.isWeak) {
        NSValue *v = [self objectForKey:attr.name];
        result = [v nonretainedObjectValue];
    } else {
        result = [self objectForKey:attr.name];
    }
    if (result == [NSNull null]) {
        result = nil;
    }
    return result;
}

static void setter(id self, SEL _cmd, id value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    if (attr.isCopy) {
        [self setObject:[value copy] forKey:attr.name];
    } else if (attr.isWeak) {
        NSValue *v = [NSValue valueWithNonretainedObject:value];
        [self setObject:v forKey:attr.name];
    } else if (attr.isRetain) {
        [self setObject:value forKey:attr.name];
    }
}

static id getterAtomic(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        id result = nil;
        if (attr.isWeak) {
            NSValue *v = [self objectForKey:attr.name];
            result = [v nonretainedObjectValue];
        } else {
            result = [self objectForKey:attr.name];
        }
        if (result == [NSNull null]) {
            result = nil;
        }
        return result;
    }
}

static void setterAtomic(id self, SEL _cmd, id value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        if (attr.isCopy) {
            [self setObject:[value copy] forKey:attr.name];
        } else if (attr.isWeak) {
            NSValue *v = [NSValue valueWithNonretainedObject:value];
            [self setObject:v forKey:attr.name];
        } else if (attr.isRetain) {
            [self setObject:value forKey:attr.name];
        }
    }
}

// l, i, c,....
static BOOL getter_b(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    return [[self objectForKey:attr.name] boolValue];
}

static void setter_b(id self, SEL _cmd, BOOL value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    //    id v = [self valueForKey:attr.name];
    [self setObject:@(value) forKey:attr.name];
}

static BOOL getter_bAtomic(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        return [[self objectForKey:attr.name] boolValue];
    }
}

static void setter_bAtomic(id self, SEL _cmd, BOOL value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        [self setObject:@(value) forKey:attr.name];
    }
}

static char getter_c(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    return [[self objectForKey:attr.name] charValue];
}

static void setter_c(id self, SEL _cmd, char value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    //    id v = [self valueForKey:attr.name];
    [self setObject:@(value) forKey:attr.name];
}

static char getter_cAtomic(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        return [[self objectForKey:attr.name] charValue];
    }
}

static void setter_cAtomic(id self, SEL _cmd, char value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        [self setObject:@(value) forKey:attr.name];
    }
}


static long getter_l(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    return [[self objectForKey:attr.name] longValue];
}

static void setter_l(id self, SEL _cmd, long value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    //    id v = [self valueForKey:attr.name];
    [self setObject:@(value) forKey:attr.name];
}

static long getter_lAtomic(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        return [[self objectForKey:attr.name] longValue];
    }
}

static void setter_lAtomic(id self, SEL _cmd, long value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        [self setObject:@(value) forKey:attr.name];
    }
}

static long long getter_ll(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    return [[self objectForKey:attr.name] longLongValue];
}

static void setter_ll(id self, SEL _cmd, long long value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    [self setObject:@(value) forKey:attr.name];
}

static long long getter_llAtomic(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        return [[self objectForKey:attr.name] longLongValue];
    }
}

static void setter_llAtomic(id self, SEL _cmd, long long value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        [self setObject:@(value) forKey:attr.name];
    }
}

static unsigned long getter_ul(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    return [[self objectForKey:attr.name] unsignedLongValue];
}

static void setter_ul(id self, SEL _cmd, unsigned long value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    [self setObject:@(value) forKey:attr.name];
}

static unsigned long getter_ulAtomic(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        return [[self objectForKey:attr.name] unsignedLongValue];
    }
}

static void setter_ulAtomic(id self, SEL _cmd, unsigned long value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        [self setObject:@(value) forKey:attr.name];
    }
}

static unsigned long long getter_ull(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    return [[self objectForKey:attr.name] unsignedLongLongValue];
}

static void setter_ull(id self, SEL _cmd, unsigned long long value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    [self setObject:@(value) forKey:attr.name];
}

static unsigned long long getter_ullAtomic(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        return [[self objectForKey:attr.name] unsignedLongLongValue];
    }
}

static void setter_ullAtomic(id self, SEL _cmd, unsigned long long value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        [self setObject:@(value) forKey:attr.name];
    }
}
// d
static double getter_d(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    return [[self objectForKey:attr.name] doubleValue];
}

static void setter_d(id self, SEL _cmd, double value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    [self setObject:@(value) forKey:attr.name];
}

static double getter_dAtomic(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        return [[self objectForKey:attr.name] doubleValue];
    }
}

static void setter_dAtomic(id self, SEL _cmd, double value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        [self setObject:@(value) forKey:attr.name];
    }
}

// f
static float getter_f(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    return [[self objectForKey:attr.name] floatValue];
}

static void setter_f(id self, SEL _cmd, float value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    [self setObject:@(value) forKey:attr.name];
}

static float getter_fAtomic(id self, SEL _cmd) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        return [[self objectForKey:attr.name] floatValue];
    }
}

static void setter_fAtomic(id self, SEL _cmd, float value) {
    AVIMPropertyAttribute *attr = attributeFromSelector([self class], _cmd);
    @synchronized(self) {
        [self setObject:@(value) forKey:attr.name];
    }
}

@interface AVIMDynamicObject () {
    NSMutableDictionary *_localData;
}

@end
@implementation AVIMDynamicObject
+(BOOL)synthesizeWithPropertyAttribute:(AVIMPropertyAttribute *)attr class:(Class)class {
    const char type = attr.typeCode;
    IMP getterImp = NULL;
    IMP setterImp = NULL;
    const char *getterCode = NULL;
    const char *setterCode = NULL;
    //Code
    //Meaning
    //c
    //A char
    //i
    //An int
    //s
    //A short
    //l
    //A long
    //l is treated as a 32-bit quantity on 64-bit programs.
    //q
    //A long long
    //C
    //An unsigned char
    //I
    //An unsigned int
    //S
    //An unsigned short
    //L
    //An unsigned long
    //Q
    //An unsigned long long
    //f
    //A float
    //d
    //A double
    //B
    //A C++ bool or a C99 _Bool
    //v
    //A void
    //*
    //A character string (char *)
    //@
    //An object (whether statically typed or typed id)
    //#
    //A class object (Class)
    //:
    //A method selector (SEL)
    //[array type]
    //An array
    //{name=type...}
    //A structure
    //(name=type...)
    //A union
    //bnum
    //A bit field of num bits
    //^type
    //A pointer to type
    //?
    //An unknown type (among other things, this code is used for function pointers)
    switch (type) {
        case '@':
            if (attr.isNonatomic) {
                getterImp = (IMP)getter;
                setterImp = (IMP)setter;
                getterCode = "@@:";
                setterCode = "v@:@";
            } else {
                getterImp = (IMP)getterAtomic;
                setterImp = (IMP)setterAtomic;
                getterCode = "@@:";
                setterCode = "v@:@";
            }
            break;
        case 'B':
            if (attr.isNonatomic) {
                getterImp = (IMP)getter_b;
                setterImp = (IMP)setter_b;
                getterCode = "B@:";
                setterCode = "v@:B";
            } else {
                getterImp = (IMP)getter_bAtomic;
                setterImp = (IMP)setter_bAtomic;
                getterCode = "B@:";
                setterCode = "v@:B";
            }
            break;
        case 'c':
            if (attr.isNonatomic) {
                getterImp = (IMP)getter_c;
                setterImp = (IMP)setter_c;
                getterCode = "c@:";
                setterCode = "v@:c";
            } else {
                getterImp = (IMP)getter_cAtomic;
                setterImp = (IMP)setter_cAtomic;
                getterCode = "c@:";
                setterCode = "v@:c";
            }
            break;
            
        case 'i':
        case 's':
        case 'l':
            if (attr.isNonatomic) {
                getterImp = (IMP)getter_l;
                setterImp = (IMP)setter_l;
                getterCode = "l@:";
                setterCode = "v@:l";
            } else {
                getterImp = (IMP)getter_lAtomic;
                setterImp = (IMP)setter_lAtomic;
                getterCode = "l@:";
                setterCode = "v@:l";
            }
            break;
        case 'q':
            if (attr.isNonatomic) {
                getterImp = (IMP)getter_ll;
                setterImp = (IMP)setter_ll;
                getterCode = "q@:";
                setterCode = "v@:q";
            } else {
                getterImp = (IMP)getter_llAtomic;
                setterImp = (IMP)setter_llAtomic;
                getterCode = "q@:";
                setterCode = "v@:q";
            }
            break;
        case 'd':
            if (attr.isNonatomic) {
                getterImp = (IMP)getter_d;
                setterImp = (IMP)setter_d;
                getterCode = "d@:";
                setterCode = "v@:d";
            } else {
                getterImp = (IMP)getter_dAtomic;
                setterImp = (IMP)setter_dAtomic;
                getterCode = "d@:";
                setterCode = "v@:d";
            }
            break;
        case 'f':
            if (attr.isNonatomic) {
                getterImp = (IMP)getter_f;
                setterImp = (IMP)setter_f;
                getterCode = "f@:";
                setterCode = "v@:f";
            } else {
                getterImp = (IMP)getter_fAtomic;
                setterImp = (IMP)setter_fAtomic;
                getterCode = "f@:";
                setterCode = "v@:f";
            }
            break;
        case 'Q':
            if (attr.isNonatomic) {
                getterImp = (IMP)getter_ull;
                setterImp = (IMP)setter_ull;
                getterCode = "Q@:";
                setterCode = "v@:Q";
            } else {
                getterImp = (IMP)getter_ullAtomic;
                setterImp = (IMP)setter_ullAtomic;
                getterCode = "Q@:";
                setterCode = "v@:Q";
            }
            break;
            
        case 'C':
        case 'I':
        case 'S':
        case 'L':
            if (attr.isNonatomic) {
                getterImp = (IMP)getter_ul;
                setterImp = (IMP)setter_ul;
                getterCode = "L@:";
                setterCode = "v@:L";
            } else {
                getterImp = (IMP)getter_ulAtomic;
                setterImp = (IMP)setter_ulAtomic;
                getterCode = "L@:";
                setterCode = "v@:L";
            }
            break;
        default:
            return NO;
    }
    NSMutableDictionary *methodMap = objc_getAssociatedObject(class, methodMapKey);
    [methodMap setObject:attr forKey:attr.getter];
    if (!attr.isReadonly) {
        [methodMap setObject:attr forKey:attr.setter];
    }
    class_addMethod(class, NSSelectorFromString(attr.getter),
                    getterImp, getterCode);
    if (!attr.isReadonly) {
        class_addMethod(class, NSSelectorFromString(attr.setter),
                        setterImp, setterCode);
    }
    return YES;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel class:(Class)class {
    if (class == [AVIMDynamicObject class] || !class) {
        return NO;
    }
    BOOL result = NO;
    NSString *selName = NSStringFromSelector(sel);
    Class objectClass = class;
    NSNumber *resolved = objc_getAssociatedObject(objectClass, methodResolvedKey);
    if (![resolved boolValue]) {
        objc_setAssociatedObject(objectClass, methodResolvedKey, @(YES), OBJC_ASSOCIATION_RETAIN);
        NSDictionary *methodMap = objc_getAssociatedObject(class, methodMapKey);
        if (!methodMap) {
            objc_setAssociatedObject(class, methodMapKey, [[NSMutableDictionary alloc] init], OBJC_ASSOCIATION_RETAIN);
        } else {
            AVLoggerD(@"methodMap:%@", methodMap);
        }
        
        unsigned int numOfProperties;
        objc_property_t *properties = class_copyPropertyList(objectClass, &numOfProperties);
        for (int i = 0; i < numOfProperties; ++i) {
            objc_property_t property = properties[i];
            AVIMPropertyAttribute *attr = [[AVIMPropertyAttribute alloc] initWithProperty:property];
            if (attr.isDynamic) {
                BOOL r = [self synthesizeWithPropertyAttribute:attr class:objectClass];
                if ([selName isEqualToString:attr.getter] || [selName isEqualToString:attr.setter]) {
                    result = r;
                }
            } else {
                AVLoggerD(@"!!! Property %@ not dynamic for class %@.", attr.name, NSStringFromClass(class));
            }
        }
        free(properties);
        
    }
    if (result) {
        return result;
    } else {
        return [self resolveInstanceMethod:sel class:class_getSuperclass(objectClass)];
    }
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    BOOL result = NO;
    NSString *selName = NSStringFromSelector(sel);
    Class objectClass = [self class];
    NSNumber *resolved = objc_getAssociatedObject(objectClass, methodResolvedKey);
    if (![resolved boolValue]) {
        objc_setAssociatedObject(objectClass, methodResolvedKey, @(YES), OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(objectClass, methodMapKey, [[NSMutableDictionary alloc] init], OBJC_ASSOCIATION_RETAIN);
        
        unsigned int numOfProperties;
        objc_property_t *properties = class_copyPropertyList(objectClass, &numOfProperties);
        for (int i = 0; i < numOfProperties; ++i) {
            objc_property_t property = properties[i];
            AVIMPropertyAttribute *attr = [[AVIMPropertyAttribute alloc] initWithProperty:property];
            if (attr.isDynamic) {
                BOOL r = [self synthesizeWithPropertyAttribute:attr class:objectClass];
                if ([selName isEqualToString:attr.getter] || [selName isEqualToString:attr.setter]) {
                    result = r;
                }
            } else {
                AVLoggerD(@"!!! Property %@ not dynamic for class %@.", attr.name, NSStringFromClass([self class]));
            }
        }
        free(properties);
    }
    if (result) {
        return result;
    } else {
        result = [self resolveInstanceMethod:sel class:class_getSuperclass(objectClass)];
        if (result) {
            return result;
        } else {
            return [super resolveInstanceMethod:sel];
        }
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        _localData = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if ((self = [self init])) {
        [_localData addEntriesFromDictionary:dictionary];
    }
    return self;
}

- (instancetype)initWithMutableDictionary:(NSMutableDictionary *)dictionary {
    if ((self = [super init])) {
        _localData = dictionary;
    }
    return self;
}

- (instancetype)initWithJSON:(NSString *)json {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    if (!dict) {
        return nil;
    } else {
        return [self initWithDictionary:dict];
    }
}

- (instancetype)initWithMessagePack:(NSData *)data {
    NSDictionary *dict = [AVMPMessagePackReader readData:data options:0 error:nil];
    if (!dict) {
        return nil;
    } else {
        return [self initWithDictionary:dict];
    }
}

- (BOOL)hasKey:(NSString *)key {
    id object = [_localData objectForKey:key];
    if (object) {
        return YES;
    } else {
        return NO;
    }
}

- (id)objectForKey:(NSString *)key {
    return [_localData objectForKey:key];
}

- (void)setObject:(id)object forKey:(NSString *)key {
    //    [self willChangeValueForKey:key];
    if (object) {
        [_localData setObject:object forKey:key];
    } else {
        [self removeObjectForKey:key];
    }
    //    [self didChangeValueForKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    [_localData removeObjectForKey:key];
}

- (NSDictionary *)rawDictionary {
    NSMutableSet *visitedObjects = [[NSMutableSet alloc] init];
    return [self _rawDictionaryWithVisitedObjects:visitedObjects];
}

- (NSDictionary *)_rawDictionaryWithVisitedObjects:(NSMutableSet *)visitedObjects {
    if (![visitedObjects containsObject:self]) {
        [visitedObjects addObject:self];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        for (NSString *key in [_localData allKeys]) {
            id object = [_localData objectForKey:key];
            if ([object isKindOfClass:[AVIMDynamicObject class]]) {
                NSDictionary *childDict = [object _rawDictionaryWithVisitedObjects:visitedObjects];
                if (childDict) {
                    [dict setObject:childDict forKey:key];
                }
            } else {
                [dict setObject:object forKey:key];
            }
        }
        return dict;
    } else {
        return nil;
    }
    
}
- (NSString *)JSONString {
    @try {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:[self rawDictionary] options:0 error:&error];
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

- (NSDictionary *)dictionary {
    return [self rawDictionary];
}

- (NSData *)messagePack {
    NSDictionary *dict = [self rawDictionary];
    return [AVMPMessagePackWriter writeObject:dict options:0 error:nil];
}
@end
