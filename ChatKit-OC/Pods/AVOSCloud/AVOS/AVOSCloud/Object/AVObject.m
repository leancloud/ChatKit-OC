// AVObject.h
// Copyright 2011 AVOS Inc. All rights reserved.

#import "AVObject_Internal.h"
#import "AVPaasClient.h"
#import "AVUtils.h"
#import "AVRelation.h"
#import "AVObject_Internal.h"
#import "AVRelation_Internal.h"
#import "AVACL.h"
#import "AVACL_Internal.h"
#import "AVGeoPoint_Internal.h"
#import "AVFile_Internal.h"
#import "AVObjectUtils.h"
#import "AVErrorUtils.h"
#import "AVQuery_Internal.h"

#import "AVObject+Subclass.h"
#import "AVSubclassing.h"
#import "AVSaveOption.h"
#import "AVSaveOption_internal.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <libkern/OSAtomic.h>

#import "AVUser_Internal.h"
#import "SDMacros.h"

#define AV_BATCH_SAVE_SIZE 100
#define AV_BATCH_CONCURRENT_SIZE 20

NSString *const internalIdTag = @"__internalId";

/*!
 A LeanCloud Framework Object that is a local representation of data persisted to the LeanCloud. This is the
 main class that is used to interact with objects in your app.
 */

static BOOL convertingNullToNil = YES;

@interface AVObject ()

+ (NSArray *)invalidKeys;
+ (NSString *)parseClassName;

/**
 * Operation queue for requests of object's CRUD.
 */
@property (nonatomic, readonly, strong) NSRecursiveLock *requestLock;

- (void)iteratePropertiesWithBlock:(void(^)(id object))block withAccessed:(NSMutableSet *)accessed;
- (void)iterateDescendantObjectsWithBlock:(void(^)(id object))block;

@end

NS_INLINE
void iterate_object_with_accessed(id object, void(^block)(id object), NSMutableSet *accessed) {
    if (!object || [accessed containsObject:object]) {
        return;
    }

    [accessed addObject:object];

    if ([object isKindOfClass:[AVObject class]]) {
        [object iteratePropertiesWithBlock:block withAccessed:accessed];
    } else if ([object respondsToSelector:@selector(objectEnumerator)]) {
        for (id value in [[object copy] objectEnumerator]) {
            iterate_object_with_accessed(value, block, accessed);
        }
    }

    if (block) {
        block(object);
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused"

NS_INLINE
BOOL requests_contain_request(NSArray *requests, NSDictionary *request) {
    NSString *internalId = request_internal_id(request);

    for (NSDictionary *request in [requests copy]) {
        if ([internalId isEqualToString:request_internal_id(request)]) {
            return YES;
        }
    }

    return NO;
}

#pragma clang diagnostic pop

@implementation AVObject

@synthesize uuid = _uuid;
@synthesize isPointer = _isPointer;
@synthesize operationQueue = _operationQueue;
@synthesize running = _running;
@synthesize requestLock = _requestLock;

#pragma mark - Utils Methods

- (BOOL)isDirty {
    BOOL isNewborn = ![self hasValidObjectId];
    BOOL isModified = [self.requestManager containsRequest];

    return isNewborn || isModified;
}

- (NSDictionary *)snapshot {
    return [AVObjectUtils objectSnapshot:self recursive:NO];
}

- (NSString *)description {
    NSDictionary *snapshot = [self snapshot];

    return [NSString stringWithFormat:@"<%@, %@, %@, %@>",
            NSStringFromClass([self class]),
            self.className,
            self.objectId,
            snapshot];
}

#pragma mark - Accessor
- (NSString *)uuid {
    if (_uuid == nil) {
        _uuid = [AVUtils generateCompactUUID];
    }
    return _uuid;
}

- (NSRecursiveLock *)requestLock {
    if (_requestLock)
        return _requestLock;

    @synchronized(self) {
        if (!_requestLock) {
            _requestLock = [[NSRecursiveLock alloc] init];
        }
    }

    return _requestLock;
}

#pragma mark - API

+ (instancetype)objectWithObjectId:(NSString *)objectId {
    AVObject *object = [[[self class] alloc] init];
    object.objectId = objectId;
    return object;
}

+ (instancetype)objectWithoutDataWithObjectId:(NSString *)objectId {
    return [self objectWithObjectId:objectId];
}

+ (instancetype)objectWithClassName:(NSString *)className
{
    AVObject *object = [[self alloc] initWithClassName:className];
    return object;
}

+ (instancetype)objectWithClassName:(NSString *)className objectId:(NSString *)objectId {
    AVObject *object = [self objectWithClassName:className];
    object.objectId = objectId;
    return object;
}

+ (instancetype)objectWithoutDataWithClassName:(NSString *)className objectId:(NSString *)objectId {
    return [self objectWithClassName:className objectId:objectId];
}

+ (instancetype)objectWithClassName:(NSString *)className dictionary:(NSDictionary *)dictionary
{
    AVObject * object = [self objectWithClassName:className];
    for (NSString *key in [dictionary allKeys]) {
        id value = [dictionary objectForKey:key];
        [object setObject:value forKey:key];
    }
    return object;
}

+ (NSString *)parseClassName {
    return NSStringFromClass([self class]);
}

+ (void)setConvertingNullToNil:(BOOL)yesOrNo {
    convertingNullToNil = yesOrNo;
}

+ (NSArray *)invalidKeys {
    static NSArray *_invalidKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _invalidKeys = @[@"code",
                         @"uuid",
                         @"className",
                         @"keyValues",
                         @"fetchWhenSave",
                         @"running",
                         @"acl",
                         @"ACL",
                         @"pendingKeys",
                         @"createdAt",
                         @"updatedAt",
                         @"objectId"];
    });
    return _invalidKeys;
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        _className = [[self class] parseClassName];
        _localData = [[NSMutableDictionary alloc] init];
        _estimatedData = [[NSMutableDictionary alloc] init];
        _relationData = [[NSMutableDictionary alloc] init];
        _operationQueue = [[AVRequestOperationQueue alloc] init];
        _requestManager = [[AVRequestManager alloc] init];
        _submit = YES;
    }
    return self;
}

- (instancetype)initWithClassName:(NSString *)newClassName
{
    self = [self init];
    if (self)
    {
        self.className = newClassName;
    }
    return self;
}

-(NSArray *)allArray
{
    NSArray * array = @[self.localData, self.estimatedData, self.relationData];
    return array;
}

- (NSArray *)allKeys
{
    NSMutableArray * result = [[NSMutableArray alloc] init];
    for (NSMutableDictionary * dict in [self allArray])
    {
        [result addObjectsFromArray:[dict allKeys]];
    }
    return [result copy];
}

-(id)valueForUndefinedKey:(NSString *)key {
    // search in local data and estimated data
    id object = nil;
    for (NSMutableDictionary * dict in @[self.localData, self.estimatedData])
    {
        object = [dict objectForKey:key];
        if (object) {
            return object;
        }
    }
    
    // dynamic property
    if ([self.relationData objectForKey:key] != nil) {
        object = [self relationForKey:key];
        return object;
    }
    
    // check if it's dynamic relation
    if ([AVUtils isDynamicProperty:key inClass:[self class] withType:[AVRelation class] containSuper:YES]) {
        // need to create relation for the key
        return [self relationForKey:key];
    }
    
    return nil;
}

- (id)objectForKey:(NSString *)key
{
    if (key == nil) {
        return nil;
    }
    id value;
    if ([AVUtils containsProperty:key inClass:[self class] containSuper:YES filterDynamic:YES]) {
        value = [self valueForKey:key];
    } else {
        value = [self valueForUndefinedKey:key];
    }
    if (convertingNullToNil && value == [NSNull null]) {
        return nil;
    } else {
        return value;
    }
}

- (void)updateValue:(id)value forKey:(NSString *)key {
    if ([AVUtils containsProperty:key inClass:[self class] containSuper:YES filterDynamic:YES]) {
        self.inSetter = YES;
        [self setValue:value forKey:key];
        self.inSetter = NO;
    } else {
        if (value) {
            [self.localData setObject:value forKey:key];
        } else {
            [self.localData removeObjectForKey:key];
        }
    }
}

- (void)setObject:(id)object
           forKey:(NSString *)key
           submit:(BOOL)s
{
    if (object == nil) {
        if (s) {
            // When manaully set it nil, we remove it.
            [self removeObjectForKey:key];
        }
        return;
    }
    
    // Special case when object is [NSNull null], we also set it like NSDictionary did.
    
    self.submit = s;
    [self updateValue:object forKey:key];
    if (s) {
        [self addSetRequest:key object:object];
    }
    self.submit = YES;
}

