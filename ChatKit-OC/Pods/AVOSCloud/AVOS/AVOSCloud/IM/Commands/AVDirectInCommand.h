//
//  AVDirectInCommand.h
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVDirectCommand.h"

@interface AVDirectInCommand : AVDirectCommand
@property(nonatomic, strong)NSString *id;
@property(nonatomic, strong)NSString *fromPeerId;
@property(nonatomic)int64_t timestamp;
@property(nonatomic)bool offline;
@end
