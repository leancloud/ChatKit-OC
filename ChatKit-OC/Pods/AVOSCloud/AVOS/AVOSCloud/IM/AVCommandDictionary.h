//
//  AVCommandDictionary.h
//  AVOS
//
//  Created by Qihe Bian on 7/22/14.
//
//

#import <Foundation/Foundation.h>

@interface AVCommandDictionary : NSObject
- (void)setObject:(id)object forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (NSString *)JSONString;
@end