- (void)setObject:(id)object forKey:(NSString *)key
{
    if ([[[self class] invalidKeys] containsObject:key]) {
        NSError *error = [NSError errorWithDomain:kAVErrorDomain code:0 userInfo:@{@"text":[NSString stringWithFormat:@"Don't use an internal key name:%@", key]}];
        AVLoggerE(@"fail to set object for key, error: %@", error);
        NSException *exception = [NSException exceptionWithName:kAVErrorDomain reason:[NSString stringWithFormat:@"Invalid key name:%@", key] userInfo:nil];
        [exception raise];
        return;
    }
    
    if (self.inSetter) {
        return;
    }
    [self setObject:object forKey:key submit:YES];
}

- (void)removeObjectForKey:(NSString *)key
{
    BOOL hasKey = NO;
    for (NSMutableDictionary *dic in [self allArray]) {
        if ([dic objectForKey:key]) {
            hasKey = YES;
        }
        [dic removeObjectForKey:key];
    }
    if ([AVUtils containsProperty:key inClass:[self class] containSuper:YES filterDynamic:YES]) {
        /* Create a clean object to produce an empty value. */
        [self setValue:[[[self class] alloc] valueForKey:key] forKey:key];
        hasKey = YES;
    }
    if (hasKey || [self hasValidObjectId]) {
        [self.requestManager unsetRequestForKey:key];
    }
}

- (id)objectForKeyedSubscript:(NSString *)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)object forKeyedSubscript:(NSString *)key
{
    return [self setObject:object forKey:key];
}

-(void)addRelation:(AVObject *)object
            forKey:(NSString *)key
            submit:(BOOL)submit
{
    NSMutableArray * array = [self findArrayForKey:key inDictionary:self.relationData create:YES];
    if (![array containsObject:object])
    {
        [array addObject:object];
    }
    if (submit)
    {
        [self.requestManager addRelationRequestForKey:key object:object];
    }
}

-(void)removeRelation:(AVObject *)object
               forKey:(NSString *)key
{
    NSMutableArray * array = [self findArrayForKey:key  inDictionary:self.relationData create:NO];
    if ([array containsObject:object])
    {
        [array removeObject:object];
    }
    [self.requestManager removeRelationRequestForKey:key object:object];
}

-(NSString *)internalClassName
{
    return self.className;
}

- (AVRelation *)relationforKey:(NSString *)key {
    return [self relationForKey:key];
}

- (AVRelation *)relationForKey:(NSString *)key {
    NSArray * array = [self.relationData objectForKey:key];
    AVObject *target = nil;
    if (array.count > 0)
    {
        target = [array objectAtIndex:0];
    }
    AVRelation *relation = [[AVRelation alloc] init];
    relation.parent = self;
    relation.key = key;
    relation.targetClass = target.className;
    return relation;
}

- (NSString *)childClassNameForRelation:(NSString *)key {
    NSArray * array = [self.relationData objectForKey:key];
    AVObject *target = nil;
    if (array.count > 0)
    {
        target = [array objectAtIndex:0];
    }
    return target.className;
}

-(NSMutableArray *)findArrayForKey:(NSString *)key
                      inDictionary:(NSMutableDictionary *)dict
                            create:(BOOL)create
{
    NSMutableArray * array = [dict objectForKey:key];

    if (array) {
        if (![array isKindOfClass:[NSArray class]]) {
            NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException reason:@"Value referenced by key is not an array." userInfo:nil];
            [exception raise];
        }
        if (![array isKindOfClass:[NSMutableArray class]]) {
            array = [array mutableCopy];
            [dict setObject:array forKey:key];
        }
    } else if (create) {
        array = [[NSMutableArray alloc] init];
        [dict setObject:array forKey:key];
    }

    return array;
}

-(NSMutableArray *)createArrayForKey:(NSString *)key {
    id object = [self.localData objectForKey:key];
    NSMutableArray * array = [NSMutableArray array];
    [self.localData setObject:array forKey:key];
    if (object == nil) {
        return array;
    }
    if ([object isKindOfClass:[NSArray class]]) {
        [array addObjectsFromArray:object];
    } else {
        [array addObject:object];
    }
    return array;
}

- (BOOL)addObject:(id)object
           forKey:(NSString *)key
           unique:(BOOL)unique
{
    if ([AVUtils containsProperty:key inClass:[self class] containSuper:YES filterDynamic:YES]) {
        id v = [self valueForKey:key];
        if (!v) {
            v = [[NSArray alloc] init];
        }
        if ([v isKindOfClass:[NSArray class]]) {
            if (unique && [v containsObject:object]) {
                return NO;
            }
            NSMutableArray *array = [v mutableCopy];
            [array addObject:object];
            self.inSetter = YES;
            [self setValue:array forKey:key];
            self.inSetter = NO;
            if (unique) {
                [self.requestManager addUniqueObjectRequestForKey:key object:object];
            } else {
                [self.requestManager setRequestForKey:key object:array];
            }
            return YES;
        } else {
            return NO;
        }
    }
    NSMutableArray *array = [self findArrayForKey:key inDictionary:self.localData create:YES];
    if (unique && [array containsObject:object])
    {
        return NO;
    }
    
    // update local data, we always create new array and copy existing data
    // to the new array.
    array = [self createArrayForKey:key];
    [array addObject:object];
    if (unique) {
        [self.requestManager addUniqueObjectRequestForKey:key object:object];
    } else {
        [self.requestManager addObjectRequestForKey:key object:object];
    }
    return YES;
}

- (void)addObject:(id)object forKey:(NSString *)key
{
    [self addObject:object forKey:key unique:NO];
}

- (void)addObjectsFromArray:(NSArray *)objects forKey:(NSString *)key
{
    for(NSObject * object in [objects copy])
    {
        [self addObject:object forKey:key unique:NO];
    }
}

- (void)addUniqueObject:(id)object forKey:(NSString *)key
{
    [self addObject:object forKey:key unique:YES];
}

- (void)addUniqueObjectsFromArray:(NSArray *)objects forKey:(NSString *)key
{
    for(NSObject * object in [objects copy])
    {
        [self addObject:object forKey:key unique:YES];
    }
}

- (void)removeObject:(id)object forKey:(NSString *)key
{
    NSMutableArray * array = [self findArrayForKey:key inDictionary:self.localData create:NO];
    if (!array) {
        if ([AVUtils containsProperty:key inClass:[self class] containSuper:YES filterDynamic:YES]) {
            array = [self valueForKey:key];
            if (array) {
                if (![array isKindOfClass:[NSMutableArray class]]) {
                    array = [array mutableCopy];
                    [self setValue:array forKey:key];
                }
            } else {
                array = [[NSMutableArray alloc] init];
                [self setValue:array forKey:key];
            }
        }
    }
    if (![array containsObject:object] && !self.hasValidObjectId)
    {
        return;
    }
    [array removeObject:object];
    [self.requestManager removeObjectRequestForKey:key object:object];

    /* Update value again for compatibility with Swift.
     * Or array value will not be updated after element removed via this method.
     */
    [self updateValue:array forKey:key];
}

- (void)removeObjectsInArray:(NSArray *)objects forKey:(NSString *)key
{
    for(NSObject * object in [objects copy])
    {
        [self removeObject:object forKey:key];
    }
}

-(BOOL)moveToEstimated:(NSString *)key
{
    NSNumber * localNumber = [self.localData valueForKey:key];
    NSNumber * estimatedNumber = [self.estimatedData valueForKey:key];
    if (localNumber)
    {
        [self.estimatedData setValue:localNumber forKey:key];
        [self.localData removeObjectForKey:key];
        return YES;
    }
    if (estimatedNumber)
    {
        return YES;
    }
    return NO;
}

- (void)incrementKey:(NSString *)key
{
    [self incrementKey:key byAmount:@(1)];
}

- (void)incrementKey:(NSString *)key byAmount:(NSNumber *)amount
{
    [self moveToEstimated:key];
    NSNumber * number = [self.estimatedData valueForKey:key];
    double value = [number doubleValue];
    value += [amount doubleValue];
    [self.estimatedData setValue:@(value) forKey:key];
    
    if ([self hasValidObjectId]) {
        [self.requestManager incRequestForKey:key value:[amount doubleValue]];
    } else {
        [self.requestManager setRequestForKey:key object:@(value)];
    }
}

