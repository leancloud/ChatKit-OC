//
//  AVCommand.h
//  AVOS
//
//  Created by Qihe Bian on 9/4/14.
//
//

#import "AVDynamicBase.h"

extern NSString *const AVCommandPresence;
extern NSString *const AVCommandDirect;
extern NSString *const AVCommandSession;
extern NSString *const AVCommandAckReq;
extern NSString *const AVCommandAck;
extern NSString *const AVCommandRoom;
extern NSString *const AVCommandRcp;

typedef enum : NSUInteger {
    AVCommandIOTypeIn,
    AVCommandIOTypeOut,
} AVCommandIOType;

@class AVCommand;

typedef void (^AVCommandResultBlock)(AVCommand *outCommand, AVCommand *inCommand, NSError *error);

@interface AVCommand : AVDynamicBase
@property(nonatomic) uint16_t i;
@property(nonatomic) NSString *cmd;
@property(nonatomic) NSString *peerId;

+ (instancetype)commandWithJSON:(NSString *)json ioType:(AVCommandIOType)ioType;
+ (instancetype)commandWithDictionary:(NSDictionary *)dictionary ioType:(AVCommandIOType)ioType;
+ (uint16_t)nextSerialId;

- (void)addOrRefreshSerialId;
- (void)setCallback:(AVCommandResultBlock)callback;
- (AVCommandResultBlock)callback;
@end
