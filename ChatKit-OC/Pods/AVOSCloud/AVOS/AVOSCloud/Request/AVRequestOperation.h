//
//  AVRequestOperation.h
//  AVOSCloud
//
//  Created by Zhu Zeng on 7/9/13.
//  Copyright (c) 2013 AVOS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVConstants.h"

@interface AVRequestOperation : NSObject

@property (nonatomic, readwrite, strong) NSMutableArray * batchRequest;
@property (nonatomic, readwrite, copy) AVBooleanResultBlock block;
@property (nonatomic, readwrite) int sequence;

+(AVRequestOperation *)operation:(NSArray *)request;

@end


@interface AVRequestOperationQueue : NSObject

@property (nonatomic, readwrite) NSMutableArray * queue;
@property (nonatomic, readwrite) int currentSequence;

-(void)increaseSequence;
-(AVRequestOperation *)addOperation:(NSArray *)request
                   withBlock:(AVBooleanResultBlock)block;
-(AVRequestOperation *)popHead;
-(BOOL)noPendingRequest;
-(void)clearOperationWithSequence:(int)seq;

@end