-(void)setACL:(AVACL *)ACL {
    _ACL = ACL;
    [self addSetRequest:ACLTag object:ACL.permissionsById];
}

-(void)addSetRequest:(NSString *)key
              object:(NSObject *)object
{
    if (self.submit) {
        [self.requestManager setRequestForKey:key object:object];
    }
}

#pragma mark - Save

- (BOOL)save
{
    return [self save:NULL];
}

- (BOOL)save:(NSError *__autoreleasing *)error
{
    return [self saveWithOption:nil error:error];
}

- (BOOL)saveWithOption:(AVSaveOption *)option
                 error:(NSError *__autoreleasing *)error
{
    return [self saveWithOption:option eventually:NO error:error];
}

- (BOOL)saveWithOption:(AVSaveOption *)option
            eventually:(BOOL)eventually
                 error:(NSError *__autoreleasing *)error
{
    return [self saveWithOption:option eventually:eventually verifyBefore:YES error:error];
}

- (BOOL)saveWithOption:(AVSaveOption *)option
            eventually:(BOOL)eventually
          verifyBefore:(BOOL)verifyBefore
                 error:(NSError *__autoreleasing *)error
{
    /* Make validation before save. */
    if (verifyBefore) {
        NSError *preError = [self preSave];

        if (preError) {
            if (error)
                *error = preError;
            return NO;
        }
    }

    /* Synthesize request options. */
    if (!option) {
        option = [[AVSaveOption alloc] init];
    }

    NSError *optionError = [self validateSaveOption:option];

    if (optionError) {
        if (error)
            *error = optionError;
        return NO;
    }

    NSError *requestError = nil;

    [self.requestLock lock];

    /* Perform save request. */
    do {
        /* If object is clean, ignore save request. */
        if (![self isDirty]) {
            AVLoggerInfo(AVLoggerDomainStorage, @"Object not changed, ignore save request.");
            break;
        }

        /* Firstly, save all related files. */
        NSError *fileError = [self saveNewFiles];

        if (fileError) {
            requestError = fileError;
            break;
        }

        /* Send object batch save request. */
        NSMutableArray *requests = [self buildSaveRequests];

        /* Apply option to requests. */
        [self applySaveOption:option toRequests:requests];

        if (requests.count > 0) {
            [self sendBatchRequest:requests
                        eventually:eventually
                             error:&requestError];
        }
    } while (NO);

    if (error) {
        *error = requestError;
    }

    [self.requestLock unlock];

    return !requestError;
}

- (NSError *)validateSaveOption:(AVSaveOption *)option {
    NSError *error = nil;

    AVQuery *query = option.query;
    NSString *queryClassName = query.className;

    if (queryClassName && ![queryClassName isEqualToString:self.className]) {
        error = [AVErrorUtils errorWithCode:kAVErrorInvalidClassName errorText:@"Invalid query class name."];
    }

    return error;
}

- (void)applySaveOption:(AVSaveOption *)option toRequests:(NSMutableArray *)requests {
    NSDictionary *params = [option dictionary];

    if (!params.count)
        return;

    @weakify(self);
    [requests enumerateObjectsWithOptions:NSEnumerationReverse
                               usingBlock:^(NSMutableDictionary * _Nonnull request, NSUInteger idx, BOOL * _Nonnull stop)
    {
        @strongify(self);

        if ([request_method(request) isEqualToString:@"PUT"] &&
            [request_internal_id(request) isEqualToString:self.objectId]) {
            request[@"params"] = params;
            *stop = YES;
        }
    }];
}

- (void)postProcessBatchRequests:(NSMutableArray *)requests {
    /* Add parameter 'new' to newborn objects. */
    for (NSMutableDictionary *request in [requests copy]) {
        if ([request_method(request) isEqualToString:@"POST"] && !request_object_id(request)) {
            request[@"new"] = @(YES);
        }
    }
}

- (void)saveInBackground
{
    [self saveInBackgroundWithBlock:nil];
}

- (void)saveInBackgroundWithBlock:(AVBooleanResultBlock)block
{
    [self saveInBackgroundWithOption:nil block:block];
}

- (void)saveInBackgroundWithOption:(AVSaveOption *)option block:(AVBooleanResultBlock)block {
    [self saveInBackgroundWithOption:option eventually:NO block:block];
}

- (void)saveInBackgroundWithOption:(AVSaveOption *)option eventually:(BOOL)eventually block:(AVBooleanResultBlock)block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        [self saveWithOption:option eventually:eventually error:&error];
        [AVUtils callBooleanResultBlock:block error:error];
    });
}

-(NSError *)preSave
{
    return nil;
}

-(void)postSave
{
    [self.requestManager clear];

    // Reset all descendant objects' requests.
    [self iterateDescendantObjectsWithBlock:^(id object) {
        if ([object isKindOfClass:[AVObject class]]) {
            [[object requestManager] clear];
        }
    }];
}

-(NSMutableDictionary *)initialBodyData {
    return [self.requestManager initialSetDict];
}

-(void)refreshHasDataForInitial {
    NSMutableSet *visitedObjects = [[NSMutableSet alloc] init];
    [self refreshHasDataForInitial:visitedObjects];
}

-(void)refreshHasDataForInitial:(NSMutableSet *)visitedObjects {
    [visitedObjects addObject:self];
    __block BOOL change = NO;
    [self iterateLocalDataWithBlock:^(NSString *key, id object) {
        if ([object isKindOfClass:[AVObject class]]) {
            if (![visitedObjects containsObject:object]) {
                [object refreshHasDataForInitial:visitedObjects];
                if ([object hasDataForInitial]) {
                    change = YES;
                }
            }
        }
    }];
    if (change || !self.hasValidObjectId) {
        self.hasDataForInitial = YES;
    } else {
        self.hasDataForInitial = NO;
    }
}

// add all initial save request. save all children together.
-(void)addInitialSaveRequest:(NSMutableArray *)initialSaveArray {
    [self refreshHasDataForInitial];
    NSMutableSet *visitedObjects = [[NSMutableSet alloc] init];
    [self addInitialSaveRequest:initialSaveArray visitedObjects:visitedObjects];
}

-(void)addInitialSaveRequest:(NSMutableArray *)initialSaveArray visitedObjects:(NSMutableSet *)visitedObjects {
    [visitedObjects addObject:self];
    if (![self hasDataForInitial]) {
        return;
    }
    [self iterateLocalDataWithBlock:^(NSString *key, id object) {
        if ([object isKindOfClass:[AVObject class]]) {
            if (![visitedObjects containsObject:object]) {
                [object addInitialSaveRequest:initialSaveArray visitedObjects:visitedObjects];
            }
        }
    }];

//    if ([self hasDataForCloud]) {
//        return;
//    }
    
    /* make it little bit clear, so don't optimize
     // add the save operation only when there is addRelation/removeRelation ops.
     if (self.requestManager.addRelationObjectDict.count <= 0 &&
     self.requestManager.removeRelationDict.count <= 0) {
     return;
     }
     */
    
    NSString *method = [self initialRequestMethod];
    NSMutableDictionary * body = [self initialBodyData];
    [self addInternalId:body];
    // should use addACLIfExists ?
    [self addDefaultACL:body];
    NSMutableDictionary * item = [AVPaasClient batchMethod:method path:[self initialRequestPath] body:body parameters:[self myParams]];
    [initialSaveArray addObject:item];
}

- (NSString *)initialRequestMethod {
    return [self hasValidObjectId] ? @"PUT" : @"POST";
}

- (NSString *)initialRequestPath {
    return [self myObjectPath];
}

- (NSSet *)allAttachedDirtyFiles {
    NSMutableSet *files = [NSMutableSet set];

    [self iterateDescendantObjectsWithBlock:^(id object) {
        if ([object isKindOfClass:[AVFile class]] && [object isDirty]) {
            [files addObject:object];
        }
    }];

    return files;
}

- (NSError *)saveNewFiles{
    NSError *error = nil;
    NSSet   *files = [self allAttachedDirtyFiles];

    for (AVFile *file in files) {
        if ([file isDirty]) {
            [file save:&error];

            if (error) {
                return error;
            }
        }
    }

    return nil;
}

- (BOOL)shouldIncludeUpdateRequests {
    return YES;
}

