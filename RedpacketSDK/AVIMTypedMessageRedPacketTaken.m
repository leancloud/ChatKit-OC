//
//  RedpacketTakenMessage.m
//  RCloudMessage
//
//  Created by YANG HONGBO on 2016-5-3.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "AVIMTypedMessageRedPacketTaken.h"

@implementation AVIMTypedMessageRedPacketTaken
+ (void)load{
    [self registerSubclass];
}
+ (AVIMMessageMediaType)classMediaType;{
    return 4;
}
- (instancetype)initWithClientId:(NSString *)clientId
                ConversationType:(LCCKConversationType)conversationType
                  receiveMembers:(NSArray<NSString*>*)members
{
    self = [super init];
    if (!self) {
        return nil;
    }
    [self setText:@"抢红包"];
    [self lcck_setObject:@"抢红包消息" forKey:LCCKCustomMessageTypeTitleKey];
    [self lcck_setObject:@"这是一条抢红包消息，当前版本过低无法显示，请尝试升级APP查看" forKey:LCCKCustomMessageDegradeKey];
    [self lcck_setObject:@"有人向您发送了一条抢红包，请打开APP查看" forKey:LCCKCustomMessageSummaryKey];
    
    if (members.count) {
        NSMutableString * memberString = [NSMutableString string];
        [members enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [memberString appendFormat:@"%@,",obj];
        }];
        [self lcck_setObject:[memberString substringToIndex:memberString.length -1] forKey:@"OnlyVisiableForClientId"];
        //    [self lcck_setObject:@[ @"Tom", @"Jerry"] forKey:LCCKCustomMessageOnlyVisiableForPartClientIds];
    }
    return self;
}
- (void)setAttributes:(NSDictionary *)attributes{
    [attributes enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self setObject:obj forKey:key];
    }];
}
- (NSDictionary *)attributes{
    
    NSError * error;
    NSDictionary * attributes = [NSJSONSerialization JSONObjectWithData:[self.payload dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:&error];
    if (!error) return attributes;
    
    return nil;
}
@end
