//
//  AVIMMessage+LCCKExtension.h
//  Pods
//
//  Created by 陈宜龙 on 16/8/20.
//
//

#import <AVOSCloudIM/AVOSCloudIM.h>

@interface AVIMMessage (LCCKExtension)

- (AVIMTypedMessage *)lcck_getValidTypedMessage;

@end