- (NSMutableArray *)buildSaveRequests {
    NSMutableArray *requests = [NSMutableArray array];

    do {
        BOOL modified = [self.requestManager containsRequest];

        /* If object saved and not modified, no request. */
        if ([self hasValidObjectId] && !modified)
            break;

        [self addInitialSaveRequest:requests];

        if (![self shouldIncludeUpdateRequests])
            break;

        [self refreshHasDataForCloud];

        /* If object has no update requests and not modified, break. */
        if (!self.hasDataForCloud && !modified)
            break;

        NSArray *updateRequests = [self jsonDataForCloudWithClear:YES];

        [requests addObjectsFromArray:updateRequests];
    } while (0);

    if (requests.count) {
        [self postProcessBatchRequests:requests];
        return requests;
    }

    return nil;
}

-(AVObject *)searchObjectByInternalId:(NSString *)internalId {
    return [self searchObjectByInternalId:internalId visitedObjects:[NSMutableSet set]];
}

-(AVObject *)searchObjectByInternalId:(NSString *)internalId visitedObjects:(NSMutableSet *)visitedObjects {
    [visitedObjects addObject:self];
    if ([internalId isEqualToString:self.uuid]) {
        return self;
    }
    NSDictionary *localData = [self.localData copy];
    for (id key in localData) {
        id object = localData[key];
        if ([object isKindOfClass:[AVObject class]]) {
            if ([visitedObjects containsObject:object]) {
                continue;
            } else {
                AVObject * result = [object searchObjectByInternalId:internalId visitedObjects:visitedObjects];
                if (result) {
                    return result;
                }
            }
        }
    }
    return nil;
}

-(BOOL)sendBatchRequest:(NSArray *)batchRequest
             eventually:(BOOL)isEventually
                  error:(NSError **)theError
{
    batchRequest = [batchRequest copy];

    // change post to put and object path if we got objectId. also change child object id.
    for(NSMutableDictionary * dict in batchRequest) {
        NSDictionary * body = [dict objectForKey:@"body"];
        NSString * internalId = [body objectForKey:internalIdTag];
        AVObject * object = [self searchObjectByInternalId:internalId];
        if ([object hasValidObjectId]) {
            [AVPaasClient updateBatchMethod:@"PUT" path:[object myObjectPath] dict:dict];
        }
    }
    __block BOOL hasCallback = NO;
    __block NSError *blockError;
    [[AVPaasClient sharedInstance] postBatchSaveObject:batchRequest headerMap:[self headerMap] eventually:isEventually block:^(id object, NSError *error) {
        [self copyByUUIDFromDictionary:object];
        if(![error.domain isEqualToString:kAVErrorDomain]) {
            [self postSave];
        }
        if (error) {
            blockError = error;
        }
        hasCallback = YES;
    }];
    AV_WAIT_TIL_TRUE(hasCallback, 0.1);
    if (theError != NULL) {
        *theError = blockError;
    }
    return blockError == nil;
}

- (void)iterateLocalDataWithBlock:(void(^)(NSString *key, id object))block {
    NSDictionary *localData = [self.localData copy];

    for (NSString *key in localData) {
        block(key, localData[key]);
    }
}

// TODO, move to avobjectutils
- (void)copyByUUIDFromDictionary:(NSDictionary *)dic {
    [self copyByUUIDFromDictionary:dic visitedObjects:[NSMutableSet set]];
}

- (void)copyByUUIDFromDictionary:(NSDictionary *)dic visitedObjects:(NSMutableSet *)visitedObjects {
    /**
     Item:
     "c2": {
     {
     52274247e4b00334fc423df7 =     {
     createdAt = "2013-09-04T22:23:03.223Z";
     updatedAt = "2013-09-04T22:23:14.326Z";
     value = 2;
     };
     }
     
     }
     */
    [visitedObjects addObject:self];
    // copy the item to self
    id item = dic[self.uuid];
    if (item && [item isKindOfClass:[NSDictionary class]]) {
        [AVObjectUtils copyDictionary:item toObject:self];
    }
    
    // when put, it may contain value from server side,
    // so update local estimated values too.
    item = dic[self.objectId];
    if (item && [item isKindOfClass:[NSDictionary class]]) {
        [AVObjectUtils copyDictionary:item toObject:self];
    }

    [self iterateLocalDataWithBlock:^(NSString *key, id object) {
        if ([object isKindOfClass:[AVObject class]]) {
            if (![visitedObjects containsObject:object]) {
                [object copyByUUIDFromDictionary:dic visitedObjects:visitedObjects];
            }
        }
    }];
}

-(NSDictionary *)myParams
{
    if (self.fetchWhenSave) {
        return @{@"fetchWhenSave" : @(YES)};
    }
    return nil;
}

- (void)saveInBackgroundWithTarget:(id)target selector:(SEL)selector
{
    @weakify(self);
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        @strongify(self);
        [AVUtils performSelectorIfCould:target selector:selector object:self object:error];
    }];
}

- (void)saveInBackgroundWithOption:(AVSaveOption *)option target:(id)target selector:(SEL)selector {
    @weakify(self);
    [self saveInBackgroundWithOption:option block:^(BOOL succeeded, NSError *error) {
        @strongify(self);
        [AVUtils performSelectorIfCould:target selector:selector object:self object:error];
    }];
}

- (void)saveEventually
{
    [self saveEventually:nil];
}

- (void)saveEventually:(AVBooleanResultBlock)callback
{
    [self saveInBackgroundWithOption:nil eventually:YES block:callback];
}

+ (BOOL)saveAll:(NSArray *)objects
{
    return [[self class] saveAll:objects error:NULL];
}

- (void)iteratePropertiesWithBlock:(void(^)(id object))block withAccessed:(NSMutableSet *)accessed {
    NSSet *propertyNames = [AVObjectUtils allAVObjectProperties:[self class]];

    for (NSString *key in propertyNames) {
        iterate_object_with_accessed([self valueForKey:key], block, accessed);
    }
}

- (void)iterateDescendantObjectsWithBlock:(void(^)(id object))block {
    iterate_object_with_accessed(self, block, [NSMutableSet set]);
}

- (NSArray *)descendantFiles {
    NSMutableSet *files = [NSMutableSet set];

    [self iterateDescendantObjectsWithBlock:^(id object) {
        if ([object isKindOfClass:[AVFile class]] && [object isDirty]) {
            [files addObject:object];
        }
    }];

    return [files allObjects];
}

+ (NSArray *)descendantFilesOfObjects:(NSArray *)objects {
    NSMutableSet *files = [NSMutableSet set];

    for (AVObject *object in [objects copy]) {
        [files addObjectsFromArray:[object descendantFiles]];
    }

    return [files allObjects];
}

+ (NSArray *)reduceObjectsFromArray:(NSMutableArray *)array count:(NSInteger)count {
    NSArray *subArray = nil;

    if ([array count] <= count) {
        subArray = [array copy];
        [array removeAllObjects];
    } else {
        NSRange range = NSMakeRange(0, count);
        subArray = [array subarrayWithRange:range];
        [array removeObjectsInRange:range];
    }

    return subArray;
}

// 和 sendBatchRequest 有啥区别？是否可重用？
+ (BOOL)postBatchRequests:(NSArray *)requests forObjects:(NSArray *)objects error:(NSError **)error {
    __block BOOL finished = NO;
    __block NSError *blockError;
    
    [[AVPaasClient sharedInstance] postBatchSaveObject:requests
                                             headerMap:nil
                                            eventually:NO
                                                 block:^(id result, NSError *anError)
    {
        if (!anError) {
            for (AVObject *object in [objects copy]) {
                [object copyByUUIDFromDictionary:result];
            }
        }
        blockError = anError;
        finished = YES;
    }];
    
    AV_WAIT_TIL_TRUE(finished, 0.1);
    if (blockError && error != NULL) {
        *error = blockError;
    }
    return blockError == nil;
}

+ (BOOL)saveDescendantFileOfObjects:(NSArray *)objects error:(NSError **)error {
    NSMutableArray *files = [[self descendantFilesOfObjects:objects] mutableCopy];

    __block BOOL saveOK = YES;
    __block NSError *blockError;

    while ([files count] && saveOK) {
        __block int32_t uploadCount = 0;
        NSArray *subFiles = [self reduceObjectsFromArray:files count:AV_BATCH_CONCURRENT_SIZE];

        for (AVFile *file in subFiles) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *anError = nil;

                if (![file save:&anError]) {
                    blockError = anError;
                    saveOK = NO;
                }

                OSAtomicIncrement32(&uploadCount);
            });
        }

        AV_WAIT_TIL_TRUE(uploadCount == [subFiles count], 0.1);
    }
    if (blockError && error != NULL) {
        *error = blockError;
    }

    return saveOK;
}

