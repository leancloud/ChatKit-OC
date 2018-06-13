//
//  LCChatKit_Internal.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/3/9.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKSingleton.h"

NSMutableDictionary const *_sharedInstances = nil;

@implementation LCCKSingleton

#pragma mark -

+ (void)initialize {
	if (_sharedInstances == nil) {
		_sharedInstances = [NSMutableDictionary dictionary];
	}
}

+ (id)allocWithZone:(NSZone *)zone {
	// Not allow allocating memory in a different zone
	return [self sharedInstance];
}

+ (id)copyWithZone:(NSZone *)zone {
	// Not allow copying to a different zone
	return [self sharedInstance];
}

#pragma mark -

+ (instancetype)sharedInstance {
	id sharedInstance = nil;
	@synchronized(self) {
		NSString *instanceClass = NSStringFromClass(self);
		
		// Looking for existing instance
		sharedInstance = [_sharedInstances objectForKey:instanceClass];
		
		// If there's no instance – create one and add it to the dictionary
		if (sharedInstance == nil) {
			sharedInstance = [[super allocWithZone:nil] init];
			[_sharedInstances setObject:sharedInstance forKey:instanceClass];
		}
	}
	
	return sharedInstance;
}

+ (instancetype)instance {
	return [self sharedInstance];
}

#pragma mark -

+ (void)destroyInstance {
	[_sharedInstances removeObjectForKey:NSStringFromClass(self)];
}

+ (void)destroyAllInstance {
    [_sharedInstances removeAllObjects];
}

#pragma mark -

- (id)init {
	self = [super init];
	
	if (self && !self.isInitialized) {
		// Thread-safe because it called from +sharedInstance
		_isInitialized = YES;
	}
	
	return self;
}

@end
