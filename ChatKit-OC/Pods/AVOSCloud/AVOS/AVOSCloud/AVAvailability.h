//
//  AVAvailability.h
//  AVOS
//
//  Created by Tang Tianyong on 1/6/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import <Availability.h>
#import <TargetConditionals.h>

#ifndef AV_IOS_UNAVAILABLE
#  ifdef __IOS_UNAVILABLE
#    define AV_IOS_UNAVAILABLE __IOS_UNAVAILABLE
#  else
#    define AV_IOS_UNAVAILABLE
#  endif
#endif

#ifndef AV_OSX_UNAVAILABLE
#  if TARGET_OS_MAC
#    define AV_OSX_UNAVAILABLE __OSX_UNAVAILABLE
#  else
#    define AV_OSX_UNAVAILABLE
#  endif
#endif

#ifndef AV_WATCH_UNAVAILABLE
#  ifdef __WATCHOS_UNAVAILABLE
#    define AV_WATCH_UNAVAILABLE __WATCHOS_UNAVAILABLE
#  else
#    define AV_WATCH_UNAVAILABLE
#  endif
#endif

#ifndef AV_TV_UNAVAILABLE
#  ifdef __TVOS_PROHIBITED
#    define AV_TV_UNAVAILABLE __TVOS_PROHIBITED
#  else
#    define AV_TV_UNAVAILABLE
#  endif
#endif

#define AV_IOS_ONLY (TARGET_OS_IPHONE)
#define AV_OSX_ONLY (TARGET_OS_MAC && !TARGET_OS_IPHONE)

#define AV_TARGET_OS_OSX (TARGET_OS_MAC && !TARGET_OS_IOS && !TARGET_OS_WATCH && !TARGET_OS_TV)
#define AV_TARGET_OS_IOS (TARGET_OS_IOS && !TARGET_OS_WATCH && !TARGET_OS_TV)
