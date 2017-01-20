//
//  AVRcpCommand.h
//  AVOS
//
//  Created by Qihe Bian on 11/5/14.
//
//

#import "AVCommand.h"

@interface AVRcpCommand : AVCommand
@property(nonatomic, strong)NSString *id;
@property(nonatomic)int64_t t;

@end
