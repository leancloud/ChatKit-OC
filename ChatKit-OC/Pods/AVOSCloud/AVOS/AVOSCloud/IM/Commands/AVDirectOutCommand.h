//
//  AVDirectOutCommand.h
//  AVOS
//
//  Created by Qihe Bian on 9/9/14.
//
//

#import "AVDirectCommand.h"
#import "AVMessage.h"

@interface AVDirectOutCommand : AVDirectCommand
@property(nonatomic, strong)NSArray *toPeerIds;
@property(nonatomic)bool r;

- (void)setReceiptCallback:(AVCommandResultBlock)callback;
- (AVCommandResultBlock)receiptCallback;
@end
