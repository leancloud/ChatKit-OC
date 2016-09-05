//
//  AVIMConversationQuery.m
//  AVOSCloudIM
//
//  Created by Qihe Bian on 2/3/15.
//  Copyright (c) 2015 LeanCloud Inc. All rights reserved.
//

#import "AVIMConversationQuery.h"
#import "MessagesProtoOrig.pbobjc.h"
#import "AVIMCommandCommon.h"
#import "AVUtils.h"
#import "AVIMConversation.h"
#import "AVIMConversation_Internal.h"
#import "AVIMConversationQuery_Internal.h"
#import "AVIMClient_Internal.h"
#import "AVIMBlockHelper.h"
#import "AVIMErrorUtil.h"
#import "AVObjectUtils.h"
#import "LCIMConversationCache.h"

NSString *const kAVIMKeyName = @"name";
NSString *const kAVIMKeyMember = @"m";
NSString *const kAVIMKeyCreator = @"c";
NSString *const kAVIMKeyConversationId = @"objectId";

@implementation AVIMConversationQuery

+(NSDictionary *)dictionaryFromGeoPoint:(AVGeoPoint *)point
{
    return @{ @"__type": @"GeoPoint", @"latitude": @(point.latitude), @"longitude": @(point.longitude) };
}

+(AVGeoPoint *)geoPointFromDictionary:(NSDictionary *)dict
{
    AVGeoPoint * point = [[AVGeoPoint alloc]init];
    point.latitude = [[dict objectForKey:@"latitude"] doubleValue];
    point.longitude = [[dict objectForKey:@"longitude"] doubleValue];
    return point;
}

+ (instancetype)orQueryWithSubqueries:(NSArray<AVIMConversationQuery *> *)queries {
    AVIMConversationQuery *result = nil;

    if (queries.count > 0) {
        AVIMClient *client = [[queries firstObject] client];
        NSMutableArray *wheres = [[NSMutableArray alloc] initWithCapacity:queries.count];

        for (AVIMConversationQuery *query in queries) {
            NSString *eachClientId = query.client.clientId;

            if (!eachClientId || ![eachClientId isEqualToString:client.clientId]) {
                AVLoggerError(AVLoggerDomainIM, @"Invalid conversation query client id: %@.", eachClientId);
                return nil;
            }

            [wheres addObject:[query where]];
        }

        result = [client conversationQuery];
        result.where[@"$or"] = wheres;
    }

    return result;
}

+ (instancetype)andQueryWithSubqueries:(NSArray<AVIMConversationQuery *> *)queries {
    AVIMConversationQuery *result = nil;

    if (queries.count > 0) {
        AVIMClient *client = [[queries firstObject] client];
        NSMutableArray *wheres = [[NSMutableArray alloc] initWithCapacity:queries.count];

        for (AVIMConversationQuery *query in queries) {
            NSString *eachClientId = query.client.clientId;

            if (!eachClientId || ![eachClientId isEqualToString:client.clientId]) {
                AVLoggerError(AVLoggerDomainIM, @"Invalid conversation query client id: %@.", eachClientId);
                return nil;
            }

            [wheres addObject:[query where]];
        }

        result = [client conversationQuery];

        if (wheres.count > 1) {
            result.where[@"$and"] = wheres;
        } else {
            [result.where addEntriesFromDictionary:[wheres firstObject]];
        }
    }

    return result;
}

- (instancetype)init {
    if ((self = [super init])) {
        _where = [[NSMutableDictionary alloc] init];
        _cachePolicy = (AVIMCachePolicy)kAVCachePolicyCacheElseNetwork;
        _cacheMaxAge = 1 * 60 * 60; // an hour
    }
    return self;
}

- (NSString *)whereString {
    NSDictionary *dic = [AVObjectUtils dictionaryFromDictionary:self.where];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:NULL];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)addWhereItem:(NSDictionary *)dict forKey:(NSString *)key {
    if ([dict objectForKey:@"$eq"]) {
        if ([self.where objectForKey:@"$and"]) {
            NSMutableArray *eqArray = [self.where objectForKey:@"$and"];
            int removeIndex = -1;
            for (NSDictionary *eqDict in eqArray) {
                if ([eqDict objectForKey:key]) {
                    removeIndex = (int)[eqArray indexOfObject:eqDict];
                }
            }
            
            if (removeIndex >= 0) {
                [eqArray removeObjectAtIndex:removeIndex];
            }
            
            [eqArray addObject:@{key:[dict objectForKey:@"$eq"]}];
        } else {
            NSMutableArray *eqArray = [[NSMutableArray alloc] init];
            [eqArray addObject:@{key:[dict objectForKey:@"$eq"]}];
            [self.where setObject:eqArray forKey:@"$and"];
        }
    } else {
        if ([self.where objectForKey:key]) {
            [[self.where objectForKey:key] addEntriesFromDictionary:dict];
        } else {
            NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
            [self.where setObject:mutableDict forKey:key];
        }
    }
}

