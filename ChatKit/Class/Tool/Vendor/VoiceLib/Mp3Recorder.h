//
//  Mp3Recorder.h
//  BloodSugar
//
//  v0.8.5 Created by PeterPan on 14-3-24.
//  Copyright (c) 2014年 shake. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Mp3RecorderDelegate <NSObject>
- (void)failRecord;
- (void)beginConvert;
- (void)endConvertWithMP3FileName:(NSString *)fileName;
- (void)realTimeVolumeSize:(float)size timeLength:(NSTimeInterval)timeLength;
@end

@interface Mp3Recorder : NSObject
@property (nonatomic, weak) id<Mp3RecorderDelegate> delegate;

- (id)initWithDelegate:(id<Mp3RecorderDelegate>)delegate;
- (void)startRecord;
- (void)stopRecord;
- (void)cancelRecord;

@end
