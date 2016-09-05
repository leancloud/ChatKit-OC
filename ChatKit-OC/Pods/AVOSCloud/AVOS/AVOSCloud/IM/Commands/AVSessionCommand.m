//
//  AVSessionCommand.m
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVSessionCommand.h"

NSString *const AVSessionOperationOpen = @"open";
NSString *const AVSessionOperationOpened = @"opened";
NSString *const AVSessionOperationAdd = @"add";
NSString *const AVSessionOperationAdded = @"added";
NSString *const AVSessionOperationRemove = @"remove";
NSString *const AVSessionOperationClose = @"close";
NSString *const AVSessionOperationQuery = @"query";
NSString *const AVSessionOperationQueryResult = @"query-result";

@implementation AVSessionCommand
@dynamic op;

- (instancetype)init {
    if ((self = [super init])) {
        self.cmd = AVCommandSession;
    }
    return self;
}

- (NSString *)description {
    NSString *des = [[NSString alloc] initWithFormat:@"%@ operation:%@", [super description], self.op];
    return des;
}
@end