+ (BOOL)saveDescendantRequestsOfObjects:(NSArray *)objects error:(NSError **)error {
    NSMutableArray *requestsArray = [NSMutableArray array];
    NSMutableArray *dirtyObjects = [NSMutableArray array];
    for (AVObject *object in [objects copy]) {
        NSMutableArray *requests = [object buildSaveRequests];
        if (requests.count > 0) {
            [dirtyObjects addObject:object];
            [requestsArray addObject:requests];
        }
    }
    __block BOOL saveOK = YES;

    while ([dirtyObjects count] && saveOK) {
        // requests 在 AV_BATCH_SAVE_SIZE 以内，计算这一批可处理多少个 objects
        NSInteger requestCount = 0;
        NSInteger objectCount = 0;
        for (NSArray *requests in requestsArray) {
            if (requestCount + requests.count > AV_BATCH_SAVE_SIZE) {
                break;
            } else {
                requestCount += requests.count;
                objectCount ++;
            }
        }
        
        NSArray *subObjects = [self reduceObjectsFromArray:dirtyObjects count:objectCount];
        NSArray *subRequestsArray = [self reduceObjectsFromArray:requestsArray count:objectCount];
        // 将二维数组平铺开来
        NSMutableArray *subRequests = [NSMutableArray array];
        for (NSArray *array in subRequestsArray) {
            [subRequests addObjectsFromArray:array];
        }
        NSError *anError;
        if (![self postBatchRequests:subRequests forObjects:subObjects error:&anError]) {
            saveOK = NO;
            *error = anError;
        }
    }
    return saveOK;
}

+ (BOOL)saveAll:(NSArray *)objects error:(NSError **)error
{
    // Upload descendant files of objects
    NSError *fileUploadError = nil;

    if (![self saveDescendantFileOfObjects:objects error:&fileUploadError]) {
        *error = fileUploadError;
        return NO;
    }

    // Post descendant batch requests of objects
    NSError *requestPostError = nil;

    if (![self saveDescendantRequestsOfObjects:objects error:&requestPostError]) {
        *error = requestPostError;
        return NO;
    }

    return YES;
}

+ (void)saveAllInBackground:(NSArray *)objects
{
    [[self class] saveAllInBackground:objects block:NULL];
}

+ (void)saveAllInBackground:(NSArray *)objects
                      block:(AVBooleanResultBlock)block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        [[self class] saveAll:objects error:&error];
        [AVUtils callBooleanResultBlock:block error:error];
    });
}

+ (void)saveAllInBackground:(NSArray *)objects
                     target:(id)target
                   selector:(SEL)selector
{
    [[self class] saveAllInBackground:objects block:^(BOOL succeeded, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:@(succeeded) object:error];
    }];
}

- (BOOL)isDataAvailable
{
    return self.objectId.length > 0 && self.createdAt != nil;
}

#pragma mark - Refresh

- (void)refresh
{
    [self refresh:NULL];
}

- (void)refreshWithKeys:(NSArray *)keys {
    [self refreshWithBlock:NULL keys:keys waitUntilDone:YES error:nil];
}

- (BOOL)refresh:(NSError **)error
{
    return [self refreshWithBlock:NULL keys:nil waitUntilDone:YES error:error];
}

- (void)refreshInBackgroundWithBlock:(AVObjectResultBlock)block {
    [self refreshWithBlock:block keys:nil waitUntilDone:NO error:NULL];
}

- (void)refreshInBackgroundWithKeys:(NSArray *)keys
                              block:(AVObjectResultBlock)block {
    [self refreshWithBlock:block keys:keys waitUntilDone:NO error:NULL];
}

- (BOOL)refreshWithBlock:(AVObjectResultBlock)block
                    keys:(NSArray *)keys
           waitUntilDone:(BOOL)wait
                   error:(NSError **)theError {
    
    BOOL __block hasCalledBack = NO;
    NSError __block *blockError = nil;
    
    NSString *path = [self myObjectPath];
    NSDictionary * parameters = nil;
    if (keys) {
        parameters = [AVQuery dictionaryFromIncludeKeys:keys];
    }
    [[AVPaasClient sharedInstance] getObject:path withParameters:parameters block:^(id object, NSError *error) {
        
        if (error == nil)
        {
            [self removeLocalData];
            [AVObjectUtils copyDictionary:object toObject:self];
        }
        else
        {
            
        }
        if (self == [AVUser currentUser]) {
            [[self class] changeCurrentUser:(AVUser *)self save:YES];
        }
        [AVUtils callObjectResultBlock:block object:self error:error];
        
        if (wait) {
            blockError = error;
            hasCalledBack = YES;
        }
    }];
    
    // wait until called back if necessary
    if (wait) {
        [AVUtils warnMainThreadIfNecessary];
        
        AV_WAIT_TIL_TRUE(hasCalledBack, 0.1);
    };
    
    if (theError != NULL && blockError) {
        *theError = blockError;
        return NO;
    }
    return YES;
}

- (void)refreshInBackgroundWithTarget:(id)target selector:(SEL)selector
{
    NSString * path = [self myObjectPath];
    [[AVPaasClient sharedInstance] getObject:path withParameters:nil block:^(id object, NSError *error) {
        if (error == nil)
        {
            [self removeLocalData];
            [AVObjectUtils copyDictionary:object toObject:self];
        }
        else
        {
            
        }
        if (self == [AVUser currentUser]) {
            [[self class] changeCurrentUser:(AVUser *)self save:YES];
        }
        [AVUtils performSelectorIfCould:target selector:selector object:object object:error];
    }];
}

#pragma mark - Fetch

- (BOOL)fetch
{
    return [self fetch:NULL];
}

- (BOOL)fetch:(NSError **)error
{
    return [self fetchWithKeys:nil error:error];
}

- (void)fetchWithKeys:(NSArray *)keys {
    [self fetchWithKeys:keys error:nil];
}

- (BOOL)fetchWithKeys:(NSArray *)keys
                error:(NSError **)error {
    __block NSError *blockError;
    __block BOOL hasCallback = NO;
    [self internalFetchInBackgroundWithKeys:keys block:^(AVObject *object, NSError *error) {
        blockError = error;
        hasCallback = YES;
    }];
    AV_WAIT_TIL_TRUE(hasCallback, 0.1);
    if (blockError && error != NULL) {
        *error = blockError;
    }
    return blockError == nil;
}

- (AVObject *)fetchIfNeeded
{
    return [self fetchIfNeededWithKeys:nil];
}

- (AVObject *)fetchIfNeeded:(NSError **)error
{
    return [self fetchIfNeededWithKeys:nil error:error];
}

- (AVObject *)fetchIfNeededWithKeys:(NSArray *)keys {
    return [self fetchIfNeededWithKeys:keys error:nil];
}

- (AVObject *)fetchIfNeededWithKeys:(NSArray *)keys
                              error:(NSError **)error {
    if (![self isDataAvailable]) {
        [self fetchWithKeys:keys error:error];
    }
    return self;
}

- (void)fetchInBackgroundWithBlock:(AVObjectResultBlock)resultBlock
{
    [self fetchInBackgroundWithKeys:nil block:resultBlock];
}

- (void)fetchInBackgroundWithKeys:(NSArray *)keys
                            block:(AVObjectResultBlock)block {
    [self internalFetchInBackgroundWithKeys:keys block:^(AVObject *object, NSError *error) {
        [AVUtils callObjectResultBlock:block object:object error:error];
    }];
}

- (void)handleFetchResult:(id)object error:(NSError **)error{
    if ([object allKeys].count <= 0) {
        // 返回 {}
        if (error != NULL) {
            *error = [AVErrorUtils errorWithCode:kAVErrorObjectNotFound errorText:@"not found the object to fetch"];
        }
    } else {
        [self removeLocalData];
        [AVObjectUtils copyDictionary:object toObject:self];
        if (self == [AVUser currentUser]) {
            [[self class] changeCurrentUser:(AVUser *)self save:YES];
        }
    }
}

- (void)internalFetchInBackgroundWithKeys:(NSArray *)keys
                                    block:(AVObjectResultBlock)resultBlock
{
    
    if (![self hasValidObjectId]) {
        NSError *error = [AVErrorUtils errorWithCode:kAVErrorMissingObjectId errorText:@"Missing ObjectId"];
        [AVUtils callObjectResultBlock:resultBlock object:nil error:error];
        return;
    }
    
    NSString *path = [self myObjectPath];
    NSDictionary * parameters = nil;
    if (keys) {
        parameters = [AVQuery dictionaryFromIncludeKeys:keys];
    }
    [[AVPaasClient sharedInstance] getObject:path withParameters:parameters block:^(id object, NSError *error) {
        if (!error) {
            NSError *theError;
            [self handleFetchResult:object error:&theError];
            error = theError;
        }
        if (resultBlock) {
            resultBlock(self, error);
        }
    }];
}

