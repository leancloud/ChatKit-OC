//
//  AVCloudQueryResult.m
//  AVOS
//
//  Created by Qihe Bian on 9/22/14.
//
//

#import "AVCloudQueryResult.h"
#import "AVCloudQueryResult_Internal.h"

@implementation AVCloudQueryResult

- (void)setClassName:(NSString *)className {
    _className = className;
}

- (void)setResults:(NSArray *)results {
    _results = results;
}

- (void)setCount:(NSUInteger)count {
    _count = count;
}
@end
