//
//  AVHistoryMessage.m
//  AVOS
//
//  Created by Qihe Bian on 10/21/14.
//
//

#import "AVHistoryMessage.h"

@implementation AVHistoryMessage
- (id)copyWithZone:(NSZone *)zone {
    AVHistoryMessage *message = [super copy];
    if (message) {
        message.conversationId = _conversationId;
    }
    return message;
}
@end