- (void)fetchInBackgroundWithTarget:(id)target selector:(SEL)selector
{
    [self fetchInBackgroundWithBlock:^(AVObject *object, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:object object:error];
    }];
}

- (void)fetchIfNeededInBackgroundWithBlock:(AVObjectResultBlock)block
{
    if (![self isDataAvailable]) {
        [self fetchInBackgroundWithBlock:^(AVObject *object, NSError *error) {
            if (block) block(object, error);
        }];
    } else {
        if (block) block(self, nil);
    }
}

- (void)fetchIfNeededInBackgroundWithTarget:(id)target
                                   selector:(SEL)selector
{
    [self fetchIfNeededInBackgroundWithBlock:^(AVObject *object, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:object object:error];
    }];
}

+ (void)fetchAll:(NSArray *)objects
{
    [[self class] fetchAll:objects error:NULL];
}

+ (BOOL)fetchAll:(NSArray *)objects error:(NSError **)error
{
    return [[self class] fetchAll:objects error:error checkIfNeed:NO];
}

+ (void)fetchAllIfNeeded:(NSArray *)objects
{
    [[self class] fetchAllIfNeeded:objects error:NULL];
}

+ (BOOL)fetchAllIfNeeded:(NSArray *)objects error:(NSError **)error
{
    return [[self class] fetchAll:objects error:error checkIfNeed:YES];
}

+ (BOOL)fetchAll:(NSArray *)objects error:(NSError **)error checkIfNeed:(BOOL)check {
    objects = [objects copy];
    NSError __block *retError;
    if (![self isValidObjects:objects error:&retError]) {
        return NO;
    }
    NSMutableArray *fetches = [NSMutableArray array];
    NSMutableArray *fetchObjects = [NSMutableArray array];
    // Add a task to the group
    for (AVObject *obj in objects) {
        if ([obj isKindOfClass:[AVObject class]]) {
            if (!check || ![obj isDataAvailable]) {
                NSDictionary* fetch = [AVPaasClient batchMethod:@"GET" path:[obj myObjectPath] body:nil parameters:nil];
                [fetches addObject:fetch];
                [fetchObjects addObject:obj];
            }
        }
    }
    if (fetches.count > 0) {
        __block BOOL hasCalledBlcok = NO;
        [[AVPaasClient sharedInstance] postBatchObject:fetches block:^(NSArray *results, NSError *error) {
            if (error) {
                retError = error;
            } else {
                if (results.count == fetches.count) {
                    for (NSInteger i = 0; i < fetches.count; i++) {
                        AVObject *object = fetchObjects[i];
                        id result = results[i];
                        if ([result isKindOfClass:[NSDictionary class]]) {
                            NSError *theError;
                            [object handleFetchResult:result error:&theError];
                            if (theError && retError == nil) {
                                // retError 只需记录第一个错误
                                retError = theError;
                            }
                        } else {
                            if (retError == nil) {
                                retError = result;
                            }
                        }
                    }
                }
            }
            hasCalledBlcok = YES;
        }];
        AV_WAIT_TIL_TRUE(hasCalledBlcok, 0.1);
    }
    if (retError && error) {
        *error=retError;
        return NO;
    }
    return YES;
}

+ (void)fetchAllInBackground:(NSArray *)objects
                       block:(AVArrayResultBlock)block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        [[self class] fetchAll:objects error:&error];
        [AVUtils callArrayResultBlock:block array:objects error:error];
    });
}

+ (void)fetchAllInBackground:(NSArray *)objects
                      target:(id)target
                    selector:(SEL)selector
{
    [[self class] fetchAllInBackground:objects block:^(NSArray *objects, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:objects object:error];
    }];
}

+ (void)fetchAllIfNeededInBackground:(NSArray *)objects
                               block:(AVArrayResultBlock)block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error;
        [[self class] fetchAllIfNeeded:objects error:&error];
        [AVUtils callArrayResultBlock:block array:objects error:error];
    });
}

+ (void)fetchAllIfNeededInBackground:(NSArray *)objects
                              target:(id)target
                            selector:(SEL)selector
{
    [[self class] fetchAllIfNeededInBackground:objects block:^(NSArray *objects, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:objects object:error];
    }];
}

#pragma mark - delete

- (void)postDelete {
    
}

- (BOOL)delete
{
    return [self delete:NULL];
}

- (BOOL)delete:(NSError **)error
{
    __block NSError *blockError;
    __block BOOL hasCallback = NO;
    [self internalDeleteWithEventually:NO block:^(BOOL succeeded, NSError *error) {
        blockError = error;
        hasCallback = YES;
    }];
    AV_WAIT_TIL_TRUE(hasCallback, 0.1);
    if (blockError && error) {
        *error = blockError;
    }
    return blockError == nil;
}

- (void)deleteInBackground
{
    [self deleteInBackgroundWithBlock:NULL];
}

- (void)deleteInBackgroundWithBlock:(AVBooleanResultBlock)block {
    [self internalDeleteWithEventually:NO block:^(BOOL succeeded, NSError *error) {
        [AVUtils callBooleanResultBlock:block error:error];
    }];
}

- (void)internalDeleteWithEventually:(BOOL)eventually block:(AVBooleanResultBlock)block {
    NSError *error;
    if (![[self class] isValidObjects:@[self] error:&error]) {
        [AVUtils callBooleanResultBlock:block error:error];
        return;
    }
    [self.requestManager clear];
    NSString *path = [self myObjectPath];
    [[AVPaasClient sharedInstance] deleteObject:path withParameters:nil block:^(id object, NSError *error) {
        if (!error) {
            [self postDelete];
        }
        if (block) {
            block(error == nil, error);
        }
    }];
}

- (void)deleteInBackgroundWithTarget:(id)target
                            selector:(SEL)selector
{
    [self deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [AVUtils performSelectorIfCould:target selector:selector object:@(succeeded) object:error];
    }];
}

- (void)deleteEventually {
    [self deleteEventuallyWithBlock:nil];
}

- (void)deleteEventuallyWithBlock:(AVIdResultBlock)block {
    [self internalDeleteWithEventually:YES block:^(BOOL succeeded, NSError *error) {
        [AVUtils callIdResultBlock:block object:self error:error];
    }];
}

// check className & objectId
+ (BOOL)isValidObjects:(NSArray *)objects error:(NSError **)error {
    for(AVObject * object in [objects copy]) {
        if (object.className.length <= 0 || ![object hasValidObjectId]) {
            if (error != NULL)
            *error = [AVErrorUtils errorWithCode:kAVErrorMissingObjectId errorText:@"Invaid className or objectId"];
            return NO;
        }
    }
    return YES;
}

+ (BOOL)deleteAll:(NSArray *)objects {
    return [self deleteAll:objects error:nil];
}

+ (BOOL)deleteAll:(NSArray *)objects error:(NSError **)error {
    __block NSError *blockError;
    __block BOOL hasCalledBlock = NO;
    [self internalDeleteAllInBackground:objects block:^(BOOL succeeded, NSError *theError) {
        blockError = theError;
        hasCalledBlock = YES;
    }];
    AV_WAIT_TIL_TRUE(hasCalledBlock, 0.1);
    if (blockError && error) {
        *error = blockError;
    }
    return blockError == nil;
}

+ (void)deleteAllInBackground:(NSArray *)objects
                        block:(AVBooleanResultBlock)block {
    [self internalDeleteAllInBackground:objects block:^(BOOL succeeded, NSError *error) {
        [AVUtils callBooleanResultBlock:block error:error];
    }];
}

+ (void)internalDeleteAllInBackground:(NSArray *)objects
                                block:(AVBooleanResultBlock)block {
    objects = [objects copy];
    if (objects.count == 0) {
        [AVUtils callBooleanResultBlock:block error:nil];
        return;
    }
    NSError *error;
    if (![self isValidObjects:objects error:&error]) {
        [AVUtils callBooleanResultBlock:block error:error];
        return;
    }
    NSMutableArray *deletes = [NSMutableArray array];
    for (AVObject *object in objects) {
        NSMutableDictionary *delete = [AVPaasClient batchMethod:@"DELETE" path:[object myObjectPath] body:nil parameters:nil];
        [deletes addObject:delete];
    }
    [[AVPaasClient sharedInstance] postBatchObject:deletes block:^(NSArray *results, NSError *error) {
        if (!error) {
            for (id result in results) {
                if ([result isKindOfClass:[NSDictionary class]]) {
                    // succeed
                    NSInteger index = [results indexOfObject:result];
                    AVObject *object = objects[index];
                    [object postDelete];
                }
            }
        }
        if (block) {
            block(error == nil, error);
        }
    }];
}

