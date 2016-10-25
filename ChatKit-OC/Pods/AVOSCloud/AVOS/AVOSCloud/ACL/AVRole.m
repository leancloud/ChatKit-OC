
#import <Foundation/Foundation.h>
#import "AVObject.h"
#import "AVObject_Internal.h"
#import "AVRole.h"
#import "AVRole_Internal.h"
#import "AVQuery.h"
#import "AVRelation.h"
#import "AVRelation_Internal.h"
#import "AVACL.h"
#import "AVPaasClient.h"
#import "AVGlobal.h"
#import "AVUtils.h"

@implementation AVRole

@synthesize name = _name;
@synthesize acl = _acl;
@synthesize relationData = _relationData;

+(NSString *)className
{
    return @"_Role";
}

+(NSString *)endPoint
{
    return @"roles";
}

- (instancetype)initWithName:(NSString *)name
{
    self = [super initWithClassName:[AVRole className]];
    if (self)
    {
        self.name = name;
        _relationData = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+(instancetype)role {
    AVRole * r = [[AVRole alloc] initWithName:@""];
    return r;
}

- (instancetype)initWithName:(NSString *)name acl:(AVACL *)acl
{
    self = [self initWithName:name];
    if (self)
    {
        self.acl = acl;
    }
    return self;
}

+ (instancetype)roleWithName:(NSString *)name
{
    AVRole * role = [[AVRole alloc] initWithName:name];
    return role;
}

+ (instancetype)roleWithName:(NSString *)name acl:(AVACL *)acl
{
    AVRole * role = [[AVRole alloc] initWithName:name acl:acl];
    return role;
}

- (AVRelation *)users
{
    return [self relationForKey:@"users"];
}

- (AVRelation *)roles
{
    return [self relationForKey:@"roles"];
}

+ (AVQuery *)query
{
    AVQuery *query = [[AVQuery alloc] initWithClassName:[AVRole className]];
    return query;
}

-(NSMutableDictionary *)initialBodyData {
    return [self.requestManager initialSetAndAddRelationDict];
}

-(void)setName:(NSString *)name {
    _name = name;
    [self addSetRequest:@"name" object:name];
}

-(void)setAcl:(AVACL *)acl {
    _acl = acl;
    [self addSetRequest:ACLTag object:acl];
}

@end
