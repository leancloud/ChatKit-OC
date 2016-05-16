//
//  MLPViewController.h
//  MLPAutoCompleteDemo
//
//  Created by Eddy Borja on 1/23/13.
//  Copyright (c) 2013 Mainloop. All rights reserved.
//

///-----------------------------------------------------------------------------------
///---------------------用以产生Demo中的联系人数据的宏定义-------------------------------
///-----------------------------------------------------------------------------------

#define LCIMProfileKeyPeerId        @"peerId"
#define LCIMProfileKeyName          @"username"
#define LCIMProfileKeyAvatarURL     @"avatarURL"
#define LCIMDeveloperPeerId @"571dae7375c4cd3379024b2f"

//TODO:add more friends
#define LCIMContactProfiles \
@[ \
@{ LCIMProfileKeyPeerId:LCIMDeveloperPeerId, LCIMProfileKeyName:@"LCIMKit小秘书", LCIMProfileKeyAvatarURL:@"http://image17-c.poco.cn/mypoco/myphoto/20151211/16/17338872420151211164742047.png" },\
@{ LCIMProfileKeyPeerId:@"Tom", LCIMProfileKeyName:@"Tom", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/tom_and_jerry2.jpg" },\
@{ LCIMProfileKeyPeerId:@"Jerry", LCIMProfileKeyName:@"Jerry", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/jerry.jpg" },\
@{ LCIMProfileKeyPeerId:@"Harry", LCIMProfileKeyName:@"Harry", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/young_harry.jpg" },\
@{ LCIMProfileKeyPeerId:@"William", LCIMProfileKeyName:@"William", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/william_shakespeare.jpg" },\
@{ LCIMProfileKeyPeerId:@"Bob", LCIMProfileKeyName:@"Bob", LCIMProfileKeyAvatarURL:@"http://www.avatarsdb.com/avatars/bath_bob.jpg" },\
]

#define LCIMContactPeerIds \
[LCIMContactProfiles valueForKeyPath:LCIMProfileKeyPeerId]

#define LCIMTestPersonProfiles \
@[ \
@{ LCIMProfileKeyPeerId:@"Tom" },\
@{ LCIMProfileKeyPeerId:@"Jerry" },\
@{ LCIMProfileKeyPeerId:@"Harry" },\
@{ LCIMProfileKeyPeerId:@"William" },\
@{ LCIMProfileKeyPeerId:@"Bob" },\
]

#define LCIMTestPeerIds \
[LCIMTestPersonProfiles valueForKeyPath:LCIMProfileKeyPeerId]


#import <UIKit/UIKit.h>
#import "MLPAutoCompleteTextFieldDelegate.h"

@class DEMODataSource;
@class MLPAutoCompleteTextField;
@interface LCIMLoginViewController : UIViewController <UITextFieldDelegate, MLPAutoCompleteTextFieldDelegate>

@property (strong, nonatomic) IBOutlet DEMODataSource *autocompleteDataSource;
@property (weak) IBOutlet MLPAutoCompleteTextField *autocompleteTextField;
@property (strong, nonatomic) IBOutlet UILabel *demoTitle;
@property (strong, nonatomic) IBOutlet UILabel *author;
@property (strong, nonatomic) IBOutlet UISegmentedControl *typeSwitch;




@end
