# ChatKit-OC


## 集成效果

最近联系人 | 语音消息，根据语音长度调整宽度 | 图片消息，尺寸自适应 
-------------|-------------|-------------|-------------
![enter image description here](http://i63.tinypic.com/1zxqjns.jpg)|![enter image description here](http://i68.tinypic.com/2rx9sfq.jpg)  | ![enter image description here](http://i64.tinypic.com/aw87wl.jpg) 
 地理位置消息| 失败消息本地缓存，可重发 |上传图片，进度条提示 
![enter image description here](http://i65.tinypic.com/2vmuaf4.jpg) | ![enter image description here](http://i68.tinypic.com/n6b29v.jpg)| ![enter image description here](http://i66.tinypic.com/orrrxh.jpg)
## 项目结构

 ```
├── ChatKit  ＃核心库文件夹，如果不使用 CocoaPods 集成，请直接将这个文件夹拖拽带你的项目中
│   ├── LCChatKit.h  # 这是整个库的入口，也是中枢，相当于”组件化方案“中的 Mediator。
│   ├── LCChatKit.m
│   └── Class
│       ├── Model
│       ├── Module
│       │   ├── Base
│       │   ├── Conversation
│       │   │   ├── Controller
│       │   │   ├── Model
│       │   │   ├── Tool
│       │   │   │   ├── Categories
│       │   │   │   └── DisableImageMemoryCache
│       │   │   └── View
│       │   │       ├── ChatBar
│       │   │       └── ChatMessageCell
│       │   └── ConversationList
│       │       ├── Controller
│       │       ├── Model
│       │       └── View
│       ├── Resources  # 资源文件，如图片、音频等
│       │   ├── BarButtonIcon.bundle
│       │   ├── ChatKeyboard.bundle
│       │   ├── Common.bundle
│       │   ├── DateTools.bundle
│       │   ├── Emoji.bundle
│       │   ├── MBProgressHUD.bundle
│       │   ├── MessageBubble.bundle
│       │   ├── Placeholder.bundle
│       │   ├── VoiceMessageSource.bundle
│       │   └── localization
│       │       ├── en.lproj
│       │       └── zh-Hans.lproj
│       ├── Tool
│       │   ├── Service
│       │   └── Vendor
│       │       ├── DateTools
│       │       ├── LCCKAlertController
│       │       ├── LCCKDeallocBlockExecutor
│       │       ├── LCCKTableViewRowAction
│       │       └── VoiceLib
│       │           └── lame.framework
│       │               └── Headers
│       └── View
└── ChatKit-OC  # Demo演示
    ├── ChatKit-OC.xcodeproj
    ├── Example
    │   └── LCChatKitExample.h  #这是Demo演示的入口类，这个类中提供了很多胶水函数，可完成初步的集成
    │   └── LCChatKitExample.m
    │       ├── Model
    │       ├── Module
    │       │   ├── ContactList
    │       │   │   ├── Controller
    │       │   │   ├── Tool
    │       │   │   └── View
    │       │   ├── Login
    │       │   │   ├── Controller
    │       │   │   ├── Model
    │       │   │   └── View
    │       │   ├── Main
    │       │   │   ├── Controller
    │       │   │   └── View
    │       │   └── Other
 ```
 
 ## 使用 ChatKit
 
 为了让这个库，更易入手，避免引入过多的类，以及概念，我们采用了类似 “组件化” 的思想：将你在使用 ChatKit 库的所需要的所有的方法都放在了这一个类中，类的名字叫做 `LCChatKit`，是一个 Mediator，是整个库的入口，也是中枢。
 
 使用 ChatKit 大体有几个步骤：
 
 1. 在 `-[AppDelegate application:didFinishLaunchingWithOptions:]` 中调用 `-[LCChatKit setAppId:appKey:]`  来开启 LeanCloud 服务。
 2. 调用 `-[LCChatKit sharedInstance]` 来初始化一个单例对象。
 3. 调用 `-[[LCChatKit sharedInstance] openWithClientId:callback:]` 开启 LeanCloud 的 IM 服务 LeanMessage，开始聊天。
 4. 调用 `-[[LCChatKit sharedInstance] closeWithCallback:]` 关闭 LeanCloud 的 IM 服务，结束聊天。
 5. 实现 `-[[LCChatKit sharedInstance] setFetchProfilesBlock:]`, 来让 ChatKit 能通过你的 user id 来获知用户信息. `LCCKUserSystemService.h` 文件中给出了例子，演示了如何集成 LeanCloud 原生的用户系统  AVUser。
 6. 如果你实现了 `-[[LCChatKit sharedInstance] setGenerateSignatureBlock:]` 方法，那么 ChatKit会自动为以下行为添加签名：open（开启会话）, start(创建会话), kick（踢人）, invite（邀请）。
 7. 使用
下面进行下详细的介绍：

### 第一步：使用CocoaPods导入ChatKit

在 `Podfile` 中进行如下导入：

 ```
pod 'ChatKit'
 ```
然后使用 `cocoaPods` 进行安装：

如果尚未安装 CocoaPods, 运行以下命令进行安装:


 ```Objective-C
gem install cocoapods
 ```


安装成功后就可以安装依赖了：

建议使用如下方式：


 ```Objective-C
 # 禁止升级CocoaPods的spec仓库，否则会卡在 Analyzing dependencies ，非常慢 
 pod update --verbose --no-repo-update
 ```
 
如果提示找不到库，则可去掉 --no-repo-update

### 第二步：快速集成

ChatKit提供了一个快速集成的演示类 LCChatKitExample ，路径如下：

 ```Objective-C
 ── ChatKit-OC  # Demo演示
    ├── ChatKit-OC.xcodeproj
    ├── Example
    │   └── LCChatKitExample.h  #这是Demo演示的入口类，这个类中提供了很多胶水函数，可完成初步的集成
    │   └── LCChatKitExample.m
 ```
 
 
 
使用 LCChatKitExample 提供的函数即可完成从程序启动到登录再到登出的完整流程：

在`-[AppDelegate didFinishLaunchingWithOptions:]` 等函数中调用下面这几个基础的入口胶水函数，可完成初步的集成。

进一步地，胶水代码中包含了特地设置的#warning，请仔细阅读这些warning的注释，根据实际情况调整代码，以符合你的需求。

 ```Objective-C

/*!
 *  入口胶水函数：初始化入口函数
 *
 *  程序完成启动，在appdelegate中的 `-[AppDelegate didFinishLaunchingWithOptions:]` 一开始的地方调用.
 */
+ (void)invokeThisMethodInDidFinishLaunching;

/*!
 * Invoke this method in `-[AppDelegate appDelegate:didRegisterForRemoteNotificationsWithDeviceToken:]`.
 */
+ (void)invokeThisMethodInDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/*!
 * invoke This Method In `-[AppDelegate application:didReceiveRemoteNotification:]`
 */
+ (void)invokeThisMethodInApplication:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo ;

/*!
 *  入口胶水函数：登入入口函数
 *
 *  用户即将退出登录时调用
 */
+ (void)invokeThisMethodAfterLoginSuccessWithClientId:(NSString *)clientId success:(LCCKVoidBlock)success failed:(LCCKErrorBlock)failed;

/*!
 *  入口胶水函数：登出入口函数
 *
 *  用户即将退出登录时调用
 */
+ (void)invokeThisMethodBeforeLogoutSuccess:(LCCKVoidBlock)success failed:(LCCKErrorBlock)failed;
+ (void)invokeThisMethodInApplicationWillResignActive:(UIApplication *)application;
+ (void)invokeThisMethodInApplicationWillTerminate:(UIApplication *)application;
 ```

### 配置聊天界面和最近联系人界面

初始化方法非常简单分别是：

 ```Objective-C
LCCKConversationListViewController *firstViewController = [[LCCKConversationListViewController alloc] init];
 ```

聊天界面有两种初始化方式：

 ```Objective-C
// 用于单聊
LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithPeerId:peerId];
 ```

 ```Objective-C
// 单聊或群聊
LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithConversationId:conversationId];

 ```

这里注意，通过PeerId初始化，内部实现时，如果不是好友关系，会先建立好友关系、创建会话，所以调用该方法前请自行判断是否具有好友关系。
同理，通过conversationId初始化群聊，内部实现时，如果不是群成员会先把当前用户加入群，再开始群聊。


### 