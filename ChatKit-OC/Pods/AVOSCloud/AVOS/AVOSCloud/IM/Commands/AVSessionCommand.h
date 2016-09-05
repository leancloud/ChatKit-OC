//
//  AVSessionCommand.h
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVCommand.h"

extern NSString *const AVSessionOperationOpen;
extern NSString *const AVSessionOperationOpened;
extern NSString *const AVSessionOperationAdd;
extern NSString *const AVSessionOperationAdded;
extern NSString *const AVSessionOperationRemove;
extern NSString *const AVSessionOperationClose;
extern NSString *const AVSessionOperationQuery;
extern NSString *const AVSessionOperationQueryResult;

@interface AVSessionCommand : AVCommand
@property(nonatomic, strong) NSString *op;
//@property(nonatomic, strong)NSString *peerId;
@end
