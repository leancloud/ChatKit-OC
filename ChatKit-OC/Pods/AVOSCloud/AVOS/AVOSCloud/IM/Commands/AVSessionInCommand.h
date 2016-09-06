//
//  AVSessionInCommand.h
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVSessionCommand.h"

@interface AVSessionInCommand : AVSessionCommand
@property(nonatomic, strong)NSArray *onlineSessionPeerIds;

@end