-(void)addAclIfExist:(NSMutableDictionary *)data
{
    if (self.ACL)
    {
        NSDictionary * dict = @{@"ACL":self.ACL.permissionsById};
        [data addEntriesFromDictionary:dict];
    }
}

-(NSMutableDictionary *)postData
{
    return [AVObjectUtils objectSnapshot:self];
}

-(void)addChildrenIfExist:(NSMutableDictionary *)dict {
    NSMutableArray *children = [NSMutableArray array];
    
    // visit all children
    [self iterateLocalDataWithBlock:^(NSString *key, id object) {
        if ([object isKindOfClass:[AVObject class]]) {
            if ([object hasDataForCloud]) {
                NSDictionary * child = [AVObjectUtils childDictionaryFromAVObject:object withKey:key];
                [children addObject:child];
            }
        }
    }];

    if (children.count > 0) {
        [dict setObject:children forKey:@"__children"];
    }
}

-(void)addInternalId:(NSMutableDictionary *)dict {
    [dict setObject:[self hasValidObjectId] ? self.objectId : self.uuid forKey:internalIdTag];
}

-(void)addDefaultACL:(NSMutableDictionary *)dict {
    if (self.ACL == nil) {
        if ([AVPaasClient sharedInstance].updatedDefaultACL) {
            
            // set ACL for this object, see -[AVACLTest testSetDefaultACL_withAccessForCurrentUser]
            self.ACL = [AVPaasClient sharedInstance].updatedDefaultACL;
            [dict setObject:[AVPaasClient sharedInstance].updatedDefaultACL.permissionsById forKey:ACLTag];
        }
    }
}

// create batch request from body
-(NSMutableDictionary *)requestFromBody:(NSMutableDictionary *)body {
//    NSString *method = [self hasValidObjectId] ? @"PUT" : @"POST";
    NSString *method = @"PUT";
    BOOL new = ![self hasValidObjectId];
    if (body == nil) {
        body = [NSMutableDictionary dictionary];
    }
    [self addInternalId:body];
    NSMutableDictionary * item = [AVPaasClient batchMethod:method path:[self myObjectPath] body:body parameters:[self myParams]];
    if (new) {
        [item setObject:[NSNumber numberWithBool:new] forKey:@"new"];
    }
    return item;
}

-(void)refreshHasDataForCloud {
    NSMutableSet *visitedObjects = [[NSMutableSet alloc] init];
    [self refreshHasDataForCloud:visitedObjects];
}

-(void)refreshHasDataForCloud:(NSMutableSet *)visitedObjects {
    [visitedObjects addObject:self];
    __block BOOL change = NO;
    [self iterateLocalDataWithBlock:^(NSString *key, id object) {
        if ([object isKindOfClass:[AVObject class]]) {
            if (![visitedObjects containsObject:object]) {
                [object refreshHasDataForCloud:visitedObjects];
                if ([object hasDataForCloud]) {
                    change = YES;
                }
            }
        }
    }];
    if (change || [self.requestManager containsRequest] || !self.hasValidObjectId) {
        self.hasDataForCloud = YES;
    } else {
        self.hasDataForCloud = NO;
    }
}
// Basic steps
// 1. generate json request from request manager, it generates request from all dirty(changed) fields. In this step, we ignore AVObject set request
// as they will be added later in step3.
// 2. add acl
// 3. add children list(changed) only
// 4. generate intenral id
// 5. add children request into begin of request list
-(NSMutableArray *)dataForCloud {
    //    BOOL hasChild = NO;
    // body array
    [self refreshHasDataForCloud];
    NSMutableSet *visitedObjects = [[NSMutableSet alloc] init];
    return [self dataForCloudWithVisitedObjects:visitedObjects];
}

-(NSMutableArray *)dataForCloudWithVisitedObjects:(NSMutableSet *)visitedObjects {
    [visitedObjects addObject:self];
    //    BOOL hasChild = NO;
    // body array
    NSMutableArray * array = [self.requestManager jsonForCloud];
    NSMutableDictionary * dict = nil;
    if (array.count > 0) {
        dict = [array objectAtIndex:0];
        [self addChildrenIfExist:dict];
    } else {
        dict = [NSMutableDictionary dictionary];
        [self addChildrenIfExist:dict];
        if (dict.count > 0) {
            [array addObject:dict];
        }
    }

    // create request from internal id, method, path and body
    NSMutableArray * json = [NSMutableArray arrayWithCapacity:array.count];
    for(NSMutableDictionary * body in [array copy]) {
        NSDictionary * item = [self requestFromBody:body];
        [json addObject:item];
    }
    
    // for each child call dataForCloud and insert them to the begin of array.
    [self iterateLocalDataWithBlock:^(NSString *key, id object) {
        if ([object isKindOfClass:[AVObject class]]) {
            if (((AVObject *)object).hasDataForCloud && ![visitedObjects containsObject:object]) {
                NSMutableArray * list = [object dataForCloudWithVisitedObjects:visitedObjects];
                if (list) {
                    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, list.count)];
                    [json insertObjects:list atIndexes:indexSet];
                }
            }
        }
    }];
    return json;
}

-(NSMutableArray *)jsonDataForCloudWithClear:(BOOL)clear {
    NSMutableArray * array = [self dataForCloud];
    if (clear) {
        [self.requestManager clear];
    }
    return array;
}

-(NSDictionary *)headerMap {
    return nil;
}

-(NSString *)myObjectPath
{
    return [AVObjectUtils objectPath:self.className objectId:self.objectId];
}

#pragma mark - Private Methods
- (BOOL)moveIfNeedWithKey:(NSString *)key from:(NSMutableDictionary *)from to:(NSMutableDictionary *)to {
    id object = [from objectForKey:key];
    
    if (object) {
        [to setObject:object forKey:key];
        [from removeObjectForKey:key];
        return YES;
    }
    
    return NO;
}

-(BOOL)hasValidObjectId {
    return (self.objectId.length > 0);
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }
    AVObject * otherObject = (AVObject *)other;
    return ([self.objectId isEqualToString:otherObject.objectId] &&
            [self.className isEqualToString:otherObject.className]);
}

#pragma mark - Serialization, Deserialization

-(NSMutableDictionary *)dictionaryForObject {
    return [AVObjectUtils objectSnapshot:self];
}

+ (AVObject *)objectWithDictionary:(NSDictionary *)dictionary {
    return [AVObjectUtils avobjectFromDictionary:dictionary];
}

-(void)objectFromDictionary:(NSDictionary *)dict {
    [AVObjectUtils copyDictionary:dict toObject:self];
}

#pragma mark -

-(void)removeLocalData {
    [self.localData removeAllObjects];
    [self.relationData removeAllObjects];
    [self.estimatedData removeAllObjects];
    [self.requestManager clear];
}

@end


@implementation AVObject (Subclass)

+ (instancetype)object {
    id obj = [[[self class] alloc] init];
    return obj;
}

