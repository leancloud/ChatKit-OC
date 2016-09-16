# ChatKit 红包快速入门 · iOS

## 下载最新的红包 SDK 库文件

ChatKit 默认已经添加了红包SDK，因为红包 SDK 在一直更新维护，所以如果想获取更新过的 SDK ，可前往[这里](https://www.yunzhanghu.com/download.html)下载 zip 包。

  解压后将 RedpacketStaticLib 复制替换至 ChatKit-OC 对应目录下。

## 下载最新的支付宝 SDK 库文件
ChatKit 同样也默认集成了一个支付宝SDK，如想更新，请前往[支付宝对应页面](https://doc.open.alipay.com/doc2/detail.htm?spm=a219a.7629140.0.0.CeDJVo&treeId=54&articleId=104509&docType=1)下载最新版本。

## 集成红包功能

ChatKit Demo中已经默认集成了红包功能，Demo 的做法如下：

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
    执行`红包 SDK` 的信息注册

如对注册信息有其他要求,请自行参考 `RedpacketConfig` 实现和`YZHRedpacketBridge` 所提供API

demo 提供两个 Plugin 底部插件.分别是零钱 `RedPacketChangeInputViewPlugin` 和发红包`RedPacketInputViewPlugin`。

![](http://ww2.sinaimg.cn/large/801b780ajw1f7vg21w5waj20bi0kgtac.jpg)

如要修改零钱页面入口请查看`RedPacketChangeInputViewPlugin`类

### 在聊天对话中添加红包支持

    1）发送红包事件参考 `RedPacketInputViewPlugin` 插件
    2) 添加红包功能
    查看 `RedPacketInputViewPlugin.m` 的源代码注释了解红包功能的。
    添加的部分包括：

       (1) 设置红包插件界面
       (2) 设置红包功能相关的参数
       (3) 设置红包接收用户信息
       (4) 设置红包 SDK 功能回调
  

IM在使用中有任何问题都可以到[我们的官方论坛](https://forum.leancloud.cn/)提问题，或添加红包 SDK 的技术支持QQ：472624215。会有专业工程师回复，平均响应时间在24小时内，