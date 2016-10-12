# ChatKit 自定义业务


## 导航
  1.  [设置单聊用户的头像和昵称](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#设置单聊用户的头像和昵称) 
      - [ClientId 与 UserId](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#clientid-与-userid) 
  2.  [Profile缓存](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#profile缓存) 
  3.  [聊天页面头像点击事件](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#聊天页面头像点击事件) 
  4.  [自定义会话列表左滑菜单](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#自定义会话列表左滑菜单) 
  5.  [自定义长按菜单](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#自定义长按菜单) 
  6.  [自定义消息](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#自定义消息) 
      -  [不需要显示自定义 Cell 的消息](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#不需要显示自定义-cell-的消息) 
      -  [需要显示自定义 Cell 的消息](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#需要显示自定义-cell-的消息) 
  7. [自定义消息步骤](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#自定义消息步骤) 
      1.  [自定义消息](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#自定义消息) 
      2. [自定义消息 Cell](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#自定义消息-cell) 
      3.  [自定义输入框插件](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#自定义输入框插件) 
      4.  [删除自定义插件、自定义消息、自定义 Cell (可选) ](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#删除自定义插件自定义消息自定义-cell) 
  8.  [国际化与本地化](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#国际化与本地化) 
  9.  [其他事件及属性](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#其他事件及属性) 
      -  [监听并筛选或处理消息](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#监听并筛选或处理消息) 
      -  [预览大图](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#预览大图) 
      -  [预览地理位置](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#预览地理位置)
      -  [消息未读数](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#消息未读数)
      -  [设置单点登录与强制重连](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#设置单点登录与强制重连)


## 设置单聊用户的头像和昵称

当你的应用想要集成一个IM服务时，可能这时候，你的APP已经上架了，已经有自己的注册、登录等流程了。用 ChatKit 进行聊天很简单，只需要给 ChatKit 一个 id 就够了，就像 Demo 里做的那样。聊天是正常了，但是双方只能看到一个id，这样体验很不好。但是如何展示头像、昵称呢？于是就设计了这样一个接口，`-setFetchProfilesBlock:` 。

这是上层（APP）提供用户信息的 Block，由于 ChatKit 并不关心业务逻辑信息，比如用户昵称，用户头像等。用户可以通过 ChatKit 单例向 ChatKit 注入一个用户信息内容提供 Block，通过这个用户信息提供 Block，ChatKit 才能够正确的进行业务逻辑数据的绘制。

示意图如下：

![](http://ww2.sinaimg.cn/large/801b780ajw1f8ah885yn0j20e70bw754.jpg)

用法如下：

首先要必须自己新建一个表示 User 的 Model 并遵循 LCCKUserDelegate 协议，Demo 中对应的是 `LCCKUser`。

然后实现 `-setFetchProfilesBlock:`：

 ```Objective-C
 
#warning 注意：setFetchProfilesBlock 方法必须实现，如果不实现，ChatKit将无法显示用户头像、用户昵称。以下方法循环模拟了通过 userIds 同步查询 users 信息的过程，这里需要替换为 App 的 API 同步查询
    [[LCChatKit sharedInstance] setFetchProfilesBlock:^(NSArray<NSString *> *userIds, LCCKFetchProfilesCompletionHandler completionHandler) {
        if (userIds.count == 0) {
            NSInteger code = 0;
            NSString *errorReasonText = @"User ids is nil";
            NSDictionary *errorInfo = @{
                                        @"code" : @(code),
                                        NSLocalizedDescriptionKey : errorReasonText,
                                        };
            NSError *error = [NSError errorWithDomain:@"LCChatKitExample"
                                                 code:code
                                             userInfo:errorInfo];
            !completionHandler ?: completionHandler(nil, error);
            return;
        }
        
        NSMutableArray *users = [NSMutableArray arrayWithCapacity:userIds.count];
#warning 注意：以下方法循环模拟了通过 userIds 同步查询 users 信息的过程，这里需要替换为 App 的 API 同步查询
        
        [userIds enumerateObjectsUsingBlock:^(NSString * _Nonnull clientId, NSUInteger idx, BOOL * _Nonnull stop) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"peerId like %@", clientId ];
            NSArray *searchedUsers = [LCCKContactProfiles filteredArrayUsingPredicate:predicate];
            if (searchedUsers.count > 0) {
                NSDictionary *user = searchedUsers[0];
                NSURL *avatarURL = [NSURL URLWithString:user[LCCKProfileKeyAvatarURL]];
                LCCKUser *user_ = [LCCKUser userWithUserId:user[LCCKProfileKeyPeerId]
                                                      name:user[LCCKProfileKeyName]
                                                 avatarURL:avatarURL
                                                  clientId:clientId];
                [users addObject:user_];
            } else {
                //注意：如果网络请求失败，请至少提供 ClientId！
                LCCKUser *user_ = [LCCKUser userWithClientId:clientId];
                [users addObject:user_];
            }
        }];
        // 模拟网络延时，3秒
        // sleep(3);

#warning 重要：completionHandler 这个 Bock 必须执行，需要在你**获取到用户信息结束**后，将信息传给该Block！
        !completionHandler ?: completionHandler([users copy], nil);
    }];

 ```

 对这个方法有疑惑，可以到这个 [issue](https://github.com/leancloud/ChatKit-OC/issues/17) 里讨论。
 
注意: **设置头像和昵称的这种方式是被动的，即 ChatKit 需要显示某个Person的头像和昵称时，才会回调这个 block 来获取。而不是您主动地将哪个用户的 Profile 设置到 ChatKit 中。请务必理解这一点。**

###  ClientId 与 UserId


这里最重要的一个概念是 ClientId ，具体含义的请参考  [《实时通信服务总览-核心概念》](https://leancloud.cn/docs/realtime_v2.html#核心概念) 。

这里阐述下 ClientId 与 UserId 的关系：

 ChatKit 与服务端进行数据交互时只会使用 ClientId，但界面展示则需要用到 App 已有用户系统的 User 信息，这时候 ChatKit 就会回调 `FetchProfilesBlock` 来获取用户信息，当然主要是获取 头像和用户名。

比如上面的代码中 userIds 这个就是 ClientIds，但 LCCKProfileKeyPeerId 这个就是 App 已有用户系统的UserId。除了 LCCKUserDelegate 中的 userId，其余在 ChatKit 接口中定义的 UserId 、PeerId 均是 ClientId（如果确定是对方，不是自己，比如好友列表、进行对话的对象，就会使用 PeerId 代替UserId），建议将 App 已有的用户系统中的 UserId 直接设置为 ClientId，如果 UserId 与 ClientId 不相等，那么就需要在上面的 `-setFetchProfilesBlock:` 方法中添加 clientIds 转换为 userIds 的步骤，然后再拿 userIds 去调用 App 已有的 API 来进行查询。

## Profile缓存

当 ChatKit 成功获取到用户的头像和昵称后，会将 Profile 缓存到内存中，关于 Profile 缓存（暂时未作本地缓存，相关讨论见 [issue](https://github.com/leancloud/ChatKit-OC/issues/28)），如果用户修改了自己的头像和昵称，开发者应该调用下面 ChatKit 的缓存清理接口，让 ChatKit 获取新的 Profile:

 ```Objective-C
- (void)removeCachedProfileForPeerId:(NSString *)peerId;
- (void)removeAllCachedProfiles;
 ```

## 聊天页面头像点击事件

可以通过设置 `-[LCChatKit setOpenProfileBlock]` 来处理用户点击会话列表中头像的事件:

用法如下：

 ```Objective-C
    [[LCChatKit sharedInstance] setOpenProfileBlock:^(NSString *userId, id<LCCKUserDelegate> user, __kindof UIViewController *parentController) {
        if (!userId) {
            [LCCKUtil showNotificationWithTitle:@"用户不存在" subtitle:nil type:LCCKMessageNotificationTypeError];
            return;
        }
        [self exampleOpenProfileForUser:user userId:userId parentController:parentController];
    }];
    
    - (void)exampleOpenProfileForUser:(id<LCCKUserDelegate>)user userId:(NSString *)userId parentController:(__kindof UIViewController *)parentController {
    // 可以根据会话类型，做不同的处理
    NSString *currentClientId = [LCChatKit sharedInstance].clientId;
    NSString *title = [NSString stringWithFormat:@"打开用户主页 \nClientId是 : %@", userId];
    NSString *subtitle = [NSString stringWithFormat:@"name是 : %@", user.name];
    if ([userId isEqualToString:currentClientId]) {
        title = [NSString stringWithFormat:@"打开自己的主页 \nClientId是 : %@", userId];
        subtitle = [NSString stringWithFormat:@"我自己的name是 : %@", user.name];
    } else if ([parentController isKindOfClass:[LCCKConversationViewController class]] ) {
            LCCKConversationViewController *conversationViewController_ = [[LCCKConversationViewController alloc] initWithPeerId:user.clientId ?: userId];
            [[self class] pushToViewController:conversationViewController_];
            return;
    }
    [LCCKUtil showNotificationWithTitle:title subtitle:subtitle type:LCCKMessageNotificationTypeMessage];
}

 ```
 
 
## 自定义会话列表左滑菜单

会话列表会话节点的 cell 默认支持的左滑菜单为删除，可以通过 `-[LCChatKit setConversationEditActionBlock:]` 来实现自定义功能，Demo中演示了如何添加一个标记未读的左滑菜单。详情见 Demo。


## 自定义长按菜单

聊天页面的气泡，默认支持长按复制， 你可以通过 `[LCChatKit setLongPressMessageBlock:]` 来自定义添加功能，Demo 中演示了如何添加长按转发消息的功能。详情见Demo。


## 自定义消息

自定义消息分几种：

最简单的一种是：

### 不需要显示自定义 Cell 的消息

也即[暂态消息](https://leancloud.cn/docs/realtime_guide-ios.html#暂态消息) ，且不需要显示自定义 Cell 的自定义消息。

请自行监听 `LCCKNotificationCustomTransientMessageReceived` 通知，自行处理响应事件。

这里注意，非暂态自定义消息也会走这个通知，所以监听该通知时务必检查 Message 的类型，进行筛选。

比如直播聊天室的弹幕消息、点赞出心这种暂态消息，不会存在聊天记录里，也不会有离线通知。

发送消息接口：


 ```Objective-C
 //  LCCKConversationViewController.h
/*!
 * 自定义消息位置发送
 */
- (void)sendCustomMessage:(AVIMTypedMessage *)customMessage;

/*!
 * 自定义消息位置发送
 */
- (void)sendCustomMessage:(AVIMTypedMessage *)customMessage
            progressBlock:(AVProgressBlock)progressBlock
                  success:(LCCKBooleanResultBlock)success
                   failed:(LCCKBooleanResultBlock)failed;
 ```


### 需要显示自定义 Cell 的消息

这里以 Demo 里的 VCard 名片消息为例：

效果如下，ChatKit 默认实现是不支持这种消息类型，需要自定义：

![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160816/14/17338872420160816144930053.png?414x736_130)


## 自定义消息步骤

### 自定义消息

 [《iOS 实时通信开发指南》](https://leancloud.cn/docs/realtime_guide-ios.html#消息) 里面详细介绍了自定义消息的步骤。
 
 这里再介绍下 Demo 里的 VCard 消息的自定义过程：
 
定义一个`LCCKVCardMessage` 自定义消息，继承 `AVIMTypedMessage` ，并遵循、实现 `AVIMTypedMessageSubclassing` 协议：

 ```Objective-C
#pragma mark -
#pragma mark - Override Methods

#pragma mark -
#pragma mark - AVIMTypedMessageSubclassing Method

+ (void)load {
    [self registerSubclass];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeVCard;
}

 ```


在初始化自定义消息时，需要注意，务必添加三个字段，ChatKit 内部会使用到。

字段名 | 作用 | 备注
-------------|-------------|-------------
degrade | 用来定义如何展示老版本未支持的自定义消息类型  | 添加到自定义消息的 attributes 字典属性下
typeTitle | 最近对话列表中最近一条消息的title，</p>比如：最近一条消息是图片，可设置该字段内容为：`@"图片"`，相应会展示：`[图片]`） | 添加到自定义消息的 attributes 字典属性下
summary | 用来显示在push提示中  | 添加到自定义消息的 attributes 字典属性下，</p>另外，这个字段是为了方便自定义推送内容，这需要借助云引擎实现。
conversationType | 用来显示在push提示中 |  添加到自定义消息的 attributes 字典属性下,</p>对话类型，用来展示在推送提示中，以达到这样的效果： [群消息]Tom：hello gays!</p> 以枚举 LCCKConversationType 定义为准，0为单聊，1为群聊
以上三个字段需要添加到自定义消息的 attributes 字典属性下，ChatKit 给出了一个方法来方便添加 `-lcck_setObject:forKey:` ，用法如下：


 ```Objective-C
/*!
 * 有几个必须添加的字段：
 *  - degrade 用来定义如何展示老版本未支持的自定义消息类型
 *  - typeTitle 最近对话列表中最近一条消息的title，比如：最近一条消息是图片，可设置该字段内容为：`@"图片"`，相应会展示：`[图片]`。
 *  - summary 会显示在 push 提示中
 * @attention 务必添加这三个字段，ChatKit 内部会使用到。
 */
- (instancetype)initWithClientId:(NSString *)clientId {
    self = [super init];
    if (!self) {
        return nil;
    }
    [self lcck_setObject:@"名片" forKey:LCCKCustomMessageTypeTitleKey];
    [self lcck_setObject:@"这是一条名片消息，当前版本过低无法显示，请尝试升级APP查看" forKey:LCCKCustomMessageDegradeKey];
    [self lcck_setObject:@"有人向您发送了一条名片消息，请打开APP查看" forKey:LCCKCustomMessageSummaryKey];
    [self lcck_setObject:clientId forKey:@"clientId"];
    return self;
}
 ```



### 自定义消息 Cell

继承 `LCCKChatMessageCell` ，并遵循、实现 `LCCKChatMessageCellSubclassing` 协议，重载父类方法:

这里注意 `+classMediaType` 返回的类型与自定义消息里返回的类型一致：


 ```Objective-C
#pragma mark -
#pragma mark - LCCKChatMessageCellSubclassing Method

+ (void)load {
    [self registerCustomMessageCell];
}

+ (AVIMMessageMediaType)classMediaType {
    return kAVIMMessageMediaTypeVCard;
}
 ```

重写父类的下列方法：


 ```Objective-C
- (void)setup;
- (void)configureCellWithData:(AVIMTypedMessage *)message;
 ```

布局在 `-setup`方法中进行，默认不添加头像，昵称等，如需添加需要调用`addSubview` 方法，如果添加了，就会参与约束，约束在父类的 `-setup` 方法中已经实现。

  推荐使用 AutoLayout 进行布局，如果你在布局中对 `self.contentView` 进行了合理的约束，ChatKit 将自定计算 Cell 高度。如果你没有对 `self.contentView`
进行约束，那么你需要额外提供 Cell 的 Size 数据：

 - Auto layout 布局请请重载 `-systemLayoutSizeFittingSize:`
 - Frame layout 布局请重载 `-sizeThatFits:`

比如：

 ```Objective-C
- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(size.width, A+B+C+D+E+....);
}
 ```


具体用法请参考[文档](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell)。

Demo 中的用法如下：

 ```Objective-C
#pragma mark -
#pragma mark - Override Methods

- (void)setup {
    [self.vCardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).with.insets(UIEdgeInsetsMake(LCCK_MSG_SPACE_TOP, LCCK_MSG_SPACE_LEFT, LCCK_MSG_SPACE_BTM, LCCK_MSG_SPACE_RIGHT));
    }];
    [self updateConstraintsIfNeeded];
    [super setup];
}

- (void)configureCellWithData:(AVIMTypedMessage *)message {
    [super configureCellWithData:message];
    NSString *clientId;
    NSString *name = nil;
    NSURL *avatarURL = nil;
    clientId = [message.attributes valueForKey:@"clientId"];
    [[LCChatKit sharedInstance] getCachedProfileIfExists:clientId name:&name avatarURL:&avatarURL error:nil];
    if (!name) {
        name = clientId;
    }
    if (!name) {
        name = @"未知用户";
    }
    
    [self.vCardView configureWithAvatarURL:avatarURL title:name clientId:clientId];
}

 ```
 
 自定义 Cell 的点击事件，请在自定义 Cell 中自行定义、响应，Demo中采用了添加 Tap 手势的方式。


### 自定义输入框插件
用法与自定义消息和自定义 Cell 类似：
继承 `LCCKInputViewPlugin` ，遵循、实现 `LCCKInputViewPluginSubclassing` 协议，

 ```Objective-C
#pragma mark -
#pragma mark - LCCKInputViewPluginSubclassing Method

+ (void)load {
    [self registerCustomInputViewPlugin];
}

+ (LCCKInputViewPluginType)classPluginType {
    return LCCKInputViewPluginTypeVCard;
}

 ```

UI自定义，需要实现 `LCCKInputViewPluginDelegate` 方法：


 ```Objective-C
#pragma mark -
#pragma mark - LCCKInputViewPluginDelegate Method

/**
 * 插件图标
 */
- (UIImage *)pluginIconImage {
    return [self imageInBundlePathForImageName:@"chat_bar_icons_location"];
}

/**
 * 插件名称
 */
- (NSString *)pluginTitle {
    return @"名片";
}

/**
 * 插件对应的 view，会被加载到 inputView 上
 */
- (UIView *)pluginContentView {
    return nil;
}

/**
 * 插件被选中运行
 */
- (void)pluginDidClicked {
    [super pluginDidClicked];
    [self presentSelectMemberViewController];
}

/**
 * 发送自定消息的实现
 */
- (LCCKIdResultBlock)sendCustomMessageHandler {
    if (_sendCustomMessageHandler) {
        return _sendCustomMessageHandler;
    }
    LCCKIdResultBlock sendCustomMessageHandler = ^(id object, NSError *error) {
        LCCKVCardMessage *vCardMessage = [LCCKVCardMessage vCardMessageWithClientId:object];
        [self.conversationViewController sendCustomMessage:vCardMessage progressBlock:^(NSInteger percentDone) {
        } success:^(BOOL succeeded, NSError *error) {
            [self.conversationViewController sendLocalFeedbackTextMessge:@"名片发送成功"];
        } failed:^(BOOL succeeded, NSError *error) {
            [self.conversationViewController sendLocalFeedbackTextMessge:@"名片发送失败"];
        }];
        //important: avoid retain cycle!
        _sendCustomMessageHandler = nil;
    };
    _sendCustomMessageHandler = sendCustomMessageHandler;
    return sendCustomMessageHandler;
}
 ```
 
 这里注意在 `-sendCustomMessageHandler` 定义时记得在 Block 执行结束时，执行 `_sendCustomMessageHandler = nil;` ，避免循环引用。

插件的排序问题：

排序优先级规则：

 - 负数（默认插件）> 正数（自定义插件）
 - 绝对值小 > 绝对值大

如果 type 分别有：－1、－2、－3、1、2、3，那么 ChatKit 会将它们排序为－1、－2、－3、1、2、3。默认插件只能从 -1 开始连续递增，自定义 type 时只能从 1 连续递增。在选取使用默认插件时，如发现无法保证从 -1 开始时，请选择使用自定义插件来完成对应功能。


### 删除自定义插件、自定义消息、自定义 Cell 

如果需要删除插件，比如 Demo 中自定义了一个名片插件，如果想删除掉，只需要删除 LCCKInputViewPluginVCard 类中的如下代码，当然删除整个类也是能达到该效果的：


 ```Objective-C
+ (void)load {
    [self registerCustomInputViewPlugin];
}
 ```

并且由于 VCard 被删除，那么自定义插件的 type 值也会跟着中断、不连续，比如demo中 VCard 的 type 值是 1， 

删除前是：－1、－2、－3、1、2、3，然后变成了 －1、－2、－3、2、3，不连续了，你需要重新调整 type 的定义，使 type 重新连续，将之前的 2 变为 1 ，3 变为 2，确保 type 是从 1 开始连续递增。详情见 [issue 讨论：删除插件后程序crash](https://github.com/leancloud/ChatKit-OC/issues/49#issuecomment-243652387) 。

另外因为一个插件往往搭配一个自定义 Cell 和自定义消息，这个也需要一并删除：

删除自定义消息：

`LCCKVCardMessage` 类中的：

 ```Objective-C
+ (void)load {
    [self registerSubclass];
}
 ```

删除自定义 Cell ：

`LCCKVCardMessageCell` 类中的：

 ```Objective-C
+ (void)load {
    [self registerCustomMessageCell];
}
 ```

同理删除掉对应的类，也可以达到删除效果。

## 国际化与本地化

 ChatKit 目前已在核心流程（聊天、对话列表话及相关页面）中支持国际化，开发者可以通过非常少的工作量来支持本地化，只需要自定义 Other.bundle 为 CustomizedChatKitOther.bundle，并修改或增加其中的本地化文件即可。

这个文件在每次 ChatKit 版本发布时是增量更新的，新增的内容置于文件的末尾并有时间注释，保证开发者可以迅速定位新增键值对。

## 其他事件及属性

### 监听并筛选或处理消息

可以通过接口 `-[LCChatKit setFilterMessagesBlock:]` 实现拦截新消息，包括实时接收的消息，和拉取历史记录消息。

Demo中演示了，群定向消息的实现： 


LCCKVCardMessage类：


 ```Objective-C
- (instancetype)initWithClientId:(NSString *)clientId  conversationType:(LCCKConversationType)conversationType {
    self = [super init];
    if (!self) {
        return nil;
    }
    [self lcck_setObject:@"名片" forKey:LCCKCustomMessageTypeTitleKey];
    [self lcck_setObject:@"这是一条名片消息，当前版本过低无法显示，请尝试升级APP查看" forKey:LCCKCustomMessageDegradeKey];
    [self lcck_setObject:@"有人向您发送了一条名片消息，请打开APP查看" forKey:LCCKCustomMessageSummaryKey];
    [self lcck_setObject:@(conversationType) forKey:LCCKCustomMessageConversationTypeKey];
    [self lcck_setObject:clientId forKey:@"clientId"];
    //定向群消息，仅部分用户可见，需要实现 `-setFilterMessagesBlock:`, 详情见 LCChatKitExample 中的演示
   [self lcck_setObject:@[ @"Tom", @"Jerry"] forKey:LCCKCustomMessageOnlyVisiableForPartClientIds];
    return self;
}
 ```

LCChatKitExample 类:

 ```Objective-C
    [[LCChatKit sharedInstance] setFilterMessagesBlock:^(AVIMConversation *conversation, NSArray<AVIMTypedMessage *> *messages, LCCKFilterMessagesCompletionHandler completionHandler) {
        if (conversation.lcck_type == LCCKConversationTypeSingle) {
            completionHandler(messages ,nil);
            return;
        }
        //群聊
        NSMutableArray *filterMessages = [NSMutableArray arrayWithCapacity:messages.count];
        for (AVIMTypedMessage *typedMessage in messages) {
            if ([typedMessage.clientId isEqualToString:[LCChatKit sharedInstance].clientId]) {
                [filterMessages addObject:typedMessage];
                continue;
            }
            NSArray *visiableForPartClientIds = [typedMessage.attributes valueForKey:LCCKCustomMessageOnlyVisiableForPartClientIds];
            if (!visiableForPartClientIds) {
                [filterMessages addObject:typedMessage];
            } else if (visiableForPartClientIds.count > 0) {
                BOOL visiableForCurrentClientId = [visiableForPartClientIds containsObject:[LCChatKit sharedInstance].clientId];
                if (visiableForCurrentClientId) {
                    [filterMessages addObject:typedMessage];
                } else {
                    typedMessage.text = @"这是群定向消息，仅部分群成员可见";
                    typedMessage.mediaType = kAVIMMessageMediaTypeText;
                    [filterMessages addObject:typedMessage];
                }
            }
        }
        completionHandler([filterMessages copy] ,nil);
    }];

 ```


### 预览大图

默认的显示的方式是类似微信的消息，如果想自定义，可以通过下面的方式：


 ```Objective-C
    //    替换默认预览图片的样式
    [[LCChatKit sharedInstance] setPreviewImageMessageBlock:^(NSUInteger index, NSArray *allVisibleImages, NSArray *allVisibleThumbs, NSDictionary *userInfo) {
        [self examplePreviewImageMessageWithInitialIndex:index allVisibleImages:allVisibleImages allVisibleThumbs:allVisibleThumbs];
    }];
 ```


#### 预览地理位置

通过设置 `[LCChatKit setPreviewLocationMessageBlock:]` 实现：

 ```Objective-C
  [[LCChatKit sharedInstance] setPreviewLocationMessageBlock:^(CLLocation *location, NSString *geolocations, NSDictionary *userInfo) {
        [self examplePreViewLocationMessageWithLocation:location geolocations:geolocations];
    }];
 ```

### 消息未读数

chatKit 默认会为 TabBar 样式设置未读消息数，如果不是 TabBar 样式，请实现该 Blcok 来设置 Badge 红标：


 ```Objective-C
    //    如果不是TabBar样式，请实现该 Blcok 来设置 Badge 红标。
    [[LCChatKit sharedInstance] setMarkBadgeWithTotalUnreadCountBlock:^(NSInteger totalUnreadCount, UIViewController *controller) {
        [self exampleMarkBadgeWithTotalUnreadCount:totalUnreadCount controller:controller];
    }];
 ```

### 设置单点登录与强制重连

单点登录被踢下线或者点击聊天界面顶端的重连红条，ChatKit会去执行 `ForceReconnectSessionBlock`，你需要设置好 `[LCChatKit setForceReconnectSessionBlock:]` 来让ChatKit执行重连逻辑。

ChatKit会默认开启单点登录，如果需要关闭，需要设置 `[LCChatKit setDisableSingleSignOn:]`。



