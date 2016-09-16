# ChatKit 红包快速入门 · iOS

1. clone demo:[https://github.com/YunzhanghuOpen/ChatKit-OC.git](https://github.com/YunzhanghuOpen/ChatKit-OC)

2. 下载最新的红包 SDK 库文件 ( master 或者是 release )

  因为`红包 SDK` 在一直更新维护，所以为了不与 demo 产生依赖，所以采取了单独下载 zip 包的策略

  [https://www.yunzhanghu.com/download.html](https://www.yunzhanghu.com/download.html)

  解压后将 RedpacketStaticLib 复制至 ChatKit-OC同级 目录下。

3. 下载支付宝相关SDK并导入.如缺少必须静态库.请参考支付宝添加.
[https://doc.open.alipay.com/doc2/detail.htm?spm=a219a.7629140.0.0.CeDJVo&treeId=54&articleId=104509&docType=1](https://doc.open.alipay.com/doc2/detail.htm?spm=a219a.7629140.0.0.CeDJVo&treeId=54&articleId=104509&docType=1)
在Appdelegate中写入以下方法

    ```objc
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
    ```
4. 设置红包信息
    ```objc
    #pragma mark - 配置红包信息
    [RedpacketConfig configRedpacket];
    执行`红包 SDK` 的信息注册

    如对注册信息有其他要求,请自行参考`RedpacketConfig`实现和`YZHRedpacketBridge`所提供API```

5.demo提供两个Plugin.对应零钱`RedPacketChangeInputViewPlugin`和发红包`RedPacketInputViewPlugin`。如要修改零钱页面入口请查看`RedPacketChangeInputViewPlugin`类

6.在聊天对话中添加红包支持

    1）发送红包事件参考`RedPacketInputViewPlugin`插件
    2) 添加红包功能
    查看 `RedPacketInputViewPlugin.m` 的 源代码注释了解红包功能的。
    添加的部分包括：

       (1) 设置红包插件界面
       (2) 设置红包功能相关的参数
       (3) 设置红包接收用户信息
       (4) 设置红包 SDK 功能回调
  

IM在使用中有任何问题都可以到[我们的官方论坛](https://forum.leancloud.cn/c/jing-xuan-faq)提问题，会有专业工程师回复，平均响应时间在24小时内。
红包在使用中有任何问题可以添加官方开发QQ472624215.进行咨询.平均响应时间在24小时内。