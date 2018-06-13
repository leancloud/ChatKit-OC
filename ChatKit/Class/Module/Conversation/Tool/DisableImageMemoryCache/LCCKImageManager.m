//
//  LCCKImageManager.m
//  Kuber
//
//  v0.8.5 Created by Kuber on 16/3/30.
//  Copyright © 2016年 Huaxu Technology. All rights reserved.
//

#import "LCCKImageManager.h"
#import "NSBundle+LCCKSCaleArray.h"
#import "NSString+LCCKAddScale.h"
#import "NSMutableDictionary+LCCKWeakReference.h"

@interface LCCKImageManager()

@property (nonatomic, strong) NSMutableDictionary *imageBuff;

@end

@implementation LCCKImageManager

+ (instancetype)defaultManager {
    static LCCKImageManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (UIImage *)getImageWithName:(NSString *)name {
    UIImage *storeImage = [self getImageWithName:name inBundle:[NSBundle mainBundle]];
    return storeImage;
}

- (UIImage *)getImageWithName:(NSString *)name inBundle:(NSBundle *)bundle {
    UIImage *image = [self.imageBuff lcck_weak_getObjectForKey:name];
    if(image) {
        return image;
    }
    NSString *res = name.stringByDeletingPathExtension;
    NSString *ext = name.pathExtension;
    NSString *path = nil;
    CGFloat scale = 1;
    // If no extension, guess by system supported (same as UIImage).
    NSArray *exts = ext.length > 0 ? @[ext] : @[@"", @"png", @"jpeg", @"jpg", @"gif", @"webp", @"apng"];
    NSArray *scales = [NSBundle lcck_scaleArray];
    for (int s = 0; s < scales.count; s++) {
        scale = ((NSNumber *)scales[s]).floatValue;
        NSString *scaledName = [res lcck_stringByAppendingScale:scale];
        for (NSString *e in exts) {
            path = [bundle pathForResource:scaledName ofType:e];
            if (path) break;
        }
        if (path) break;
    }
    if (path.length == 0) return nil;
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data.length == 0) return nil;
    UIImage *storeImage = [[UIImage alloc] initWithData:data scale:scale];
    [self.imageBuff lcck_weak_setObject:storeImage forKey:name];
    return storeImage;
}

- (NSMutableDictionary *)imageBuff {
    if(!_imageBuff) {
        _imageBuff = [NSMutableDictionary dictionary];
    }
    return _imageBuff;
}

@end
