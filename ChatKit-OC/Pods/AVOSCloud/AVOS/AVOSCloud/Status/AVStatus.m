//
//  AVStatus.m
//  paas
//
//  Created by Travis on 13-12-23.
//  Copyright (c) 2013年 AVOS. All rights reserved.
//

#import "AVStatus.h"
#import "AVPaasClient.h"
#import "AVErrorUtils.h"
#import "AVObjectUtils.h"
#import "AVObject_Internal.h"
#import "AVQuery_Internal.h"
#import "SDMacros.h"
#import "AVUtils.h"


NSString * const kAVStatusTypeTimeline=@"default";
NSString * const kAVStatusTypePrivateMessage=@"private";

@interface AVStatus () {
    
}
@property(nonatomic,strong) NSString *objectId;
@property(nonatomic,strong) NSDate *createdAt;
@property(nonatomic,assign) NSUInteger messageId;

/* 用Query来设定受众群 */
@property(nonatomic,strong) AVQuery *targetQuery;

+(NSString*)parseClassName;

+(AVStatus*)statusFromCloudData:(NSDictionary*)data;

@end

@implementation AVQuery (Status)

-(NSDictionary*)dictionaryForStatusRequest{
    NSMutableDictionary *dict=[[self assembleParameters] mutableCopy];
    [dict setObject:self.className forKey:@"className"];
    
    //`where` here is a string, but the server ask for dictionary
    [dict removeObjectForKey:@"where"];
    [dict setObject:[AVObjectUtils dictionaryFromDictionary:self.where] forKey:@"where"];
    return dict;
}
@end


@interface AVStatusQuery ()
@property(nonatomic,copy) NSString *externalQueryPath;
@end

@implementation AVStatusQuery

- (id)init
{
    self = [super initWithClassName:[AVStatus parseClassName]];
    if (self) {
        
    }
    return self;
}

- (NSString *)queryPath {
    return self.externalQueryPath?self.externalQueryPath:[super queryPath];
}


- (NSMutableDictionary *)assembleParameters {
    BOOL handleInboxType=NO;
    if (self.inboxType) {
        if (self.externalQueryPath) {
            handleInboxType=YES;
        } else {
            [self whereKey:@"inboxType" equalTo:self.inboxType];
        }
        
    }
    [super assembleParameters];
    
    if (self.sinceId > 0)
    {
        [self.parameters setObject:@(self.sinceId) forKey:@"sinceId"];
    }
    if (self.maxId > 0)
    {
        [self.parameters setObject:@(self.maxId) forKey:@"maxId"];
    }
    
    if (self.owner) {
        [self.parameters setObject:[AVObjectUtils dictionaryFromAVObjectPointer:self.owner] forKey:@"owner"];
    }
    
    if (handleInboxType) {
        [self.parameters setObject:self.inboxType forKey:@"inboxType"];
    }
    
    return self.parameters;
}

-(void)queryWithBlock:(NSString *)path
           parameters:(NSDictionary *)parameters
                block:(AVArrayResultBlock)resultBlock {
    _end = NO;
    [super queryWithBlock:path parameters:parameters block:resultBlock];
}

- (AVObject *)getFirstObjectWithBlock:(AVObjectResultBlock)resultBlock
                        waitUntilDone:(BOOL)wait
                                error:(NSError **)theError {
    _end = NO;
    return [super getFirstObjectWithBlock:resultBlock waitUntilDone:wait error:theError];
}

// only called in findobjects, these object's data is ready
- (NSMutableArray *)processResults:(NSArray *)results className:(NSString *)className
{
    
    NSMutableArray *statuses=[NSMutableArray arrayWithCapacity:[results count]];
    
    for (NSDictionary *info in results) {
        [statuses addObject:[AVStatus statusFromCloudData:info]];
    }
    [statuses sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"messageId" ascending:NO]]];
    return statuses;
}

- (void)processEnd:(BOOL)end {
    _end = end;
}
@end



