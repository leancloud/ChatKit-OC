//
//  AVAckCommand.h
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVCommand.h"

@interface AVAckCommand : AVCommand
//@property(nonatomic, strong)NSString *peerId;
@property(nonatomic, strong)NSArray *ids;
@property(nonatomic)int64_t t;
@property(nonatomic, strong)NSString *uid;

@end
