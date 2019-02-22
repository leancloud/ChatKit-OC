# ChatKit 快速入门 · iOS

<p align="center">
![enter image description here](https://img.shields.io/badge/pod-v0.8.5-brightgreen.svg)  ![enter image description here](https://img.shields.io/badge/platform-iOS%207.0%2B-ff69b5618733984.svg) 
<a href="https://github.com/leancloud/ChatKit-OC/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat"></a>[ CocoaPods-Doc](http://cocoapods.org/pods/ChatKit) 
[![git-brag-stats](https://labs.turbo.run/git-brag?user=leancloud&repo=ChatKit-OC&maxn=7)](https://github.com/turbo/git-brag)

</a>

在使用中有任何问题都可以提 issue，同时也欢迎提 PR。


##  导航
 
 1. [简介](https://github.com/leancloud/ChatKit-OC#简介) 
 2. [获取项目](https://github.com/leancloud/ChatKit-OC#获取项目) 
 2. [集成效果](https://github.com/leancloud/ChatKit-OC#集成效果) 
 3. [项目结构](https://github.com/leancloud/ChatKit-OC#项目结构) 
 4. [使用方法](https://github.com/leancloud/ChatKit-OC#使用方法) 
      1. [CocoaPods 导入](https://github.com/leancloud/ChatKit-OC#cocoapods-导入) 
      2. [快速集成](https://github.com/leancloud/ChatKit-OC#快速集成) 
      3. [最近联系人界面](https://github.com/leancloud/ChatKit-OC#最近联系人界面) 
      4. [由最近联系人进入聊天界面](https://github.com/leancloud/ChatKit-OC#由最近联系人进入聊天界面) 
      4. [聊天界面](https://github.com/leancloud/ChatKit-OC#聊天界面) 
      5. [响应聊天界面的几类操作](https://github.com/leancloud/ChatKit-OC#响应聊天界面的几类操作) 
      5. [手动集成](https://github.com/leancloud/ChatKit-OC#手动集成) 
 8. [常见问题](https://github.com/leancloud/ChatKit-OC#常见问题) 

## 简介

[ChatKit](https://github.com/leancloud/ChatKit-OC) 是一个免费且开源的 UI 聊天组件，自带云服务器，自带推送，支持消息漫游，消息永久存储。底层聊天服务基于 [LeanCloud](https://leancloud.cn/?source=T6M35E4H) 的 IM 即时通讯服务，采用 Protobuf 协议进行消息传输。ChatKit 可以帮助开发者快速集成 IM 服务，轻松实现聊天功能，提供完全自由的授权协议，支持二次开发。其最大特点是把聊天常用的一些功能配合 UI 一起提供给开发者。

ChatKit 只负责演示聊天的核心逻辑，所以不支持自定义消息（如红包、名片等），并且也不支持 UI 定制。

## 获取项目 

```
git clone --depth=1 https://github.com/leancloud/ChatKit-OC
```

## 集成效果

从大量的使用场景来看，「最近联系人列表」和「聊天界面」这两个页面是开发者最常使用的，同时也是比较难处理的。

最近联系人页面实现的难点在于：

- 要根据最近打开的聊天窗口排序联系人列表；
- 对每一个最近聊天人／组需要显示最新的一条消息及时间；
- 需要实时更新未读消息的计数；

而聊天页面的实现难点则在于：

- 消息种类繁多，要有比较好的用户体验，界面以及异步处理方面有大量的开发工作；
- 音视频消息的录制和发送，需要对系统以及 LeanCloud 实时通信 API 比较熟悉；
- 推、拉展示本对话中的最新消息，需要对 LeanCloud 实时通信接口比较熟悉；

最近联系人 | 语音消息，根据语音长度调整宽度 | 图片消息，尺寸自适应 
-------------|-------------|-------------
![enter image description here](http://i63.tinypic.com/1zxqjns.jpg)|![enter image description here](http://i68.tinypic.com/2rx9sfq.jpg)  | ![enter image description here](http://i64.tinypic.com/aw87wl.jpg) 

 地理位置消息| 失败消息本地缓存，可重发 |上传图片，进度条提示 
 -------------|-------------|-------------
![enter image description here](http://i65.tinypic.com/2vmuaf4.jpg) | ![enter image description here](http://i68.tinypic.com/n6b29v.jpg)| ![enter image description here](http://i66.tinypic.com/orrrxh.jpg)

图片消息支持多图联播，支持多种分享 |文本消息支持图文混排| 文本消息支持双击全屏展示 
-------------|-------------|------------
![enter image description here](http://i65.tinypic.com/wmjuvs.jpg) | ![enter image description here](http://i63.tinypic.com/2eoa4j6.jpg) | ![enter image description here](http://i63.tinypic.com/1z1z5ur.jpg)

## 项目结构

```
├── ChatKit  ＃核心库文件夹
│   ├── LCChatKit.h  # 这是整个库的入口，也是中枢，相当于”组件化方案“中的 Mediator。
│   ├── LCChatKit.m
│   └── Class
│       ├── Model
│       ├── Module
│       │   ├── Base
│       │   ├── Conversation
│       │   │   ├── Controller
│       │   │   ├── Model
│       │   │   ├── Tool
│       │   │   └── View
│       │   └── ConversationList
│       │       ├── Controller
│       │       ├── Model
│       │       └── View
│       ├── Resources  # 资源文件，如图片、音频等
│       ├── Tool
│       │   ├── Service
│       │   └── Vendor
│       └── View
└── ChatKit-OC  # Demo演示
    ├── ChatKit-OC.xcodeproj
    └── Example
        └── LCChatKitExample.h  #这是Demo演示的入口类，这个类中提供了很多胶水函数，可完成初步的集成
        └── LCChatKitExample.m
            ├── Model
            ├── Module
            │   ├── ContactList
            │   │   ├── Controller
            │   │   ├── Tool
            │   │   └── View
            │   ├── Login
            │   │   ├── Controller
            │   │   ├── Model
            │   │   └── View
            │   ├── Main
            │   │   ├── Controller
            │   │   └── View
            │   └── Other
```

 从上面可以看出，`ChatKit-OC` 项目包分为两个部分：

* `ChatKit` 是库的核心库文件夹。
* `ChatKit-OC` 为Demo 演示部分，其中 `LCChatKitExample` 这个类提供了很多胶水函数，可完成初步的集成。


## 使用方法

ChatKit 支持以下两种方式导入到您的项目中：

 1. 通过 CocoaPods 管理依赖
 2. 手动集成并管理依赖，参考下文的[手动集成](https://github.com/leancloud/ChatKit-OC#手动集成)部分。

这里推荐通过 CocoaPods 管理依赖

> CocoaPods 是目前最流行的 Cocoa 项目库依赖管理工具之一，考虑到便捷与项目的可维护性，我们更推荐您使用 CocoaPods 导入并管理 SDK。

### CocoaPods 导入

 1. CocoaPods 安装

  如果您的机器上已经安装了 CocoaPods，直接进入下一步即可。

  如果您的网络已经翻墙，在终端中运行如下命令直接安装：

  ```shell
     sudo gem install cocoapods
  ```

  如果您的网络不能翻墙，可以通过淘宝的 RubyGems 镜像 进行安装。

  在终端依次运行以下命令：

  ```shell
     gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
     sudo gem install cocoapods
  ```

 2. 查询 CocoaPods 源中的本库

  在终端中运行以下命令：

  ```shell
     pod search ChatKit
  ```
 
   这里注意，这个命令搜索的是本机上的最新版本，并没有联网查询。如果运行以上命令，没有搜到或者搜不到最新版本，您可以运行以下命令，更新一下您本地的 CocoaPods 源列表。

  ```shell
     pod repo update
  ```
 
 3. 使用 CocoaPods 导入

  打开终端，进入到您的工程目录，执行以下命令，会自动生成一个 Podfile 文件。

  ```shell
     pod init
  ```

  然后使用 CocoaPods 进行安装。如果尚未安装 CocoaPods，运行以下命令进行安装：

 ```shell
    gem install cocoapods
 ```

  打开 Podfile，在您项目的 target 下加入以下内容。（在此以 v0.8.5 版本为例）

  在文件 `Podfile` 中加入以下内容：

 ```shell
    pod 'ChatKit', '0.8.5'
 ```

  然后在终端中运行以下命令：

 ```shell
    pod install
 ```

  或者这个命令：

 ```shell
    # 禁止升级 CocoaPods 的 spec 仓库，否则会卡在 Analyzing dependencies，非常慢
    pod update --verbose --no-repo-update
 ```

  如果提示找不到库，则可去掉 `--no-repo-update`。

  完成后，CocoaPods 会在您的工程根目录下生成一个 `.xcworkspace` 文件。您需要通过此文件打开您的工程，而不是之前的 `.xcodeproj`。

然后在需要的地方导入 ChatKit：

  ```Objective-C
     #import <ChatKit/LCChatKit.h>
  ```


**CocoaPods 使用说明**

**指定 SDK 版本**

CocoaPods 中，有几种设置 SDK 版本的方法。如：

`>= 0.8.5` 会根据您本地的 CocoaPods 源列表，导入不低于 0.8.5 版本的 SDK。
`~> 0.8.5` 会根据您本地的 CocoaPods 源列表，介于 0.7.X~0.8.5 之前版本的 SDK。
我们建议您锁定版本，便于团队开发。如，指定 0.8.5 版本。

 ```shell
pod 'ChatKit', '0.8.5'
 ```

 - 升级本地 CocoaPods 源

  `CocoaPods 有一个中心化的源，默认本地会缓存 CocoaPods 源服务器上的所有 SDK 版本。

 如果搜索的时候没有搜到或者搜不到最新版本，可以执行以下命令更新一下本地的缓存。

 ```shell
pod repo update
 ```
 
 - 升级工程的Pod版本

 更新您工程目录中 Podfile 指定版本后，在终端中执行以下命令。

 ```shell
pod update
 ```


 - 清除 Cocoapods 本地缓存

 特殊情况下，由于网络或者别的原因，通过 CocoaPods 下载的文件可能会有问题。

 这时候您可以删除 CocoaPods 的缓存(~/Library/Caches/CocoaPods/Pods/Release 目录)，再次导入即可。

 - 查看当前使用的 SDK 版本

 您可以在 Podfile.lock 文件中看到您工程中使用的 SDK 版本。

 关于 CocoaPods 的更多内容，您可以参考 [CocoaPods 文档](https://cocoapods.org/)。


### 快速集成

使用 ChatKit 有几个关键性的步骤：

 1. 在 `-[AppDelegate application:didFinishLaunchingWithOptions:]` 中调用 `-[LCChatKit setAppId:appKey:]` 来开启 LeanCloud 服务。需要到
 [LeanCloud](https://leancloud.cn/?source=T6M35E4H) 申请一个 AppId 和一个 AppKey，可以在控制台里创建应用，替换 Demo 中的 AppId 和 AppKey。示例代码如下：
```Objective-C
 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ...
    // 如果APP是在国外使用，开启北美节点
    // 必须在 APPID 初始化之前调用，否则走的是中国节点。
    // [AVOSCloud setServiceRegion:AVServiceRegionUS];
    [LCChatKit  setAppId:LCCKAPPID  appKey:LCCKAPPKEY];
    // 启用未读消息
    [AVIMClient  setUnreadNotificationEnabled:true];

   //添加输入框底部插件，如需更换图标标题，可子类化，然后调用 `+registerSubclass`
   [LCCKInputViewPluginTakePhoto  registerSubclass];
   [LCCKInputViewPluginPickImage  registerSubclass];
   [LCCKInputViewPluginLocation  registerSubclass];
     ...
 }
```
 2. 调用 `-[LCChatKit sharedInstance]` 来初始化一个单例对象。为了让这个库更易入手，避免引入过多公开的类和概念，我们采用了设计模式中的「门面模式」，将你在使用 ChatKit 库时所需要用到的所有方法都放在了 `LCChatKit` 这一个类中。它是一个 Mediator，是整个库的入口。如果不作出特殊说明，下面所说的「调用 API」，调用方都是 `-[LCChatKit sharedInstance]` 。示意图如下：

 ![](http://ww2.sinaimg.cn/large/801b780ajw1f88fhsglsxj20dn08oq3d.jpg)

 3. 实现 `-[[LCChatKit sharedInstance] setFetchProfilesBlock:]`，设置用户体系，里面要实现如何根据 userId 获取到一个 User 对象的逻辑。ChatKit 会在需要用到 User 信息时调用你设置的这个逻辑。更具体的设置方法请参考： [《ChatKit 自定义业务-设置单聊用户的头像和昵称》](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit%20自定义业务.md#设置单聊用户的头像和昵称) 。`LCCKUserSystemService.h` 文件中给出了例子，演示了如何集成 LeanCloud 原生的用户系统 `AVUser`:
```Objective-C
 [[LCChatKit  sharedInstance] setFetchProfilesBlock:^(NSArray<NSString *> *userIds,
 LCCKFetchProfilesCompletionHandler completionHandler) {
 if (userIds.count == 0) {
 NSInteger code = 0;
 NSString *errorReasonText = @"User ids is nil";
 NSDictionary *errorInfo = @{
 @"code":@(code),
 NSLocalizedDescriptionKey : errorReasonText,
 };
  NSError *error = [NSError  errorWithDomain:NSStringFromClass([self  class])
 code:code
 userInfo:errorInfo];
 !completionHandler ?: completionHandler(nil, error);
 return;
 }
  NSMutableArray *users = [NSMutableArray  arrayWithCapacity:userIds.count];
 [userIds enumerateObjectsUsingBlock:^(NSString *_Nonnull clientId, NSUInteger idx,
 BOOL *_Nonnull stop) {
 NSPredicate *predicate = [NSPredicate predicateWithFormat:@"peerId like %@", clientId];
  //这里的LCCKContactProfiles，LCCKProfileKeyPeerId都为事先的宏定义，
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
 LCCKUser *user_ = [LCCKUser userWithClientId:clientId];
 [users addObject:user_];
 }
 }];
 !completionHandler ?: completionHandler([users copy], nil);
 }];
```

 4. 如果你实现了 `-[[LCChatKit sharedInstance] setGenerateSignatureBlock:]` 方法，那么 ChatKit 会自动为以下行为添加签名：`open`（开启聊天）、`start`（创建对话）、`kick`（踢人）、`invite`（邀请）。反之不会。
 5. 调用 `-[[LCChatKit sharedInstance] openWithClientId:callback:]` 开启 LeanCloud 的 IM 服务 LeanMessage，开始聊天。请确保在 open 操作之前已经实现 `-[[LCChatKit sharedInstance] setFetchProfilesBlock:]`，否则 ChatKit 将抛出异常进行提示。
 6. 调用 `-[[LCChatKit sharedInstance] closeWithCallback:]` 关闭 LeanCloud 的 IM 服务，结束聊天。

### 最近联系人界面

主流的社交聊天软件，例如微信和 QQ 都会把最近联系人界面作为登录后的首页，可见其重要性。因此我们在 ChatKit 也提供了对话列表 `LCIMConversationListController` 页面，初始化方法非常简单：

```Objective-C
LCCKConversationListViewController *firstViewController = [[LCCKConversationListViewController alloc] init];
```

因为最近联系人的所有信息都由 ChatKit 内部维护，不需要传入额外数据，所以直接展示这个 ViewController 即可。最近联系人界面的数据，依赖于本地数据库。这些数据会在聊天过程中自动进行更新，你无需进行繁琐的数据库操作。

### 聊天界面

<div class="callout callout-info">ChatKit 中的对话是一个 `AVIMConversation` 对象， LeanMessage
用它来管理对话成员，发送消息，不区分群聊、单聊。Demo 中采用了判断对话人数的方式来区分群聊、单聊。</div>

聊天界面有两种初始化方式：

```Objective-C
// 用于单聊，默认会创建一个只包含两个成员的 unique 对话(如果已经存在则直接进入，不会重复创建)
LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithPeerId:peerId];
```

```Objective-C
// 单聊或群聊，用于已经获取到一个对话基本信息的场合。
LCCKConversationViewController *conversationViewController = [[LCCKConversationViewController alloc] initWithConversationId:conversationId];
```

这里注意，通过 `peerId` 初始化，内部实现时，如果没有一个 unique 对话刚好包含这两个成员，则会先创建一个 unique 对话，所以调用该方法时可能会导致 _Conversation 表中自动增加一条记录。同理，通过 `conversationId` 初始化群聊，内部实现时，如果不是对话成员会先把当前用户加入对话，并开启群聊。

#### 由最近联系人进入聊天界面

按照上面的步骤，我们可以非常方便地打开最近联系人页面。但是我们会发现，点击其中的某个联系人／聊天群组，我们并不能直接进入聊天界面。要做到这一点，我们需要给 LCChatKit 设置上事件响应函数，示例代码如下：

```objective-c
[[LCChatKit sharedInstance] setDidSelectConversationsListCellBlock:^(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller) {
    NSLog(@"conversation selected");
    LCCKConversationViewController *conversationVC = [[LCCKConversationViewController alloc] initWithConversationId:conversation.conversationId];
    [controller.navigationController pushViewController:conversationVC animated:YES];
}];
```

对于联系人列表页面，可以使用 `[LCChatKit sharedInstance]` 来调用如下四种操作接口：


```objective-c
/*!
 *  选中某个对话后的回调 (比较常见的需求)
 *  @param conversation 被选中的对话
 */
typedef void(^LCCKConversationsListDidSelectItemBlock)(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller);
/*!
 *  设置选中某个对话后的回调
 */
- (void)setDidSelectConversationsListCellBlock:(LCCKConversationsListDidSelectItemBlock)didSelectItemBlock;

/*!
 *  删除某个对话后的回调 (一般不需要做处理)
 *  @param conversation 被选中的对话
 */
typedef void(^LCCKConversationsListDidDeleteItemBlock)(NSIndexPath *indexPath, AVIMConversation *conversation, LCCKConversationListViewController *controller);
/*!
 *  设置删除某个对话后的回调
 */
- (void)setDidDeleteConversationsListCellBlock:(LCCKConversationsListDidDeleteItemBlock)didDeleteItemBlock;

/*!
 *  对话左滑菜单设置block (最近联系人页面有复杂的手势操作时，可以通过这里扩展实现)
 *  @return  需要显示的菜单数组
 *  @param conversation, 对话
 *  @param editActions, 默认的菜单数组，成员为 UITableViewRowAction 类型
 */
typedef NSArray *(^LCCKConversationEditActionsBlock)(NSIndexPath *indexPath, NSArray<UITableViewRowAction *> *editActions, AVIMConversation *conversation, LCCKConversationListViewController *controller);
/*!
 *  可以通过这个block设置对话列表中每个对话的左滑菜单，这个是同步调用的，需要尽快返回，否则会卡住UI
 */
- (void)setConversationEditActionBlock:(LCCKConversationEditActionsBlock)conversationEditActionBlock;
```

### 响应聊天界面的几类操作

由于有了 ChatKit 的帮助，聊天界面的初始化和展示非常简单，但是这里面交互上还有很多地方需要自定义扩展。

- 内部异常对话无法创建

如果通过 peerId 打开对话，或者通过 conversationId 打开对话时，网络出现问题或 传入参数有误，那么对话根本无法进行，这时候我们可以通过给 LCCKConversationViewController 设定 conversationHandler 进行处理。示例代码如下：

```objective-c
 [[LCChatKit sharedInstance] setFetchConversationHandler:^(
                                                              AVIMConversation *conversation,
                                                              LCCKConversationViewController *aConversationController) {
    if (!conversation) {
        // 显示错误提示信息
        [conversationController alert:@"failed to create/load conversation."];
    } else {
        // 正常处理
    }
}];
```

这里注意这个 `-setFetchConversationHandler:` 方法无需每次创建 `LCCKConversationViewController` 对象都要设置一遍，只需要设置一次，之后每次创建 `LCCKConversationViewController` 对象都会复用该设置。

- 对话详情页展示

在 QQ／微信之类的聊天应用中，聊天界面右上角会提供一个显示对话详细信息的按钮，点击可以打开对话详情页面，在那里可以进行改名、拉人、踢人、静音等操作。LCCKConversationViewController 中通过调用以下 API 也支持这一功能：

```objective-c
typedef void(^LCCKBarButtonItemActionBlock)(void);

typedef NS_ENUM(NSInteger, LCCKBarButtonItemStyle) {
    LCCKBarButtonItemStyleSetting = 0,
    LCCKBarButtonItemStyleMore,
    LCCKBarButtonItemStyleAdd,
    LCCKBarButtonItemStyleAddFriends,
    LCCKBarButtonItemStyleShare,
    LCCKBarButtonItemStyleSingleProfile,
    LCCKBarButtonItemStyleGroupProfile,
};

- (void)configureBarButtonItemStyle:(LCCKBarButtonItemStyle)style action:(LCCKBarButtonItemActionBlock)action;
```

示例代码如下：

```objective-c
[aConversationController configureBarButtonItemStyle:LCCKBarButtonItemStyleGroupProfile
                                                          action:^(UIBarButtonItem *sender, UIEvent *event) {
    ConversationDetailViewController *detailVC = [[ConversationDetailViewController alloc] init];// 自己实现的对话详情页
    detailVC.conversation = conversation;
    [conversationController.navigationController pushViewController:detailVC animated:YES];
}];
```

### 手动集成

如果你不想使用 CocoaPods 进行集成，也可以选择使用源码集成。步骤如下：

第一步：

将 [项目结构](https://github.com/leancloud/ChatKit-OC#项目结构) 中提到的 ChatKit 这个「核心库文件夹」拖拽到项目中。

第二步：

添加 ChatKit 依赖的第三方库以及对应版本：

- [AVOSCloud](https://github.com/leancloud/objc-sdk) v3.6.1
- [AVOSCloudIM](https://github.com/leancloud/objc-sdk) v3.6.1
- [MJRefresh](https://github.com/CoderMJLee/MJRefresh) 3.1.9
- [Masonry](https://github.com/SnapKit/Masonry) v1.0.1 
- [SDWebImage](https://github.com/rs/SDWebImage) v3.8.0
- [FMDB](https://github.com/ccgus/fmdb) 2.6.2 
- [UITableView+FDTemplateLayoutCell](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell) 1.5.beta

具体以  [这里](https://github.com/leancloud/ChatKit-OC/blob/master/ChatKit.podspec) 为准。

## 常见问题

**ChatKit 组件收费么？**<br/>
ChatKit 是完全开源并且免费给开发者使用，使用聊天所产生的费用以 [这里](https://leancloud.cn/pricing.html) 为准。

**接入 ChatKit 有什么好处？**<br/>
它可以减轻应用或者新功能研发初期的调研成本，直接引入使用即可。ChatKit 从底层到 UI 提供了一整套的聊天解决方案。

**如何兼容 iOS7 ？**<br/>
因为ChatKit中使用了 iOS8 的一个控件：UITableViewRowAction ，所以想要兼容 iOS7 就需要在你的 App 中添加一个 Lib：

 ```Objective-C
pod "CYLTableViewRowAction", "1.0.0"
 ```

Demo 中也是通过这个方式来兼容iOS7的。

如果不使用 Pod，你可以直接下载 [CYLTableViewRowAction](https://github.com/ChenYilong/CYLTableViewRowAction) 将里面的文件夹拖拽到项目中就可以了，不兼容 iOS7 的问题就解决了。

**为什么收不到推送消息 ？**<br/>
问题描述：推送的证书已经配置好，在控制台里测试推送，手机也能接收到，但是另一个好友发送的消息就是接收不到。

这种情况，请先参考 [《iOS 消息推送开发指南》](https://leancloud.cn/docs/ios_push_guide.html) ，如果设置方法正确，再检查下这里是否进行了正确的设置：

比如可以这样设置：

 ```Objective-C
{"alert":"您有新的消息","badge":"Increment"}
 ```

![](http://ww2.sinaimg.cn/large/7853084cjw1f7y0ltdaprj20r20fiacf.jpg)

如果想获取推送的消息内容可以参考  [《 iOS 消息推送 点击app图标 app icon如何获取推送信息 leanCloud 点击app图标 获得推送消息》]( http://blog.csdn.net/zain_/article/details/50440096
 ) 

在使用中有任何问题都可以到[我们的官方论坛](https://forum.leancloud.cn/c/jing-xuan-faq)提问题，会有专业工程师回复，平均响应时间在24小时内。


