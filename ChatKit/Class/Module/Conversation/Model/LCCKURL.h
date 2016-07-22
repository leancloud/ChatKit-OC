//
//  LCCKURL.h
//  Pods
//
//  Created by 陈宜龙 on 16/7/22.
//
//

#import <Foundation/Foundation.h>

@interface LCCKURL : NSObject

@property (nonatomic, strong) NSString *urlString;         // e.g. "http://t.co/YuvsPou0rj"
@property (nonatomic, strong) NSString *displayURL;  // e.g. "apple.com/tv/compare/"
@property (nonatomic, strong) NSString *expandedURL; // e.g. "http://www.apple.com/tv/compare/"
@property (nonatomic, strong) NSArray<NSNumber *> *indices;      // Array<NSNumber> from, to

@property (nonatomic, assign) NSRange range;         // range from indices
@property (nonatomic, strong) NSArray<NSValue *> *ranges;       // Array<NSValue(NSRange)> nil if range is less than or equal to one.

- (instancetype)initWithURLString:(NSString *)URLString range:(NSRange)range;
+ (instancetype)urlWithURLString:(NSString *)URLString range:(NSRange)range;

@end
