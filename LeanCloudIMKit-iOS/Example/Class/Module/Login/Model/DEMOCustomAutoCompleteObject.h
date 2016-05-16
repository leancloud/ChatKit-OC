//
//  DEMOCustomAutoCompleteObject.h
//  MLPAutoCompleteDemo
//
//  Created by Eddy Borja on 4/19/13.
//  Copyright (c) 2013 Mainloop. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MLPAutoCompletionObject.h"

@interface DEMOCustomAutoCompleteObject : NSObject <MLPAutoCompletionObject>

- (id)initWithCountry:(NSString *)name;

@end
