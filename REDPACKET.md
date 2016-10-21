# ChatKit 红包快速入门 · iOS


## 导航

 1. 集成红包 SDK

    1.1 [源码集成](https://github.com/leancloud/ChatKit-OC/blob/master/REDPACKET.md#源码集成)

    1.2 [CocoaPods导入](https://github.com/leancloud/ChatKit-OC/blob/master/REDPACKET.md#cocoapods导入)
 2. [集成红包功能](https://github.com/leancloud/ChatKit-OC/blob/master/REDPACKET.md#集成红包功能) 
 3. [设置红包信息](https://github.com/leancloud/ChatKit-OC/blob/master/REDPACKET.md#设置红包信息) 
 4. [在聊天对话中添加红包支持](https://github.com/leancloud/ChatKit-OC/blob/master/REDPACKET.md#在聊天对话中添加红包支持) 
    
## 源码集成

 1. [下载最新的红包 SDK 库文件](https://github.com/leancloud/ChatKit-OC/blob/master/REDPACKET.md#下载最新的支付宝SDK库文件) 
 2. [下载最新的支付宝 SDK 库文件](https://github.com/leancloud/ChatKit-OC/blob/master/REDPACKET.md#下载最新的支付宝SDK库文件) 


## CocoaPods导入
在文件 `Podfile` 中加入以下内容：

```shell
pod 'RedpacketLib'
```

然后使用 CocoaPods 进行安装。如果尚未安装 CocoaPods，运行以下命令进行安装：

```shell
gem install cocoapods
```

安装成功后就可以安装依赖了。建议使用如下方式：

```shell
 # 禁止升级 CocoaPods 的 spec 仓库，否则会卡在 Analyzing dependencies，非常慢
 pod update --verbose --no-repo-update
```

如果提示找不到库，则可去掉 `--no-repo-update`。

如果不想使用 CocoaPods 进行集成，也可以选择使用源码集成 [红包-sdk-库文件](https://www.yunzhanghu.com/download.html#手动集成)。[支付宝-sdk-库文件](https://doc.open.alipay.com/doc2/detail.htm?spm=a219a.7629140.0.0.CeDJVo&treeId=54&articleId=104509&docType=1#手动集成)。


效果图：

- | - | -
-------------|-------------|-------------
![](http://ww1.sinaimg.cn/large/7853084cjw1f7ynh6lno3j20bi0kg0ug.jpg) | ![](http://ww3.sinaimg.cn/large/7853084cjw1f7ynh6q4p8j20bi0kgdgm.jpg) | ![](http://ww3.sinaimg.cn/large/7853084cjw1f7ynh6nodqj20bi0kgdgl.jpg) 
![](http://ww4.sinaimg.cn/large/7853084cjw1f7ynh6hcqlj20bi0kg74x.jpg) | ![](http://ww1.sinaimg.cn/large/7853084cjw1f7ynh6fj58j20bi0kgab8.jpg) | ![](http://ww1.sinaimg.cn/large/7853084cjw1f7ynh6be0lj20bi0kg75n.jpg)
 
<span id = "redpacket"></span>
## 下载最新的红包SDK库文件

ChatKit 默认已经添加了红包 SDK，因为红包 SDK 在一直更新维护，所以如果想获取更新过的 SDK ，可前往[这里](https://www.yunzhanghu.com/download.html)下载 zip 包。

  解压后将 RedpacketStaticLib 复制替换至 ChatKit-OC 对应目录下。

## 下载最新的支付宝SDK库文件
ChatKit 同样也默认集成了一个支付宝 SDK，如想更新，请前往[支付宝对应页面](https://doc.open.alipay.com/doc2/detail.htm?spm=a219a.7629140.0.0.CeDJVo&treeId=54&articleId=104509&docType=1)下载最新版本。

## 集成红包功能
ChatKit Demo中已经默认集成了红包功能，Demo 的做法如下：

需要实现的对应几个API：

 自定义项 | 公开API | 备注
 -------------|-------------|-------------
 自定义消息 | 2 | `-registerSubclass`、 `+classMediaType`
 自定义Cell | 4 | `-registerCustomMessageCell`、`+classMediaType`、`-setup`、 `-configureCellWithData:`
 
 自定义插件 | 6 | `-registerCustomInputViewPlugin`、`+classPluginType`、`-pluginIconImage`、`-pluginTitle`、`-pluginDidClicked`、`sendCustomMessageHandler`

在 Appdelegate 中写入以下方法


    // NOTE: 9.0之前使用的API接口
    - (BOOL)application:(UIApplication *)application
                openURL:(NSURL *)url
      sourceApplication:(NSString *)sourceApplication
             annotation:(id)annotation {

        return YES;
    }
    
    // NOTE: 9.0以后使用新API接口
    - (BOOL)application:(UIApplication *)app
                openURL:(NSURL *)url
                options:(NSDictionary<NSString*, id> *)options
    {
        return YES;
    }
    - (void)applicationDidBecomeActive:(UIApplication *)application {
    }


### 设置红包信息


    #pragma mark - 配置红包信息GIT

    [RedpacketConfig configRedpacket];
    执行 `红包 SDK` 的信息注册

### 设置支付宝URLScheme,需在info.plist中设置URL Types。同时保持一致传入红包设置中。方便用支付宝发送红包。

    [[YZHRedpacketBridge sharedBridge] setRedacketURLScheme:@"redpacket.chatkit"];
    

如对注册信息有其他要求,请自行参考 `RedpacketConfig` 实现和`YZHRedpacketBridge` 所提供API

demo 提供两个 Plugin 底部插件.分别是零钱 `RedPacketChangeInputViewPlugin` 和发红包`RedPacketInputViewPlugin`。

![](http://ww1.sinaimg.cn/large/7853084cjw1f7ynh6lno3j20bi0kg0ug.jpg) 

如要修改零钱页面入口请查看`RedPacketChangeInputViewPlugin`类

### 在聊天对话中添加红包支持
查看 `RedPacketInputViewPlugin.m` 的源代码注释了解红包功能的。
    
添加的部分包括：

     (1) 设置红包插件界面
     (2) 设置红包功能相关的参数
     (3) 设置红包接收用户信息
     (4) 设置红包 SDK 功能回调
  

IM在使用中有任何问题都可以到[我们的官方论坛](https://forum.leancloud.cn/)提问题，或添加红包 SDK 的技术支持QQ：472624215。会有专业工程师回复，平均响应时间在24小时内，