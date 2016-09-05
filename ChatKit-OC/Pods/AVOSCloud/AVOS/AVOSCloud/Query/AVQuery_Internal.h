//
//  AVQuery_Internal.h
//  Paas
//
//  Created by Zhu Zeng on 3/28/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@interface AVQuery ()
@property (nonatomic, readwrite, strong) NSMutableDictionary *parameters;
@property (nonatomic, readwrite, strong) NSMutableDictionary *where;
@property (nonatomic, readwrite, strong) NSMutableSet * selectedKeys;
@property (nonatomic, strong) NSMutableDictionary *extraParameters;

- (NSDictionary *)assembleParameters;
+ (NSDictionary *)dictionaryFromIncludeKeys:(NSArray *)array;
- (NSString *)queryPath;
-(void)queryWithBlock:(NSString *)path
           parameters:(NSDictionary *)parameters
                block:(AVArrayResultBlock)resultBlock;
- (AVObject *)getFirstObjectWithBlock:(AVObjectResultBlock)resultBlock
                        waitUntilDone:(BOOL)wait
                                error:(NSError **)theError;

/**
 *  Convert server response json to AVObjects. Indend to be overridden.
 *  @param results "results" value of the server response.
 *  @param className The class name for parsing. If nil, the query's className will be used.
 *  @return AVObject array.
 */
- (NSMutableArray *)processResults:(NSArray *)results className:(NSString *)className;

/**
 *  Process end value of server response. Used in AVStatusQuery.
 *  @param end end value
 */
- (void)processEnd:(BOOL)end;

@end
