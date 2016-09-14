//
//  AVPaasClient_internal.h
//  AVOS
//
//  Created by Tang Tianyong on 5/23/16.
//  Copyright © 2016 LeanCloud Inc. All rights reserved.
//


@interface AVPaasClient()

/**
 A table of requests indexed by URL.

 If request task is not retained by application,
 the request will be removed from this table automaticly after request did finish.
 Thanks to the feature of NSMapTable.
 */
@property (nonatomic, strong) NSMapTable *requestTable;

@end
