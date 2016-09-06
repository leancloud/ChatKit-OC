//
//  AVPresenceCommand.h
//  AVOS
//
//  Created by Qihe Bian on 9/5/14.
//
//

#import "AVCommand.h"
extern NSString *const AVPresenceStatusOn;
extern NSString *const AVPresenceStatusOff;

@interface AVPresenceCommand : AVCommand
@property(nonatomic, strong)NSArray *sessionPeerIds;
@property(nonatomic, strong)NSString *status;
//@property(nonatomic, strong)NSString *peerId;
@end
