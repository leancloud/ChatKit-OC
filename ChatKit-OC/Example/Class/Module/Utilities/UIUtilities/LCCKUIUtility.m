//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import "LCCKUIUtility.h"
//#import <UIImageView+WebCache.h>
#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif
#import "NSFileManager+LCCKExtension.h"

static UILabel *hLabel = nil;

@implementation LCCKUIUtility

+ (CGFloat) getTextHeightOfText:(NSString *)text
                           font:(UIFont *)font
                          width:(CGFloat)width {
    if (hLabel == nil) {
        hLabel = [[UILabel alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [hLabel setNumberOfLines:0];
    }
    hLabel.frame = ({
        CGRect frame = hLabel.frame;
        frame.size.width = width;
        frame;
    });
    [hLabel setFont:font];
    [hLabel setText:text];
    return [hLabel sizeThatFits:CGSizeMake(width, MAXFLOAT)].height;
}

//+ (void)createGroupAvatar:(LCCKGroup *)group finished:(void (^)(NSString *groupID))finished
//{
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSInteger usersCount = group.users.count > 9 ? 9 : group.users.count;
//        CGFloat viewWidth = 200;
//        CGFloat width = viewWidth / 3 * 0.85;
//        CGFloat space3 = (viewWidth - width * 3) / 4;               // 三张图时的边距（图与图之间的边距）
//        CGFloat space2 = (viewWidth - width * 2 + space3) / 2;      // 两张图时的边距
//        CGFloat space1 = (viewWidth - width) / 2;                   // 一张图时的边距
//        CGFloat y = usersCount > 6 ? space3 : (usersCount > 3 ? space2 : space1);
//        CGFloat x = usersCount % 3 == 0 ? space3 : (usersCount % 3 == 2 ? space2 : space1);
//        
//        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, viewWidth)];
//        [view setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:0.6]];
//        __block NSInteger count = 0;        // 下载完成图片计数器
//        for (NSInteger i = usersCount - 1; i >= 0; i--) {
//            LCCKUser *user = [group.users objectAtIndex:i];
//            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y, width, width)];
//            [view addSubview:imageView];
//            [imageView sd_setImageWithURL:LCCKURL(user.avatarURL) placeholderImage:[UIImage imageNamed:DEFAULT_AVATAR_PATH] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
//                count ++;
//                if (count == usersCount) {     // 图片全部下载完成
//                    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 2.0);
//                    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
//                    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//                    UIGraphicsEndImageContext();
//                    CGImageRef imageRef = image.CGImage;
//                    CGImageRef imageRefRect =CGImageCreateWithImageInRect(imageRef, CGRectMake(0, 0, view.width * 2, view.height * 2));
//                    UIImage *ansImage = [[UIImage alloc] initWithCGImage:imageRefRect];
//                    NSData *imageViewData = UIImagePNGRepresentation(ansImage);
//                    NSString *savedImagePath = [NSFileManager pathUserAvatar:group.groupAvatarPath];
//                    [imageViewData writeToFile:savedImagePath atomically:YES];
//                    CGImageRelease(imageRefRect);
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if (finished) {
//                            finished(group.groupID);
//                        }
//                    });
//                }
//            }];
//            if (i % 3 == 0) {   // 换行
//                y += (width + space3);
//                x = space3;
//            }
//            else if (i == 2 && usersCount == 3) {  // 换行，只有三个时
//                y += (width + space3);
//                x = space2;
//            }
//            else {
//                x += (width + space3);
//            }
//        }
//    });
//}


+ (void)captureScreenshotFromView:(UIView *)view
                             rect:(CGRect)rect
                         finished:(void (^)(NSString *avatarPath))finished
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 2.0);
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CGImageRef imageRef = image.CGImage;
        CGImageRef imageRefRect =CGImageCreateWithImageInRect(imageRef, CGRectMake(rect.origin.x * 2, rect.origin.y * 2, rect.size.width * 2, rect.size.height * 2));
        UIImage *ansImage = [[UIImage alloc] initWithCGImage:imageRefRect];
        NSData *imageViewData = UIImagePNGRepresentation(ansImage);
        NSString *imageName = [NSString stringWithFormat:@"%.0lf.png", [NSDate date].timeIntervalSince1970 * 10000];
        NSString *savedImagePath = [NSFileManager lcck_pathScreenshotImage:imageName];
        [imageViewData writeToFile:savedImagePath atomically:YES];
        CGImageRelease(imageRefRect);
        dispatch_async(dispatch_get_main_queue(), ^{
            finished(imageName);
        });
    });
}

@end
