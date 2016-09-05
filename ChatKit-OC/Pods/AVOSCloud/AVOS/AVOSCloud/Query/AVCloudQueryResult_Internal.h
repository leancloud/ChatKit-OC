//
//  AVCloudQueryResult_Internal.h
//  AVOS
//
//  Created by Qihe Bian on 9/22/14.
//
//

#import <Foundation/Foundation.h>
#import "AVCloudQueryResult.h"

@interface AVCloudQueryResult()
- (void)setClassName:(NSString *)className;
- (void)setCount:(NSUInteger)count;
- (void)setResults:(NSArray *)results;
@end