@implementation AVStatus

+(NSString*)parseClassName{
    return @"_Status";
}

+ (NSString *)statusInboxPath {
    return @"subscribe/statuses/inbox";
}

+(AVStatus*)statusFromCloudData:(NSDictionary*)data{
    if ([data isKindOfClass:[NSDictionary class]] && data[@"objectId"]) {
        AVStatus *status=[[AVStatus alloc] init];
        
        status.objectId=data[@"objectId"];
        status.type=data[@"inboxType"];
        status.createdAt=[AVObjectUtils dateFromString:data[@"createdAt"]];
        status.messageId=[data[@"messageId"] integerValue];
        status.source=[AVObjectUtils avobjectFromDictionary:data[@"source"]];
        
        NSMutableDictionary *newData=[data mutableCopy];
        [newData removeObjectsForKeys:@[@"inboxType",@"objectId",@"createdAt",@"updatedAt",@"messageId",@"source"]];
        
        status.data=newData;
        return status;
    }
    
    return nil;
}

+(NSError*)permissionCheck{
    if (![AVUser currentUser].isAuthenticated) {
        NSError *error= [AVErrorUtils errorWithCode:kAVErrorUserCannotBeAlteredWithoutSession];
        return error;
    }
    
    return nil;
}

+(NSString*)stringOfStatusOwner:(NSString*)userObjectId{
    if (userObjectId) {
        NSString *info=[NSString stringWithFormat:@"{\"__type\":\"Pointer\", \"className\":\"_User\", \"objectId\":\"%@\"}",userObjectId];
        return info;
    }
    return nil;
}


#pragma mark - 查询


+(AVStatusQuery*)inboxQuery:(AVStatusType *)inboxType{
    AVStatusQuery *query=[[AVStatusQuery alloc] init];
    query.owner=[AVUser currentUser];
    query.inboxType=inboxType;
    query.externalQueryPath= @"subscribe/statuses";
    return query;
}


+(AVStatusQuery*)statusQuery{
    AVStatusQuery *q=[[AVStatusQuery alloc] init];
    [q whereKey:@"source" equalTo:[AVUser currentUser]];
    return q;
}

+(void)getStatusesWithType:(AVStatusType*)type skip:(NSUInteger)skip limit:(NSUInteger)limit andCallback:(AVArrayResultBlock)callback{
    NSParameterAssert(type);
    
    NSError *error=[self permissionCheck];
    if (error) {
        callback(nil,error);
        return;
    }
    
    if (limit>100 || limit<=0) {
        limit=100;
    }
    
    AVStatusQuery *q=[AVStatus inboxQuery:type];
    q.limit=limit;
    q.skip=skip;
    [q findObjectsInBackgroundWithBlock:callback];
    
}
+(void) getStatusesFromCurrentUserWithType:(AVStatusType*)type skip:(NSUInteger)skip limit:(NSUInteger)limit andCallback:(AVArrayResultBlock)callback{
    
    NSError *error=[self permissionCheck];
    if (error) {
        callback(nil,error);
        return;
    }
    
    [self getStatusesFromUser:[AVUser currentUser].objectId skip:skip limit:limit andCallback:callback];
    
}
+(void)getStatusesFromUser:(NSString *)userId skip:(NSUInteger)skip limit:(NSUInteger)limit andCallback:(AVArrayResultBlock)callback{
    NSParameterAssert(userId);
    
    AVQuery *q=[AVStatus statusQuery];
    q.limit=limit;
    q.skip=skip;
    [q whereKey:@"source" equalTo:[AVObject objectWithoutDataWithClassName:@"_User" objectId:userId]];
    [q findObjectsInBackgroundWithBlock:callback];
}



