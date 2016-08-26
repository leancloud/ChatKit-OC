# ChatKit 自定义样式

## 导航

  1. [支持自定义区域说明](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#支持自定义区域说明) 
  2. [自定义UI资源包](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#自定义主题图片语音等资源) 
    - [默认UI资源包位置](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#默认UI资源包位置)
    - [自定义 Bundle 命名规则](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#自定义-bundle-命名规则)  
  3. [UI属性配置](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#ui属性配置)
    1.  [TableView](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#tableview) 
    2.  [TableViewCell](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#tableviewcell) 
    3.  [未读数](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#未读数) 
    4.  [聊天背景](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#聊天背景) 
    5.  [输入框](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#输入框) 
    6.  [聊天消息](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#聊天消息) 
    7.  [消息气泡](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#消息气泡) 
  4.  [控制状态栏、导航栏、Tabbar等](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#控制状态栏导航栏tabbar等)  
  5.  [会话列表页面的导航栏标题](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#会话列表页面的导航栏标题) 
  6.  [聊天界面标题自定义](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#聊天界面标题自定义) 
  7.   [HUD 和通知提醒演示自定义](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义样式.md#hud-和通知提醒演示自定义) 


## 支持自定义区域说明

页面	| 位置	| 定制点	| 定制方式
-------------|-------------|-------------|-------------
全局	| 顶部导航栏	| 背景色、文字颜色等样式	| 系统API
全局	| 顶部导航栏	| 导航按钮	| 既可以使用 `-[LCCKBaseViewController configureBarButtonItemStyle:action:]`，</p>又可以在各个Controller的 `setViewDidLoadBlock:` 中调用系统API
全局	| TableView	| 分割线、背景色、Cell文字颜色、Cell背景色等 | 【plist】</p>TableView-XXX </p>	ChatKit-Theme.plist中 </p>**【plist】是指资源包 MessageBubble.bundle 中的 MessageBubble-Customize.plist </p>或者是 Other.bundle 中的 ChatKit-Theme.plist 文件，下同** 
全局 | 核心流程</p>（聊天、对话列表话及相关页面） | 支持国际化 | 自定义 Other.bundle 为 CustomizedChatKitOther.bundle，并修改或增加其中的本地化文件
全局	| 头像样式	| 头像圆角	|  `-[LCChatKit setAvatarImageViewCornerRadiusBlock:]`
全局	| 事件处理 |	预览图片 |	`-[LCChatKit setPreviewImageMessageBlock:]`
全局	| 事件处理 |	点击头像	| `-[LCChatKit setOpenProfileBlock:]`
全局	| 事件处理 | 	提示信息 |	`-[LCChatKit setShowNotificationBlock:`
会话列表 |	未读数	| 文字颜色，背景色|【plist】</p>ConversationList-UnreadText、ConversationList-UnreadBackground
聊天页面	| 聊天背景	| 替换资源包图片 |如果想修改默认的图片，需要替换 Other.bundle</p> `conversationViewController_default_backgroundImage.png` ，</p>如果要修改特定对话，需要调用下面的方法： `-[LCChatKit setCurrentConversationBackgroundImage:scaledToSize:`或</p>`-[LCChatKit setBackgroundImage:forConversationId:scaledToSize:]`
聊天页面	| 输入区域	| 主题色	|【plist】 </p>MessageInputView-Tint-Color
聊天页面	| 输入区域 |	输入区域背景色|	【plist】</p> MessageInputView-BackgroundColor
聊天页面	| 输入区域 |	输入框 |	【plist】</p> MessageInputView-TextField-TextColor、MessageInputView-TextField-BackgroundColor
聊天页面	| 输入区域 |	录音按钮|	【plist】</p>MessageInputView-Record-TextColor 、MessageInputView-RecordView-BackgroundColor
聊天页面 |	输入区域 |	更多区域|【plist】</p>MessageInputView-MorePanel-BackgroundColor、MessageInputView-MorePanel-TextColor
聊天页面 |	输入区域	|更多区域Item |	参考 `LCCKInputViewPluginVCard` 类
聊天页面 | 输入区域	| 自定义表情	| 替换 Emoji.bundle 中的图片资源和 plist 文件
聊天页面 | 自定义消息 |	自定义消息 | 参考 `LCCKVCardMessage` 类、与 `LCCKInputViewPluginVCard` 类
聊天页面 | 消息显示	| 左右文本颜色	|【plist】</p>ConversationView-Message-Left-TextColor、ConversationView-Message-Right-TextColor、
聊天页面 | 消息显示 |	链接颜色 | 【plist】</p>ConversationView-Message-LinkColor、</p>ConversationView-Message-LinkColor-Left、</p>ConversationView-Message-LinkColor-Right
聊天页面 | 消息显示	| 发送者昵称颜色	|【plist】</p> ConversationView-SenderName-TextColor
聊天页面 | 消息显示 |	时间分割线文字颜色	|【plist】</p> ConversationView-TimeLine-TextColor
聊天页面 | 气泡样式	| 气泡背景图等 | MessageBubble.bundle 中的 MessageBubble-Customize.plist，详见下文消息气泡小节

注意： **上表中的【plist】是指资源包 MessageBubble.bundle 中的 MessageBubble-Customize.plist 或者是 Other.bundle 中的 ChatKit-Theme.plist 文件**

注意：上表中列出的参考点，均可以在Demo工程中找到。


## 自定义UI资源包


### 默认UI资源包位置

可以通过如下路径找到资源包，对其中的图片和配置文件等做修改可以直接影响到 UI 页面：

 ```Objective-C
├── ChatKit  ＃核心库文件夹
│   └── Class
│       ├── Model
│       ├── Module
│       ├── Resources  # UI资源包
│       ├── Tool
└── ChatKit-OC  # Demo演示
 ```

注意：**但是我们强烈地建议您不要直接修改此bundle，因为会导致您升级 ChatKit 时难以维护被修改的资源文件。推荐使用自定义皮肤包的方式。**


注意：为了方便升级 ChatKit，强烈建议使用自定义资源包，自定义资源文件时，只需要拷贝遵循命名规则的 Bundle 即可，无需在代码中进行设置。ChatKit 将资源分为了多个 Bundle 文件，自定义时只包含你需要修改的 Bundle 即可，不需要所有 Bundle 都包含。比如如果你只需要自定义聊天气泡，那么你需要如下步骤：

 1. 将 ChatKit 中的 MessageBubble.bundle 拷贝一份到你的本机，比如桌面。
 2. 在桌面中操作该 Bundle，替换其中你要自定义的资源
 3. 将修改后的 Bundle 改名为 CustomizedChatKitMessageBubble.bundle（注意：**要确保文件命名和数量都保持不变**）
 4. 将 CustomizedChatKitMessageBubble.bundle 拖拽到你的工程中（注意：**是拷贝到你自己的项目中，也即 MainBundle 中，并非 ChatKit 中**）

#### 自定义 Bundle 命名规则

ChatKit 提供了默认的 Bundle 文件，如果想自定义对应的 Bundle ，需要在相应的资源 Bunble 前加前缀 CustomizedChatKit，然后拖拽到自己的项目中，详细的对应关系如下：


项目 | 默认名称 | 自定义名称 | 资源类型
-------------|-------------|-------------|-------------
聊天气泡 |MessageBubble.bundle        |CustomizedChatKitMessageBubble.bundle       |  图片
聊天输入框键盘相关 |ChatKeyboard.bundle         |CustomizedChatKitChatKeyboard.bundle        | 图片
表情 |Emoji.bundle                |CustomizedChatKitEmoji.bundle               | 图片、plist描述文件
默认占位图片 |Placeholder.bundle          |CustomizedChatKitPlaceholder.bundle         | 图片
声音相关 |VoiceMessageSource.bundle   |CustomizedChatKitVoiceMessageSource.bundle  | 声音
NavigationBar 左右侧icon |BarButtonIcon.bundle        |CustomizedChatKitBarButtonIcon.bundle       | 图片
其他 |Other.bundle               |CustomizedChatKitOther.bundle              | 任意类型


## UI属性配置

您可以在资源包中找到 ChatKit-Theme.plist 文件，修改某些选项即可定制对应的 UI 


### TableView

影响除聊天页面外的绝大多数 TableView ，以最近对话列表为例：

![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160826/10/17338872420160826100801073.png?717x467_130)

Key | 修改区域
-------------|-------------
TableView-SeparatorColor |分割线颜色
TableView-BackgroundColor | 背景色
TableView-PullRefresh-TextColor| 下拉刷新控件文字颜色
TableView-PullRefresh-BackgroundColor | 下拉刷新控件背景颜色


### TableViewCell

![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160826/10/17338872420160826101226079.png?669x273_130)

Key | 修改区域
-------------|-------------
TableView-CellTitle |标题文字颜色
TableView-CellMinor |附属信息文字颜色
TableView-CellDetail | 内容文字颜色
TableView-CellBackgroundColor | 背景色
TableView-CellBackgroundColor_Highlighted | 高亮背景色

### 未读数

![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160826/10/17338872420160826101138050.png?650x190_130)

Key | 修改区域
-------------|-------------
ConversationList-UnreadText | 会话列表未读数文字颜色
ConversationList-UnreadBackground | 会话列表未读数背景色

### 聊天背景

如果想修改默认的图片，需要替换 Other.bundle `conversationViewController_default_backgroundImage.png` ，如果要修改特定对话，需要调用下面的方法：`-[LCChatKit setCurrentConversationBackgroundImage:scaledToSize:`或`-[LCChatKit setBackgroundImage:forConversationId:scaledToSize:]`


默认背景图 | 修改bundle文件，将修改全部的默认背景图 |代码动态修改可针对特定对话 
-------------|-------------|-------------
![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160825/17/17338872420160825172051075.png?414x736_130) | ![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160825/17/17338872420160825172131044.png?414x736_130) | ![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160825/17/17338872420160825172228061.png)


### 输入框

![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160826/10/1733887242016082610103106.png?808x422_130)

Key | 修改区域
-------------|-------------
MessageInputView-BackgroundColor | 输入区域背景色
MessageInputView-MorePanel-TextColor | 输入框更多面板选项名称文字颜色
MessageInputView-MorePanel-BackgroundColor | 输入框更多面板背景色
MessageInputView-TextField-TextColor | 输入框文字颜色
MessageInputView-TextField-BackgroundColor | 输入框背景色
MessageInputView-Record-TextColor | 录音按钮文字颜色
MessageInputView-Tint-Color | 输入区域主题色，如果没有该项，默认会使用全局主题色

### 聊天消息

![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160826/10/17338872420160826100911064.png?601x542_130)

Key | 修改区域
-------------|-------------
ConversationView-Message-Left-TextColor |左侧文本消息文字颜色
ConversationView-Message-Right-TextColor | 右侧文本消息文字颜色
ConversationView-Message-LinkColor | 消息中链接文字颜色
ConversationView-Message-LinkColor-Left | 左侧消息中链接文字颜色，如果没有该项，则使用统一的消息链接文字颜色
ConversationView-Message-LinkColor-Right | 右侧消息中链接文字颜色，如果没有该项，则使用统一的消息链接文字颜色
ConversationView-SenderName-TextColor | 发送者昵称文字颜色
ConversationView-TimeLine-TextColor | 时间分割线文字颜色
ConversationView-TimeLine-BackgroundColor | 时间分割线背景色

### 消息气泡

资源属性文件

ChatKit 提供了消息气泡定制，你可以再资源包资源包 MessageBubble.bundle 中找到 MessageBubble-Customize.plist：

消息气泡样式配置:

key | 文本、语音等普通气泡样式
-------------|-------------
CommonLeft      | 左侧气泡样式
CommonRight     | 右侧气泡样式

key |  图片、地理位置等气泡中间镂空样式
-------------|-------------
HollowLeft  | 左侧气泡样式
HollowRight | 右侧气泡样式

其中有几个关键字段：

cap_insets : 设置气泡背景的可拉伸区域：

九宫拉伸参数 top、left、bottom、right 的含义如下：

![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160825/18/17338872420160825181346042.png?400x293_130)

以达到如下的拉伸效果：

![enter image description here](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIImage_Class/Art/image_insets_2x.png)

edge_insets: 气泡背景区域（红色）和内容区域（白色）间距：

![enter image description here](http://image18-c.poco.cn/mypoco/myphoto/20160826/10/1733887242016082610152507.png?528x454_130)


## 控制状态栏、导航栏、Tabbar等

ChatKit 提供的各个 Controller 都遵循 LCCKViewControllerEventProtocol 协议，你可以在 controller 的 `-setViewDidLoadBlock:`、`-setViewWillAppearBlock:`、`-setViewDidAppearBlock:`、`-setViewWillDisappearBlock:`、`-setViewDidDisappearBlock:`等 block 中，调用相关的系统API，以便控制状态栏、导航栏、Tabbar等。

例如：


 ```Objective-C
    [conversationViewController setViewWillAppearBlock:^(LCCKBaseViewController *viewController, BOOL aAnimated) {
        [viewController.navigationController setNavigationBarHidden:NO animated:aAnimated];
    }];
 ```
 
 ```Objective-C
    [conversationViewController setViewWillAppearBlock:^(LCCKBaseViewController *viewController, BOOL aAnimated) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:aAnimated];
    }];
 ```
 
## 会话列表页面的导航栏标题

在 LCCKConversationListViewController 的 `setViewDidLoadBlock:` 中修改导航栏标题。

 ```Objective-C
    LCCKConversationListViewController *firstViewController = [[LCCKConversationListViewController alloc] init];
    [firstViewController setViewDidLoadBlock:^(LCCKBaseViewController *viewController) {
        viewController.navigationItem.title = @"消息";
    }];
 ```

## 聊天界面标题自定义

需要禁用标题自动配置。

  默认配置如下：
  
 - 最右侧显示静音状态
 - 单聊默认显示对方昵称，群聊显示 `conversation` 的 name 字段值

 ```Objective-C
    LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithConversationId:conversationId];
    conversationViewController.disableTitleAutoConfig = YES;
    [conversationViewController setViewDidLoadBlock:^(LCCKBaseViewController *viewController) {
        viewController.navigationItem.title = @"消息";
    }];
 ```
 
 
## 头像圆角定义
 
 可以通过下面的方式自定义圆角，支持设置为圆形头像：
 
 ```Objective-C
    [[LCChatKit sharedInstance] setAvatarImageViewCornerRadiusBlock:^CGFloat(CGSize avatarImageViewSize) {
        if (avatarImageViewSize.height > 0) {
            return avatarImageViewSize.height/2;
        }
        return 5;
    }];
 ```



## HUD 和通知提醒演示自定义

通知


 ```Objective-C
    [[LCChatKit sharedInstance] setShowNotificationBlock:^(UIViewController *viewController, NSString *title, NSString *subtitle, LCCKMessageNotificationType type) {
        [self exampleShowNotificationWithTitle:title subtitle:subtitle type:type];
    }];
    
 ```

HUD


 ```Objective-C
    [[LCChatKit sharedInstance] setHUDActionBlock:^(UIViewController *viewController, UIView *view, NSString *title, LCCKMessageHUDActionType type) {
        switch (type) {
            case LCCKMessageHUDActionTypeShow:
                [[self class] lcck_showMessage:title toView:view];
                break;
                
            case LCCKMessageHUDActionTypeHide:
                [[self class] lcck_hideHUDForView:view];
                break;
                
            case LCCKMessageHUDActionTypeError:
                [[self class] lcck_showError:title toView:view];
                break;
                
            case LCCKMessageHUDActionTypeSuccess:
                [[self class] lcck_showSuccess:title toView:view];
                break;
        }
    }];
 ```

