// COSObserver.m
//
// Copyright (c) 2014 Tianyong Tang
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
// KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
// AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#import "LCObserver.h"
#import <objc/runtime.h>


@interface LCObserver ()

@property (atomic, weak) NSObject *object;

- (instancetype)initWithObject:(NSObject *)object;

@end


@interface LCObservation : NSObject

@property (atomic, unsafe_unretained) id object;
@property (atomic, unsafe_unretained) id target;
@property (atomic, copy) NSString *keyPath;
@property (atomic, assign) NSKeyValueObservingOptions options;
@property (atomic, copy) LCObserverBlock block;

- (void)deregister;

@end


static SEL deallocSel = NULL;
static NSMutableSet *swizzledClasses = nil;
static void *cos_context = &cos_context;

NS_INLINE
NSMutableSet *cos_observation_pool(NSObject *object) {
    static const void *poolKey = &poolKey;

    NSMutableSet *observationPool = objc_getAssociatedObject(object, poolKey);

    if (!observationPool) {
        observationPool = [[NSMutableSet alloc] init];

        objc_setAssociatedObject(object, poolKey, observationPool, OBJC_ASSOCIATION_RETAIN);
    }

    return observationPool;
}

NS_INLINE
void cos_hook_object_if_needed(NSObject *object) {
    @synchronized (swizzledClasses) {
        Class class = [object class];

        if ([swizzledClasses containsObject:class]) return;

        IMP oldDeallocImp = class_getMethodImplementation(class, deallocSel);
        IMP newDeallocImp = imp_implementationWithBlock(^(void *object) {
            for (LCObservation *observation in [cos_observation_pool((__bridge id)object) copy]) {
                [observation deregister];
            }

            ((void(*)(void *, SEL))oldDeallocImp)(object, deallocSel);
        });

        class_replaceMethod(class, deallocSel, newDeallocImp, "v@:");

        [swizzledClasses addObject:class];
    }
}


@implementation LCObserver

+ (void)initialize {
    deallocSel = sel_registerName("dealloc");
    swizzledClasses = [[NSMutableSet alloc] init];
}

+ (instancetype)observerForObject:(NSObject *)object {
    LCObserver *observer = nil;

    if (object) {
        static const void *observerKey = &observerKey;

        observer = objc_getAssociatedObject(object, observerKey);

        if (!observer) {
            observer = [[LCObserver alloc] initWithObject:object];

            objc_setAssociatedObject(object, observerKey, observer, OBJC_ASSOCIATION_RETAIN);
        }
    }

    return observer;
}

- (instancetype)initWithObject:(NSObject *)object {
    self = [super init];

    if (self) _object = object;

    return self;
}

- (void)addTarget:(NSObject *)target
       forKeyPath:(NSString *)keyPath
          options:(NSKeyValueObservingOptions)options
            block:(LCObserverBlock)block {
    if (target) {
        NSObject *object = self.object;

        cos_hook_object_if_needed(object);
        cos_hook_object_if_needed(target);

        LCObservation *observation = [[LCObservation alloc] init];

        observation.object = object;
        observation.target = target;
        observation.keyPath = keyPath;
        observation.options = options;
        observation.block = block;

        [cos_observation_pool(object) addObject:observation];
        [cos_observation_pool(target) addObject:observation];

        if ([target isKindOfClass:[NSArray class]]) {
            NSArray *array = (NSArray *)target;

            [array addObserver:observation
            toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [array count])]
                    forKeyPath:keyPath
                       options:options
                       context:cos_context];
        } else {
            [target addObserver:observation
                     forKeyPath:keyPath
                        options:options
                        context:cos_context];
        }
    }
}

- (void)removeTarget:(NSObject *)target forKeyPath:(NSString *)keyPath {
    if (target && keyPath) {
        NSMutableSet *find = [[NSMutableSet alloc] init];

        for (LCObservation *observation in cos_observation_pool(self.object)) {
            if (observation.target == target && [observation.keyPath isEqualToString:keyPath]) {
                [find addObject:observation];
            }
        }

        for (LCObservation *observation in find) {
            [observation deregister];
        }
    } else if (target) {
        [self removeTarget:target];
    } else {
        [self removeTarget:nil];
    }
}

- (void)removeTarget:(NSObject *)target {
    NSMutableSet *find = nil;
    NSMutableSet *observationPool = cos_observation_pool(self.object);

    if (target) {
        find = [[NSMutableSet alloc] init];

        for (LCObservation *observation in observationPool) {
            if (observation.target == target) {
                [find addObject:observation];
            }
        }
    } else {
        find = [observationPool copy];
    }

    for (LCObservation *observation in find) {
        [observation deregister];
    }
}

@end


@implementation LCObservation

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == cos_context) {
        if (self.block) {
            self.block(self.object, self.target, change);
        }
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void)deregister {
    if ([_target isKindOfClass:[NSArray class]]) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_target count])];

        [_target removeObserver:self fromObjectsAtIndexes:indexSet forKeyPath:_keyPath context:cos_context];
    } else {
        [_target removeObserver:self forKeyPath:_keyPath context:cos_context];
    }

    [cos_observation_pool(_target) removeObject:self], _target = nil;
    [cos_observation_pool(_object) removeObject:self];
}

@end
