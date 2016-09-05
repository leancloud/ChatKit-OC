//
//  AVRequestManager.h
//  paas
//
//  Created by Zhu Zeng on 9/10/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AVRequestManager : NSObject

@property (nonatomic, readwrite, strong) NSMutableArray * dictArray;

-(void)setRequestForKey:(NSString *)key
                 object:(id)object;

-(void)unsetRequestForKey:(NSString *)key;

-(void)addObjectRequestForKey:(NSString *)key
                       object:(id)object;

-(void)addUniqueObjectRequestForKey:(NSString *)key
                             object:(id)object;

-(void)removeObjectRequestForKey:(NSString *)key
                          object:(id)object;

-(void)addRelationRequestForKey:(NSString *)key
                         object:(id)object;

-(void)removeRelationRequestForKey:(NSString *)key
                      object:(id)object;

-(void)incRequestForKey:(NSString *)key
            value:(double)value;

-(NSMutableDictionary *)initialSetDict;
-(NSMutableDictionary *)initialSetAndAddRelationDict;
-(NSMutableDictionary *)setDict;
-(NSMutableArray *)jsonForCloud;

-(BOOL)containsRequest;
-(void)clear;


@end
