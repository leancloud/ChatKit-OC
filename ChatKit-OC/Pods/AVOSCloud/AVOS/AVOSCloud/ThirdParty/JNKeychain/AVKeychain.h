//
//  JNKeychain.h
//
//  Created by Jeremias Nunez on 5/10/13.
//  Copyright (c) 2013 Jeremias Nunez. All rights reserved.
//
//  Based on Anomie's great answer - http://stackoverflow.com/a/5251820
//
//  jeremias.np@gmail.com

#import <Foundation/Foundation.h>

@interface AVKeychain : NSObject

/**
  @abstract Saves a given value to the Keychain
  @param value The value to store.
  @param key The key identifying the value you want to save.
  @return YES if saved successfully, NO otherwise.
 */
+ (BOOL)saveValue:(id)value forKey:(NSString*)key;

/**
  @abstract Deletes a given value from the Keychain
  @param key The key identifying the value you want to delete.
  @return YES if deletion was successful, NO if the value was not found or some other error ocurred.
 */
+ (BOOL)deleteValueForKey:(NSString *)key;

/**
  @abstract Loads a given value from the Keychain
  @param key The key identifying the value you want to load.
  @return The value identified by key or nil if it doesn't exist.
 */
+ (id)loadValueForKey:(NSString*)key;

@end
