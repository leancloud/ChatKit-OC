//
//  Mp3Recorder.h
//  BloodSugar
//
//  v0.8.5 Created by PeterPan on 14-3-24.
//  Copyright (c) 2014年 shake. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Mp3RecorderDelegate <NSObject>
/**
 失败 时间太短
 */
- (void)tooShortFailRecord;

/**
 成功 转换格式成功
 @param fileName 文件路径
 */
- (void)endConvertWithMP3FileName:(NSString *)fileName;
/**
 音量 变化

 @param volume 音量
 */
- (void)averagePowerWithVolume:(CGFloat)volume;
@optional
- (void)beginConvert;
@end

@interface Mp3Recorder : NSObject
@property (nonatomic, weak) id<Mp3RecorderDelegate> delegate;

- (id)initWithDelegate:(id<Mp3RecorderDelegate>)delegate;
- (void)startRecord;
- (void)stopRecord;
- (void)cancelRecord;

@end