+ (void)registerSubclass {
    Class objectClass = [self class];
    
    unsigned int numOfProperties, pi;
    objc_property_t *properties = class_copyPropertyList(objectClass, &numOfProperties);
    for (pi = 0; pi < numOfProperties; pi++) {
        objc_property_t property = properties[pi];
        const char* propertyName = property_getName(property);
        const char type = avTypeOfPropertyNamed(objectClass, propertyName)[1];
        //VLog(@"type = %c",type);
        NSString* propertyStr = [NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        Method originalMethod = class_getInstanceMethod(objectClass, NSSelectorFromString(propertyStr));
        if (originalMethod) {
            // 仅仅只替换 dynamic 声明的 property
            continue;
        }

        [[self class] synthesizeWithGetterName:propertyStr
                                          type:type
                                        isCopy:IsPropertyCopy(property)];
        
        //       fprintf(stdout, "%s\n%s\n", property_getName(property), property_getAttributes(property));
        //        VLog(@"%s is %@copy",property_getName(property), IsPropertyCopy(property) ? @"" : @"not ");
    }
    free(properties);
    
    NSString *parseClassName = [self parseClassName];
    
    // + (NSString *)parseClassName must be @"_User"
    
    if ([objectClass isSubclassOfClass:[AVUser class]] && ![parseClassName isEqualToString:[AVUser userTag]]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Cannot initialize a AVUser with a custom class name."];
    }
    
    [[AVPaasClient sharedInstance] addSubclassMapEntry:parseClassName classObject:objectClass];
}

+ (AVQuery *)query {
    return [AVQuery queryWithClassName:[[self class] parseClassName]];
}

#pragma mark - Util
// @selector(setDisplayName:) -> @"displayName"
NSString *KeyFromSetter(SEL selector)
{
    NSString *SELString = NSStringFromSelector(selector);
    NSString *key = [SELString substringWithRange:NSMakeRange(3, SELString.length - 4)];
    key = [NSString stringWithFormat:@"%@%@",
           [[key substringToIndex:1] lowercaseString],
           [key substringFromIndex:1]];
    return key;
}

/**
 R
 The property is read-only (readonly).
 C
 The property is a copy of the value last assigned (copy).
 &
 The property is a reference to the value last assigned (retain).
 N
 The property is non-atomic (nonatomic).
 G<name>
 The property defines a custom getter selector name. The name follows the G (for example, GcustomGetter,).
 S<name>
 The property defines a custom setter selector name. The name follows the S (for example, ScustomSetter:,).
 D
 The property is dynamic (@dynamic).
 W
 The property is a weak reference (__weak).
 P
 The property is eligible for garbage collection.
 t<encoding>
 Specifies the type using old-style encoding.
 */
// support all types not finished
NSDictionary *PropertyTypes(objc_property_t property)
{
    NSMutableDictionary *types = [NSMutableDictionary dictionaryWithCapacity:10];
    return types;
}

BOOL IsPropertyCopy(objc_property_t property)
{
    const char * attrs = property_getAttributes( property );
    NSString *attrsString = [NSString stringWithCString:attrs encoding:NSUTF8StringEncoding];
    
    for (NSString *string in [attrsString componentsSeparatedByString:@","]) {
        if ([string isEqualToString:@"C"]) {
            return YES;
        }
    }
    return NO;
}

// return               T@"NSString"     Ti     Tc
const char * avPropertyGetTypeString( objc_property_t property )
{
    const char * attrs = property_getAttributes( property );
    if ( attrs == NULL )
        return ( NULL );
    
    static char buffer[256];
    const char * e = strchr( attrs, ',' );
    if ( e == NULL )
        return ( NULL );
    
    int len = (int)(e - attrs);
    memcpy( buffer, attrs, len );
    buffer[len] = '\0';
    
    return ( buffer );
}

const char *avTypeOfPropertyNamed(Class objectClass,const char *name)
{
    objc_property_t property = class_getProperty(objectClass, name);
    if ( property == NULL )
        return ( NULL );
    
    return ( avPropertyGetTypeString(property) );
}

#pragma mark - Runtime
// @
static id getter(id self, SEL _cmd)
{
    return [self objectForKey:NSStringFromSelector(_cmd)];
}

static void setter(id self, SEL _cmd, id value)
{
    [self setObject:value forKey:KeyFromSetter(_cmd)];
}

static void setterWithCopy(id self, SEL _cmd, id value)
{
    [self setObject:[value copy] forKey:KeyFromSetter(_cmd)];
}

// Bool
static BOOL getter_b(id self, SEL _cmd)
{
    return [[self objectForKey:NSStringFromSelector(_cmd)] boolValue];
}

static void setter_b(id self, SEL _cmd, BOOL value)
{
    [self setObject:@(value) forKey:KeyFromSetter(_cmd)];
}

// l, i, c,....
static long getter_l(id self, SEL _cmd)
{
    return [[self objectForKey:NSStringFromSelector(_cmd)] longValue];
}

static void setter_l(id self, SEL _cmd, long value)
{
    [self setObject:@(value) forKey:KeyFromSetter(_cmd)];
}

static long long getter_ll(id self, SEL _cmd)
{
    return [[self objectForKey:NSStringFromSelector(_cmd)] longLongValue];
}

static void setter_ll(id self, SEL _cmd, long long value)
{
    [self setObject:@(value) forKey:KeyFromSetter(_cmd)];
}

static unsigned long long getter_ull(id self, SEL _cmd)
{
    return [[self objectForKey:NSStringFromSelector(_cmd)] unsignedLongLongValue];
}

static void setter_ull(id self, SEL _cmd, unsigned long long value)
{
    [self setObject:@(value) forKey:KeyFromSetter(_cmd)];
}

// d
static double getter_d(id self, SEL _cmd)
{
    return [[self objectForKey:NSStringFromSelector(_cmd)] doubleValue];
}

static void setter_d(id self, SEL _cmd, double value)
{
    [self setObject:[NSNumber numberWithDouble:value] forKey:KeyFromSetter(_cmd)];
}

// f
static float getter_f(id self, SEL _cmd)
{
    return [[self objectForKey:NSStringFromSelector(_cmd)] floatValue];
}

static void setter_f(id self, SEL _cmd, float value)
{
    [self setObject:[NSNumber numberWithFloat:value] forKey:KeyFromSetter(_cmd)];
}

/**
 @see https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
 */
+(void)synthesizeWithGetterName:(NSString *)getterName type:(const char)type isCopy:(BOOL)isCopy{
    NSString *setterName = [NSString stringWithFormat:@"set%@%@:",
                            [[getterName substringToIndex:1] uppercaseString],
                            [getterName substringFromIndex:1]];
    
    // just handle 3 types in simple   id/double(double float)/long long(char int unsign char .....)
    // Objective-C does not support the long double
    switch (type) {
        case '@':
            // name
            class_addMethod([self class], NSSelectorFromString(getterName),
                            (IMP)getter, "@@:");
            // setName:(id)
            if (isCopy) {
                class_addMethod([self class], NSSelectorFromString(setterName),
                                (IMP)setterWithCopy, "v@:@");
            } else {
                class_addMethod([self class], NSSelectorFromString(setterName),
                                (IMP)setter, "v@:@");
            }
            break;
        case 'f':
            class_addMethod([self class], NSSelectorFromString(getterName),
                            (IMP)getter_f, "f@:");
            class_addMethod([self class], NSSelectorFromString(setterName),
                            (IMP)setter_f, "v@:f");
            break;
        case 'd':
            class_addMethod([self class], NSSelectorFromString(getterName),
                            (IMP)getter_d, "d@:");
            class_addMethod([self class], NSSelectorFromString(setterName),
                            (IMP)setter_d, "v@:d");
            break;
        case 'q':
            class_addMethod([self class], NSSelectorFromString(getterName),
                            (IMP)getter_ll, "q@:");
            class_addMethod([self class], NSSelectorFromString(setterName),
                            (IMP)setter_ll, "v@:q");
            break;
        case 'Q':
            class_addMethod([self class], NSSelectorFromString(getterName),
                            (IMP)getter_ull, "Q@:");
            class_addMethod([self class], NSSelectorFromString(setterName),
                            (IMP)setter_ull, "v@:Q");
            break;
        case 'B':
            class_addMethod([self class], NSSelectorFromString(getterName),
                            (IMP)getter_b, "B@:");
            class_addMethod([self class], NSSelectorFromString(setterName),
                            (IMP)setter_b, "v@:B");
            break;
        case 'c':
            // see BOOL definition in objc.h
            if (@encode(BOOL)[0] == 'c') {
                // 32 bit device or simulator
                class_addMethod([self class], NSSelectorFromString(getterName),
                                (IMP)getter_b, "B@:");
                class_addMethod([self class], NSSelectorFromString(setterName),
                                (IMP)setter_b, "v@:B");
                break;
            }
        default: // all the other handle with long long
            class_addMethod([self class], NSSelectorFromString(getterName),
                            (IMP)getter_l, "l@:");
            // setName:(long long)
            class_addMethod([self class], NSSelectorFromString(setterName),
                            (IMP)setter_l, "v@:l");
            break;
    }
}

- (void)setValue:(id)value forKey:(NSString *)key {
    @try {
        [super setValue:value forKey:key];
    } @catch (NSException *exception) {
        NSString *link = @"https://leancloud.cn/docs/ios_os_x_guide.html#AVObject";
        AVLoggerError(nil, @"Class %@ may contain a reserved property: %@, see %@ for more infomation.", NSStringFromClass([self class]), key, link);

        [exception raise];
    }
}

@end