+(void)getStatusWithID:(NSString *)objectId andCallback:(AVStatusResultBlock)callback{
    NSError *error=[self permissionCheck];
    if (error) {
        callback(nil,error);
        return;
    }
    
    NSString *owner=[AVStatus stringOfStatusOwner:[AVUser currentUser].objectId];
    [[AVPaasClient sharedInstance] getObject:[NSString stringWithFormat:@"statuses/%@",objectId] withParameters:@{@"owner":owner,@"include":@"source"} block:^(id object, NSError *error) {
        
        if (error) {
            error=[AVErrorUtils errorFromAVError:error];
        } else {
            object=[self statusFromCloudData:object];
        }
        
        [AVUtils callIdResultBlock:callback object:object error:error];
    }];
}

+(void)deleteStatusWithID:(NSString *)objectId andCallback:(AVBooleanResultBlock)callback{
    NSError *error=[self permissionCheck];
    if (error) {
        callback(NO,error);
        return;
    }
    
    NSString *owner=[AVStatus stringOfStatusOwner:[AVUser currentUser].objectId];
    [[AVPaasClient sharedInstance] deleteObject:[NSString stringWithFormat:@"statuses/%@",objectId] withParameters:@{@"owner":owner} block:^(id object, NSError *error) {
        
        if (error) {
            error=[AVErrorUtils errorFromAVError:error];
        }
        [AVUtils callBooleanResultBlock:callback error:error];
    }];
}

+ (BOOL)deleteInboxStatusForMessageId:(NSUInteger)messageId inboxType:(NSString *)inboxType receiver:(NSString *)receiver error:(NSError *__autoreleasing *)error {
    if (!receiver) {
        if (error) *error = [AVErrorUtils errorWithCode:AVLocalErrorCodeInvalidArgument errorText:@"Receiver of status can not be nil."];
        return NO;
    }

    if (!inboxType) {
        if (error) *error = [AVErrorUtils errorWithCode:AVLocalErrorCodeInvalidArgument errorText:@"Inbox type of status can not be nil."];
        return NO;
    }

    NSDictionary *parameters = @{
        @"messageId" : [NSString stringWithFormat:@"%lu", (unsigned long)messageId],
        @"owner"     : [AVObjectUtils dictionaryFromAVObjectPointer:[AVUser objectWithoutDataWithObjectId:receiver]],
        @"inboxType" : inboxType
    };

    __block NSError *responseError = nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    [[AVPaasClient sharedInstance] deleteObject:[self statusInboxPath] withParameters:parameters block:^(id object, NSError *error) {
        responseError = error;
        dispatch_semaphore_signal(sema);
    }];

    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    if (error) {
        *error = responseError;
    }

    return responseError == nil;
}

+ (void)deleteInboxStatusInBackgroundForMessageId:(NSUInteger)messageId inboxType:(NSString *)inboxType receiver:(NSString *)receiver block:(AVBooleanResultBlock)block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        [self deleteInboxStatusForMessageId:messageId inboxType:inboxType receiver:receiver error:&error];
        [AVUtils callBooleanResultBlock:block error:error];
    });
}

+(void)getUnreadStatusesCountWithType:(AVStatusType*)type andCallback:(AVIntegerResultBlock)callback{
    NSError *error=[self permissionCheck];
    if (error) {
        callback(0,error);
        return;
    }
    
    NSString *owner=[AVStatus stringOfStatusOwner:[AVUser currentUser].objectId];
    
    [[AVPaasClient sharedInstance] getObject:@"subscribe/statuses/count" withParameters:@{@"owner":owner,@"inboxType":type} block:^(id object, NSError *error) {
        NSUInteger count=[object[@"unread"] integerValue];
        if (error) {
            error=[AVErrorUtils errorFromAVError:error];
        }
        [AVUtils callIntegerResultBlock:callback number:count error:error];
    }];
}

+(void)sendStatusToFollowers:(AVStatus*)status andCallback:(AVBooleanResultBlock)callback{
    NSError *error=[self permissionCheck];
    if (error) {
        callback(NO,error);
        return;
    }
    status.source=[AVUser currentUser];
    status.targetQuery=[AVUser followerQuery:[AVUser currentUser].objectId];
    [status sendInBackgroundWithBlock:callback];
}

