//
//  AVIMAvailability.h
//  AVOS
//
//  Created by Tang Tianyong on 1/6/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//

#import <Availability.h>
#import <TargetConditionals.h>

#ifndef AVIM_IOS_UNAVAILABLE
#  ifdef __IOS_UNAVILABLE
#    define AVIM_IOS_UNAVAILABLE __IOS_UNAVAILABLE
#  else
#    define AVIM_IOS_UNAVAILABLE
#  endif
#endif

#ifndef AVIM_OSX_UNAVAILABLE
#  if TARGET_OS_MAC
#    define AVIM_OSX_UNAVAILABLE __OSX_UNAVAILABLE
#  else
#    define AVIM_OSX_UNAVAILABLE
#  endif
#endif

#ifndef AVIM_WATCH_UNAVAILABLE
#  ifdef __WATCHOS_UNAVAILABLE
#    define AVIM_WATCH_UNAVAILABLE __WATCHOS_UNAVAILABLE
#  else
#    define AVIM_WATCH_UNAVAILABLE
#  endif
#endif

#ifndef AVIM_TV_UNAVAILABLE
#  ifdef __TVOS_PROHIBITED
#    define AVIM_TV_UNAVAILABLE __TVOS_PROHIBITED
#  else
#    define AVIM_TV_UNAVAILABLE
#  endif
#endif

#define AVIM_IOS_ONLY (TARGET_OS_IPHONE)
#define AVIM_OSX_ONLY (TARGET_OS_MAC && !TARGET_OS_IPHONE)

#define AVIM_TARGET_OS_OSX (TARGET_OS_MAC && !TARGET_OS_IOS && !TARGET_OS_WATCH && !TARGET_OS_TV)
#define AVIM_TARGET_OS_IOS (TARGET_OS_IOS && !TARGET_OS_WATCH && !TARGET_OS_TV)

#define AVIM_DEPRECATED(explain) __attribute__((deprecated(explain)))
