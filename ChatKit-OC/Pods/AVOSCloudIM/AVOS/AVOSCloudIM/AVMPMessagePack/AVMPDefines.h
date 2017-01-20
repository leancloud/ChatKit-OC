//
//  AVMPDefines.h
//  AVMPMessagePack
//
//  Created by Gabriel on 12/13/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#undef AVMPDebug
#define AVMPDebug(fmt, ...) do {} while(0)
#undef AVMPErr
#define AVMPErr(fmt, ...) do {} while(0)

#if DEBUG
#undef AVMPDebug
#define AVMPDebug(fmt, ...) NSLog((@"%s:%d: " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#undef AVMPErr
#define AVMPErr(fmt, ...) NSLog((@"%s:%d: " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#endif

typedef void (^AVMPCompletion)(NSError *error);

#define AVMPMakeError(CODE, fmt, ...) [NSError errorWithDomain:@"AVMPMessagePack" code:CODE userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:fmt, ##__VA_ARGS__]}]

#define AVMPIfNull(obj, val) ([obj isEqual:NSNull.null] ? val : obj)