+(void)sendPrivateStatus:(AVStatus *)status toUserWithID:(NSString *)userId andCallback:(AVBooleanResultBlock)callback{
    NSError *error=[self permissionCheck];
    if (error) {
        callback(NO,error);
        return;
    }
    status.source=[AVUser currentUser];
    [status setType:kAVStatusTypePrivateMessage];
    
    AVQuery *q=[AVUser query];
    [q whereKey:@"objectId" equalTo:userId];
    
    status.targetQuery=q;
    [status sendInBackgroundWithBlock:callback];
}

-(void)setQuery:(AVQuery*)query{
    self.targetQuery=query;
}

-(NSError *)preSave
{
    NSParameterAssert(self.data);
    
    if ([self objectId]) {
        return [AVErrorUtils errorWithCode:kAVErrorOperationForbidden errorText:@"status can't be update"];
    }
    
    if ([AVUser currentUser]==nil) {
        return [AVErrorUtils errorWithCode:kAVErrorOperationForbidden errorText:@"do NOT have an current user, please login first"];
    }
    
    if (self.source==nil) {
        self.source=[AVUser currentUser];
    }
    
    if (self.targetQuery==nil) {
        self.targetQuery=[AVUser followerQuery:[AVUser currentUser].objectId];
    }
    
    if (self.type==nil) {
        [self setType:kAVStatusTypeTimeline];
    }

    return nil;
}

-(void)sendInBackgroundWithBlock:(AVBooleanResultBlock)block{
    NSError *error=[self preSave];
    if (error) {
        block(NO,error);
        return;
    }
    
    NSMutableDictionary *body=[NSMutableDictionary dictionary];
    
    NSMutableDictionary *data=[self.data mutableCopy];
    [data setObject:self.source forKey:@"source"];
    
    [body setObject:[AVObjectUtils dictionaryFromDictionary:data] forKey:@"data"];
    
    
    NSDictionary *queryInfo=[self.targetQuery dictionaryForStatusRequest];
    
    [body setObject:queryInfo forKey:@"query"];
    [body setObject:self.type forKey:@"inboxType"];

    AVPaasClient *client = [AVPaasClient sharedInstance];
    NSURLRequest *request = [client requestWithPath:@"statuses" method:@"POST" headers:nil parameters:body];

    @weakify(self);

    [client
     performRequest:request
     success:^(NSHTTPURLResponse *response, id responseObject) {
         @strongify(self);
         if ([responseObject isKindOfClass:[NSDictionary class]]) {
             NSString *objectId = responseObject[@"objectId"];

             if (objectId) {
                 self.objectId = objectId;
                 self.createdAt = [AVObjectUtils dateFromString:responseObject[@"createdAt"]];

                 [AVUtils callBooleanResultBlock:block error:nil];
                 return;
             }
         }

         [AVUtils callBooleanResultBlock:block error:[AVErrorUtils errorWithCode:kAVErrorInvalidJSON errorText:@"unexpected result return"]];
     }
     failure:^(NSHTTPURLResponse *response, id responseObject, NSError *error) {
         [AVUtils callBooleanResultBlock:block error:[AVErrorUtils errorFromJSON:responseObject] ?: error];
     }];
}

-(NSString*)debugDescription{
    if (self.messageId>0) {
        return [[super debugDescription] stringByAppendingFormat:@" <id: %@,messageId:%lu type: %@, createdAt:%@, source:%@(%@)>: %@",self.objectId,(unsigned long)self.messageId,self.type,self.createdAt,NSStringFromClass([self.source class]), [self.source objectId],[self.data debugDescription]];
    }
    return [[super debugDescription] stringByAppendingFormat:@" <id: %@, type: %@, createdAt:%@, source:%@(%@)>: %@",self.objectId,self.type,self.createdAt,NSStringFromClass([self.source class]), [self.source objectId],[self.data debugDescription]];
}

@end

