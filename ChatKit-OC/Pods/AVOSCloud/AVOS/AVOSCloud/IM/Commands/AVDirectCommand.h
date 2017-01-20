//
//  AVDirectCommand.h
//  AVOS
//
//  Created by Qihe Bian on 9/5/14.
//
//

#import "AVCommand.h"
#import "AVMessage.h"

@interface AVDirectCommand : AVCommand
@property(nonatomic, strong)NSString *msg;
//@property(nonatomic, strong)NSString *peerId;
@property(nonatomic, strong)NSString *roomId;

@property(nonatomic, strong)AVMessage *message;
@property(nonatomic)bool transient;

+ (instancetype)commandWithMessage:(AVMessage *)message transient:(BOOL)transient;

@end
