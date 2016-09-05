//
//  AVPartialInputStream.h
//  AVOS
//
//  Created by Qihe Bian on 8/21/14.
//
//

#import <Foundation/Foundation.h>

@interface AVPartialInputStream : NSInputStream
@property (nonatomic) uint64_t offset;
@property (nonatomic) uint64_t maxLength;
@end
