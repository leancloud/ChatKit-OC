//
//  AVFriendQuery.m
//  paas
//
//  Created by Travis on 14-1-26.
//  Copyright (c) 2014年 AVOS. All rights reserved.
//

#import "AVFriendQuery.h"
#import "AVQuery_Internal.h"
#import "AVObjectUtils.h"
#import "AVErrorUtils.h"
#import "AVQuery_Internal.h"

@implementation AVFriendQuery

//-(void)queryWithBlock:(NSString *)path
//           parameters:(NSDictionary *)parameters
//                block:(AVArrayResultBlock)resultBlock {
//    _end = NO;
//    [super queryWithBlock:path parameters:parameters block:resultBlock];
//}
//
//- (AVObject *)getFirstObjectWithBlock:(AVObjectResultBlock)resultBlock
//                        waitUntilDone:(BOOL)wait
//                                error:(NSError **)theError {
//    _end = NO;
//    return [super getFirstObjectWithBlock:resultBlock waitUntilDone:wait error:theError];
//}
// only called in findobjects, these object's data is ready
- (NSMutableArray *)processResults:(NSArray *)results className:(NSString *)className
{
    NSMutableArray * users = [NSMutableArray array];
    
    for (NSDictionary *dict in [results copy]) {
        id target = dict[self.targetFeild];
        if (target && [target isKindOfClass:[NSDictionary class]]) {
            AVObject *obj= [AVObjectUtils avobjectFromDictionary:target];
            [users addObject:obj];
        }
    }
    
    return (id)users;
}

//- (void)processEnd:(BOOL)end {
//    _end = end;
//}
@end
