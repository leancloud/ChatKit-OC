//
//  AVRequestOperation.m
//  AVOSCloud
//
//  Created by Zhu Zeng on 7/9/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import "AVRequestOperation.h"

@implementation AVRequestOperation

-(id)init
{
    self = [super init];
    _batchRequest = [[NSMutableArray alloc] init];
    return self;
}

+(AVRequestOperation *)operation:(NSArray *)request
{
    AVRequestOperation * operation = [[AVRequestOperation alloc] init];
    [operation.batchRequest addObjectsFromArray:request];
    return operation;
}

@end

@implementation AVRequestOperationQueue

@synthesize queue = _queue;

-(id)init
{
    self = [super init];
    _queue = [[NSMutableArray alloc] init];
    return self;
}

-(void)increaseSequence
{
    self.currentSequence += 2;
}

-(AVRequestOperation *)addOperation:(NSArray *)request
                   withBlock:(AVBooleanResultBlock)block
{
    AVRequestOperation * operation = [AVRequestOperation operation:[request mutableCopy]];
    operation.sequence = self.currentSequence;
    operation.block = block;
    [self.queue addObject:operation];
    [self increaseSequence];
    return operation;
}

-(AVRequestOperation *)popHead
{
    if (self.queue.count > 0) {
        AVRequestOperation * operation = [self.queue objectAtIndex:0];
        [self.queue removeObjectAtIndex:0];
        return operation;
    }
    return nil;
}

-(BOOL)noPendingRequest
{
    return (self.queue.count <= 0);
}

-(void)clearOperationWithSequence:(int)seq
{
    NSMutableArray *discardedItems = [NSMutableArray array];
    for (AVRequestOperation * operation in self.queue) {
        if (operation.sequence == seq)
            [discardedItems addObject:operation];
    }
    
    [self.queue removeObjectsInArray:discardedItems];
}

@end

