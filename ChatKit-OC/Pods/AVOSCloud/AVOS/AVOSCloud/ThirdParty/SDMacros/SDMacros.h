//
//  SDMacros.h
//
//  Created by Brandon Sneed on 7/11/13.
//  Copyright (c) 2013 SetDirection. All rights reserved.
//
//  
//  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
//  Version 2, December 2004 
//  
//  Everyone is permitted to copy and distribute verbatim or modified 
//  copies of this source code, and changing it is allowed as long 
//  as the name is changed. 
//  
//          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
//  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
//  
//  0. You just DO WHAT THE FUCK YOU WANT TO.

/**
 The __deprecated__ macro saves a little bit of typing around marking classes and methods as deprecated.
 It also provides a compile-time warning which can be used to direct developers elsewhere.
 
 Example 1: Methods
 
    @interface SDLocationManager: CLLocationManager <CLLocationManagerDelegate>
    + (SDLocationManager *)instance;
    - (void)startUpdatingLocation __deprecated__("Use the withDelegate versions of this method");
    - (void)stopUpdatingHeading __deprecated__("Use the withDelegate versions of this method");
    @end

 Example 2: Object interface

    __deprecated__("Use CLGeocoder instead.")
    @interface SDGeocoder : NSObject
    - (id)initWithQuery:(NSString *)queryString apiKey:(NSString *)apiKey;
    @end
 
 Example 3: Formal protocol
 
    __deprecated__("Use CLGeocoder instead.")
    @protocol SDGeocoderDelegate
    - (void)geocoder:(SDGeocoder *)geocoder didFailWithError:(NSError *)error;
    - (void)geocoder:(SDGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark;
    @end
 */

#define __deprecated__(s) __attribute__((deprecated(s)))

/**
 @weakify, @unsafeify and @strongify are loosely based on EXTobjc's implementation with some subtle
 differences.  The main change here has been to reduce the amount of macro-foo to something more
 understandable.  The calling pattern has also changed.  EXTobjc's @weakify for example accepts a
 variable argument list, which it will in turn generate weak shadow vars for all the items in the arg
 list.
 
 This version makes the weak designation a little more implicit by only accepting 1 variable per call.
 A second version of this macro (with the same name) allows it to be used outside of the context of a 
 block.  This can be useful when dealing with delegates, datasources, IBOutlets, etc that are marked
 as weak or strong.
 */

/**
 @weakify(existingStrongVar)
 
    Creates a weak shadow variable called _existingStrongVar_weak which can be later made strong again
    with #strongify.
 
    This is typically used to weakly reference variables in a block, but then ensure that
    the variables stay alive during the actual execution of the block (if they were live upon
    entry)
 
    Example:
    
        @weakify(self);
        [object doSomethingInBlock:^{
            @strongify(self);
            [self doSomething];
        }];
 
 @weakify(existingStrongVar, myWeakVar)
 
    Creates a weak shadow variable of existingStrongVar and gives it the name myWeakVar.  This is useful
    outside of blocks where a weak reference might be needed.

 */

#define weakify(...) \
    try {} @finally {} \
    macro_dispatcher(weakify, __VA_ARGS__)(__VA_ARGS__)

/**
 Like #weakify, but uses __unsafe_unretained instead.
 */

#define unsafeify(...) \
    try {} @finally {} \
    macro_dispatcher(unsafeify, __VA_ARGS__)(__VA_ARGS__)

/**
 @strongify(existingWeakVar)

    Redefines existingWeakVar to a strong variable of the same type.  This is typically used to redefine
    a weak self reference inside a block.

    Example:

        @weakify(self);
        [object doSomethingInBlock:^{
            @strongify(self);
            [self doSomething];
        }];

 @strongify(existingWeakVar, myStrongVar)

    Creates a strong shadow variable of existingWeakVar and gives it the name myStrongVar.  This is useful
    outside of blocks where a strong reference might be needed.
 
    Example:
 
        @strongify(self.delegate, myDelegate);
        if (myDelegate && [myDelegate respondsToSelector:@selector(someSelector)])
            [myDelegate someSelector];

 */

#define strongify(...) \
    try {} @finally {} \
    macro_dispatcher(strongify, __VA_ARGS__)(__VA_ARGS__)


/****** It's probably best not to call macros below this line directly. *******/

// Support bits for macro dispatching based on parameter count.

#define va_num_args(...) va_num_args_impl(__VA_ARGS__, 5,4,3,2,1)
#define va_num_args_impl(_1,_2,_3,_4,_5,N,...) N

#define macro_dispatcher(func, ...) macro_dispatcher_(func, va_num_args(__VA_ARGS__))
#define macro_dispatcher_(func, nargs) macro_dispatcher__(func, nargs)
#define macro_dispatcher__(func, nargs) func ## nargs

// Support macros for @strongify.

#define strongify1(v) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    __strong __typeof(v) v = v ## _weak_ \
    _Pragma("clang diagnostic pop")

#define strongify2(v_in, v_out) \
    __strong __typeof(v_in) v_out = v_in \

// Support macros for @weakify.

#define weakify1(v) \
    __weak __typeof(v) v ## _weak_ = v \

#define weakify2(v_in, v_out) \
    __weak __typeof(v_in) v_out = v_in \

// Support macros for @unsafeify.

#define unsafeify1(v) \
    __unsafe_unretained __typeof(v) v ## _weak_ = v \

#define unsafeify2(v_in, v_out) \
    __unsafe_unretained __typeof(v_in) v_out = v_in \
