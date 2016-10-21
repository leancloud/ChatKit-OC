//
//  LCChatKit_Internal.h
//  LeanCloudChatKit-iOS
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/3/9.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSMutableDictionary const *_sharedInstances;

/**
 `LCCKSingleton` is a generic class for Mac OSX and iOS that implements all the required methods to implement a singleton object. It's designed for subclassing.
 
 ### Subclassing Notes
 
 When subclassing `LCCKSingleton` you should think about your subclass as an ordinary class, `LCCKSingleton` makes sure that there is only one instance of your class.
 
 If you want to make your own initializer or override `-init` method your should check whether your singleton has already been initialized with `isInitialized` property to prevent repeated initialization.
*/

@interface LCCKSingleton : NSObject

/// @name Obtaining the Shared Instance

/**
 Returns the shared instance of the receiver class, creating it if necessary.

 You shoudn't override this method in your subclasses.

 @return Shared instance of the receiver class.
*/
+ (instancetype)sharedInstance;

/**
 `sharedInstance` alias.
 
 @return Shared instance of the receiver class.
 */
+ (instancetype)instance;

/// @name Destroy Singleton Instance

/**
 Destroys shared instance of singleton class (if there are no other references to that instance).
 
 @warning *Note:* calling `+sharedInstance` after calling this method will create new singleton instance.
 */
+ (void)destroyInstance;

/// @name Testing Singleton Initialization

+ (void)destroyAllInstance;

/**
 A Boolean value that indicates whether the receiver has been initialized.

 This property is usefull if you make you own initializer or override `-init` method.
 You should check if your singleton object has already been initialized to prevent repeated initialization in your custom initializer.
 
 @warning *Important:* you should check whether your instance already initialized before calling `[super init]`.
 
	- (id)init
	{
        if (!self.isInitialized) {
            self = [super init];
		
            if (self) {
                // Initialize self.
            }
        }
 
		return self;
	}
*/
@property (assign, readonly) BOOL isInitialized;

@end
