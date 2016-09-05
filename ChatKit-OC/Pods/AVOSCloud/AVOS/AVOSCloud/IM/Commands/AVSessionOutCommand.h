//
//  AVSessionOutCommand.h
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVSessionCommand.h"
#import "AVSignature.h"

@interface AVSessionOutCommand : AVSessionCommand
@property(nonatomic) NSString *appId;
@property(nonatomic, strong)NSArray *sessionPeerIds;
@property(nonatomic, strong)AVSignature *signature;
@end
