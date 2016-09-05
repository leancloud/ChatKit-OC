
#import "AVRelation.h"
#import "AVQuery.h"
#import "AVUtils.h"
#import "AVObject_Internal.h"
#import "AVQuery_Internal.h"
#import "AVRelation_Internal.h"
#import "AVObjectUtils.h"

@implementation AVRelation

- (AVQuery *)query
{
    NSMutableDictionary * dict = [@{@"$relatedTo": @{@"object": [AVObjectUtils dictionaryFromAVObjectPointer:self.parent], @"key":self.key}} mutableCopy];
    NSString *targetClass;
    if (!self.targetClass) {
        targetClass = self.parent.className;
    } else {
        targetClass = self.targetClass;
    }
    AVQuery * query = [AVQuery queryWithClassName:targetClass];
    [query setValue:[NSMutableDictionary dictionaryWithDictionary:dict] forKey:@"where"];
    if (!self.targetClass) {
        query.extraParameters = [@{@"redirectClassNameForKey":self.key} mutableCopy];
    }
    return query;
}

- (void)addObject:(AVObject *)object
{
    // check object id
    if (![object hasValidObjectId]) {
        NSException * exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                          reason:@"All objects in a relation must have object ids."
                                                        userInfo:nil];
        [exception raise];
    }
    self.targetClass = object.className;
    [self.parent addRelation:object forKey:self.key submit:YES];
}

- (void)removeObject:(AVObject *)object
{
    [self.parent removeRelation:object forKey:self.key];
}

+(AVQuery *)reverseQuery:(NSString *)parentClassName
             relationKey:(NSString *)relationKey
             childObject:(AVObject *)child
{
    NSDictionary * dict = @{relationKey: [AVObjectUtils dictionaryFromAVObjectPointer:child]};
    AVQuery * query = [AVQuery queryWithClassName:parentClassName];
    [query setValue:[NSMutableDictionary dictionaryWithDictionary:dict] forKey:@"where"];
    return query;
}

+(AVRelation *)relationFromDictionary:(NSDictionary *)dict {
    AVRelation * relation = [[AVRelation alloc] init];
    relation.targetClass = [dict objectForKey:classNameTag];
    return relation;
}

@end