- (void)whereKeyExists:(NSString *)key
{
    NSDictionary * dict = @{@"$exists": [NSNumber numberWithBool:YES]};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKeyDoesNotExist:(NSString *)key
{
    NSDictionary * dict = @{@"$exists": [NSNumber numberWithBool:NO]};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key equalTo:(id)object
{
        [self addWhereItem:@{@"$eq":object} forKey:key];
}

- (void)whereKey:(NSString *)key sizeEqualTo:(NSUInteger)count
{
    [self addWhereItem:@{@"$size": [NSNumber numberWithUnsignedInteger:count]} forKey:key];
}


- (void)whereKey:(NSString *)key lessThan:(id)object
{
    NSDictionary * dict = @{@"$lt":object};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key lessThanOrEqualTo:(id)object
{
    NSDictionary * dict = @{@"$lte":object};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key greaterThan:(id)object
{
    NSDictionary * dict = @{@"$gt": object};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key greaterThanOrEqualTo:(id)object
{
    NSDictionary * dict = @{@"$gte": object};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key notEqualTo:(id)object
{
    NSDictionary * dict = @{@"$ne": object};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key containedIn:(NSArray *)array
{
    NSDictionary * dict = @{@"$in": array };
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key notContainedIn:(NSArray *)array
{
    NSDictionary * dict = @{@"$nin": array };
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key containsAllObjectsInArray:(NSArray *)array
{
    NSDictionary * dict = @{@"$all": array };
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key nearGeoPoint:(AVGeoPoint *)geopoint
{
    NSDictionary * dict = @{@"$nearSphere" : [[self class] dictionaryFromGeoPoint:geopoint]};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key nearGeoPoint:(AVGeoPoint *)geopoint withinMiles:(double)maxDistance
{
    NSDictionary * dict = @{@"$nearSphere" : [[self class] dictionaryFromGeoPoint:geopoint], @"$maxDistanceInMiles":@(maxDistance)};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key nearGeoPoint:(AVGeoPoint *)geopoint withinKilometers:(double)maxDistance
{
    NSDictionary * dict = @{@"$nearSphere" : [[self class] dictionaryFromGeoPoint:geopoint], @"$maxDistanceInKilometers":@(maxDistance)};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key nearGeoPoint:(AVGeoPoint *)geopoint withinRadians:(double)maxDistance
{
    NSDictionary * dict = @{@"$nearSphere" : [[self class] dictionaryFromGeoPoint:geopoint], @"$maxDistanceInRadians":@(maxDistance)};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key withinGeoBoxFromSouthwest:(AVGeoPoint *)southwest toNortheast:(AVGeoPoint *)northeast
{
    NSDictionary * dict = @{@"$within": @{@"$box" : @[[[self class] dictionaryFromGeoPoint:southwest], [[self class] dictionaryFromGeoPoint:northeast]]}};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key matchesRegex:(NSString *)regex
{
    NSDictionary * dict = @{@"$regex": regex};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key matchesRegex:(NSString *)regex modifiers:(NSString *)modifiers
{
    NSDictionary * dict = @{@"$regex":regex, @"$options":modifiers};
    [self addWhereItem:dict forKey:key];
}

- (void)whereKey:(NSString *)key containsString:(NSString *)substring
{
    [self whereKey:key matchesRegex:[NSString stringWithFormat:@".*%@.*",substring]];
}

- (void)whereKey:(NSString *)key hasPrefix:(NSString *)prefix
{
    [self whereKey:key matchesRegex:[NSString stringWithFormat:@"^%@.*",prefix]];
}

- (void)whereKey:(NSString *)key hasSuffix:(NSString *)suffix
{
    [self whereKey:key matchesRegex:[NSString stringWithFormat:@".*%@$",suffix]];
}

- (void)orderByAscending:(NSString *)key
{
    self.order = [NSString stringWithFormat:@"%@", key];
}

- (void)addAscendingOrder:(NSString *)key
{
    if (self.order.length <= 0)
    {
        [self orderByAscending:key];
        return;
    }
    self.order = [NSString stringWithFormat:@"%@,%@", self.order, key];
}

- (void)orderByDescending:(NSString *)key
{
    self.order = [NSString stringWithFormat:@"-%@", key];
}

- (void)addDescendingOrder:(NSString *)key
{
    if (self.order.length <= 0)
    {
        [self orderByDescending:key];
        return;
    }
    self.order = [NSString stringWithFormat:@"%@,-%@", self.order, key];
}

- (void)orderBySortDescriptor:(NSSortDescriptor *)sortDescriptor
{
    NSString *symbol = sortDescriptor.ascending ? @"" : @"-";
    self.order = [symbol stringByAppendingString:sortDescriptor.key];
}

- (void)orderBySortDescriptors:(NSArray *)sortDescriptors
{
    if (sortDescriptors.count == 0) return;
    
    self.order = @"";
    for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
        NSString *symbol = sortDescriptor.ascending ? @"" : @"-";
        if (self.order.length) {
            self.order = [NSString stringWithFormat:@"%@,%@%@", self.order, symbol, sortDescriptor.key];
        } else {
            self.order=[NSString stringWithFormat:@"%@%@", symbol, sortDescriptor.key];
        }
        
    }
}

- (void)getConversationById:(NSString *)conversationId
                   callback:(AVIMConversationResultBlock)callback {
    [self whereKey:@"objectId" equalTo:conversationId];
    [self findConversationsWithCallback:^(NSArray *objects, NSError *error) {
        if (!error && objects.count > 0) {
            AVIMConversation *conversation = [objects objectAtIndex:0];
            [AVIMBlockHelper callConversationResultBlock:callback conversation:conversation error:nil];
        } else if (error) {
            [AVIMBlockHelper callConversationResultBlock:callback conversation:nil error:error];
        } else if (objects.count == 0) {
            NSError *error = [AVIMErrorUtil errorWithCode:kAVIMErrorConversationNotFound reason:@"Conversation not found."];
            [AVIMBlockHelper callConversationResultBlock:callback conversation:nil error:error];
        }
    }];
}

- (AVIMGenericCommand *)queryCommand {
    AVIMGenericCommand *genericCommand = [[AVIMGenericCommand alloc] init];
    genericCommand.needResponse = YES;
    genericCommand.cmd = AVIMCommandType_Conv;
    genericCommand.peerId = self.client.clientId;
    genericCommand.op = AVIMOpType_Query;
    
    AVIMConvCommand *command = [[AVIMConvCommand alloc] init];
    AVIMJsonObjectMessage *jsonObjectMessage = [[AVIMJsonObjectMessage alloc] init];
    jsonObjectMessage.data_p = [self whereString];
    command.where = jsonObjectMessage;
    command.sort = self.order;

    if (self.skip > 0) {
        command.skip = (uint32_t)self.skip;
    }

    if (self.limit > 0) {
        command.limit = (uint32_t)self.limit;
    } else {
        command.limit = 10;
    }
    [genericCommand avim_addRequiredKeyWithCommand:command];
    return genericCommand;
}

- (void)findConversationsWithCallback:(AVIMArrayResultBlock)callback {
    dispatch_async([AVIMClient imClientQueue], ^{
        AVIMGenericCommand *command = [self queryCommand];
        [command setCallback:^(AVIMGenericCommand *outCommand, AVIMGenericCommand *inCommand, NSError *error) {

            [self processInCommand:inCommand
                        outCommand:outCommand
                          callback:callback
                             error:error];
        }];
        [self processOutCommand:command callback:callback];
    });
}

- (id)JSONValue:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    return result;
}

- (NSArray *)conversationsWithResults:(AVIMJsonObjectMessage *)messages {
    NSArray *results = [self JSONValue:messages.data_p];

    NSMutableArray *conversations = [NSMutableArray arrayWithCapacity:[results count]];

    for (NSDictionary *dict in results) {
        AVIMConversation *conversation = [[AVIMConversation alloc] init];

        NSString *createdAt = dict[@"createdAt"];
        NSString *updatedAt = dict[@"updatedAt"];
        NSDictionary *lastMessageAt = dict[@"lm"];

        conversation.imClient = self.client;
        conversation.conversationId = [dict objectForKey:@"objectId"];
        conversation.name = [dict objectForKey:KEY_NAME];
        conversation.attributes = [dict objectForKey:KEY_ATTR];
        conversation.creator = [dict objectForKey:@"c"];
        if (createdAt) conversation.createAt = [AVObjectUtils dateFromString:createdAt];
        if (updatedAt) conversation.updateAt = [AVObjectUtils dateFromString:updatedAt];
        if (lastMessageAt) conversation.lastMessageAt = [AVObjectUtils dateFromDictionary:lastMessageAt];
        conversation.members = [dict objectForKey:@"m"];
        conversation.muted = [[dict objectForKey:@"muted"] boolValue];
        conversation.transient = [[dict objectForKey:@"tr"] boolValue];

        [conversations addObject:conversation];
    }

    [self.client cacheConversations:conversations];

    return conversations;
}

- (void)bindConversations:(NSArray *)conversations {
    for (AVIMConversation *conversation in conversations) {
        conversation.imClient = self.client;
    }
}

- (LCIMConversationCache *)conversationCache {
    return [[LCIMConversationCache alloc] initWithClientId:self.client.clientId];
}

/*!
 * Get cached conversations for a given command.
 * @param outCommand AVIMConversationOutCommand object.
 * @param callback Result callback block.
 * NOTE: The conversations passed to callback will be nil if cache not found.
 */
- (void)fetchCachedResultsForOutCommand:(AVIMGenericCommand *)outCommand callback:(void(^)(NSArray *conversations))callback {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        LCIMConversationCache *cache = [self conversationCache];
        NSArray *conversations = [cache conversationsForCommand:[outCommand avim_conversationForCache]];
        callback(conversations);
    });
}

- (void)callCallback:(AVIMArrayResultBlock)callback withConversations:(NSArray *)conversations {
    [self bindConversations:conversations];
    [self.client cacheConversationsIfNeeded:conversations];
    [AVIMBlockHelper callArrayResultBlock:callback array:conversations error:nil];
}

- (void)processInCommand:(AVIMGenericCommand *)inCommand
              outCommand:(AVIMGenericCommand *)outCommand
                callback:(AVIMArrayResultBlock)callback
                   error:(NSError *)error
{
    if (!error) {
        AVIMConvCommand *conversationInCommand = inCommand.convMessage;
        AVIMJsonObjectMessage *results = conversationInCommand.results;

        NSArray *conversations = [self conversationsWithResults:results];
        [AVIMBlockHelper callArrayResultBlock:callback array:conversations error:nil];

        if (self.cachePolicy != kAVCachePolicyIgnoreCache) {
            LCIMConversationCache *cache = [self conversationCache];
            [cache cacheConversations:conversations maxAge:self.cacheMaxAge forCommand:[outCommand avim_conversationForCache]];
        }
    } else {
        if (self.cachePolicy == kAVCachePolicyNetworkElseCache) {
            [self fetchCachedResultsForOutCommand:outCommand callback:^(NSArray *conversations) {
                if (conversations) {
                    [self callCallback:callback withConversations:conversations];
                } else {
                    [AVIMBlockHelper callArrayResultBlock:callback array:nil error:error];
                }
            }];
        } else {
            [AVIMBlockHelper callArrayResultBlock:callback array:nil error:error];
        }
    }
}

- (void)processOutCommand:(AVIMGenericCommand *)outCommand callback:(AVIMArrayResultBlock)callback {
    switch (self.cachePolicy) {
    case kAVCachePolicyIgnoreCache: {
        [self.client sendCommand:outCommand];
    }
        break;
    case kAVCachePolicyCacheOnly: {
        [self fetchCachedResultsForOutCommand:outCommand callback:^(NSArray *conversations) {
            [self callCallback:callback withConversations:conversations];
        }];
    }
        break;
    case kAVCachePolicyNetworkOnly: {
        [self.client sendCommand:outCommand];
    }
        break;
    case kAVCachePolicyCacheElseNetwork: {
        [self fetchCachedResultsForOutCommand:outCommand callback:^(NSArray *conversations) {
            if ([conversations count]) {
                [self callCallback:callback withConversations:conversations];
            } else {
                [self.client sendCommand:outCommand];
            }
        }];
    }
        break;
    case kAVCachePolicyNetworkElseCache: {
        [self.client sendCommand:outCommand];
    }
        break;
    case kAVCachePolicyCacheThenNetwork: {
        [self fetchCachedResultsForOutCommand:outCommand callback:^(NSArray *conversations) {
            [self callCallback:callback withConversations:conversations];
            [self.client sendCommand:outCommand];
        }];
    }
        break;
    default:
        break;
    }
}

@end
