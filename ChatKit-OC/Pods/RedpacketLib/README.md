# 云账户红包SDK接入指南(iOS)
___________
## 导航

  1.[注册红包token](https://github.com/YunzhanghuOpen/RedpacketLib/blob/master/README.md#注册红包)

  2.[发送红包](https://github.com/YunzhanghuOpen/RedpacketLib/blob/master/README.md#发送红包)

  3.[抢红包](https://github.com/YunzhanghuOpen/RedpacketLib/blob/master/README.md#抢红包)

  4.[打开零钱页面](https://github.com/YunzhanghuOpen/RedpacketLib/blob/master/README.md#获取零钱和零钱页面)

  5.[支持支付宝](https://github.com/YunzhanghuOpen/RedpacketLib/blob/master/README.md#支持支付宝)

  6.[可能的错误](https://github.com/YunzhanghuOpen/RedpacketLib/blob/master/README.md#可能的错误)
___

>##  注册红包

### 注册完成后会保存到SDK中， SDK自带错误重试功能，App只负责传入正确的参数。

#### 1. 基于云账户提供的签名机制进行的校验   [云账户REST API文档](http://yunzhanghu-com.oss-cn-qdjbp-a.aliyuncs.com/%E4%BA%91%E8%B4%A6%E6%88%B7%E7%BA%A2%E5%8C%85%E6%8E%A5%E5%8F%A3%E6%96%87%E6%A1%A3-v3_0_1.pdf)

```Objective-C
/**
 *  Method1:通过签名的方式获取Token (以下参数的获取方式见RestAPI集成文档)
 *
 *  @param sign
 *  @param partner
 *  @param appUserid  用户在App的用户ID
 *  @param timeStamp  时间戳
 */
- (void)configWithSign:(NSString *)sign
               partner:(NSString *)partner
             appUserId:(NSString *)appUserid
             timestamp:(NSString *)timestamp;


```

用此方法需要遵循代理

**@protocol:**`YZHRedpacketBridgeDelegate`

```Objective-C

/**
 *  SDK错误处理代理
 *
 *  @param error 错误内容
 *  @param code  错误码
 *  @discussion 通过Sign获取红包Token， 红包Token过期后，直接触发。
 */
- (void)redpacketError:(NSString *)error withErrorCode:(NSInteger)code;

```
#### 2.基于IMToken方式进行的校验

```Objective-C
/**
 *  基于IMToken的校验方式
 *
 *  @param appKey    AppKey,由IM或者云账户提供
 *  @param appUserId 用户在App的用户ID
 *  @param imToken   IM的Token
 */
- (void)configWithAppKey:(NSString *)appKey
               appUserId:(NSString *)appUserId
                 imToken:(NSString *)imToken;
            
```
____
>##  发送红包
### 设置红包发送控制器

```Objective-C

    _viewControl = [[RedpacketViewControl alloc] init];//初始化红包控制器

    _viewControl.conversationController = self;//需要得到当前栈顶的UIViewController
    _viewControl.delegate = self;//设置红包控制器的代理，需要时获取用户信息

    RedpacketUserInfo *conversationInfo = [RedpacketUserInfo new];//初始化红包接收者 
    conversationInfo.userId = #当前对话窗口ID，单聊或群组ID#;
    _viewControl.converstationInfo = conversationInfo;

   [_viewControl setRedpacketGrabBlock:^(RedpacketMessageModel *messageModel) {
        //  抢红包成功后的回调
        
   } andRedpacketBlock:^(RedpacketMessageModel *model) {
        //  发送红包成功后的回调
        
   }];
        
```

### 实现定向红包群组成员列表的代理

**@file:**`RedpacketViewControl.h`

**@protocol:**`RedpacketViewControlDelegate`

```Objective-C
/**
 *  获取定向红包成员列表
 */
- (void)getGroupMemberListCompletionHandle:(void (^)(NSArray<RedpacketUserInfo *> * groupMemberList))completionHandle;

```

### 发红包

```

typedef NS_ENUM(NSInteger,RPSendRedPacketViewControllerType){
    RPSendRedPacketViewControllerSingle, //点对点红包
    RPSendRedPacketViewControllerGroup,  //普通群红包
    RPSendRedPacketViewControllerMember, //包含专属红包的群红包
};

- (void)presentRedPacketViewControllerWithType:(RPSendRedPacketViewControllerType)rpType memberCount:(NSInteger)count;

``` 
_______
>## 抢红包

### 实现获取当前用户信息的代理

**@file:**`YZHRedpacketBridgeProtocol.h`

**@protocol:**`YZHRedpacketBridgeDataSource`

```
/**
 *  获取当前用户的信息，用户ID必须要传
 *
 *  @return 用户信息Info
 */
- (RedpacketUserInfo *)redpacketUserInfo;

```

### 抢红包的方法

```
@class:RedpacketViewControl
[self.viewControl redpacketCellTouchedWithMessageModel:#RedpacketMessageModel#];

```

### RedpacketMessageModel需要传递的参数

```
/**
 *  红包ID
 */
@property (nonatomic, copy) NSString *redpacketId;

/**
 *  红包发送者的头像url，昵称
 */
@property (nonatomic, strong) RedpacketUserInfo *redpacketSender;

```
____
>##  获取零钱和零钱页面

```
@class:RedpacketViewControl
/**
 *  零钱页面
 *
 *  @return 零钱页面，App可以放在需要的位置
 */
+ (UIViewController *)changeMoneyController;

/**
 *  零钱接口返回零钱
 *
 *  @param amount 零钱金额
 */
+ (void)getChangeMoney:(void (^)(NSString *amount))amount;

```

______
>## 支持支付宝
[支付宝集成链接](https://doc.open.alipay.com/doc2/detail.htm?spm=a219a.7629140.0.0.UccR9D&treeId=59&articleId=103676&docType=1)

1. 项目支持支付宝支付，所以请在项目中添加支付宝SDK，和支付宝需要的相关Framework.
   Build Phases中添加支付宝的依赖库**CoreMotion.framework**

2. App Transport Security Settings需要支持支付宝

3. 添加URLScheme回调, 默认为`App的identifier Bundle`， 并通过`RedpacketBridge`中的`redacketURLScheme`传入SDK。

4. 在AppDelegate导入头文件`#import "AlipaySDK.h"`，并监听回调

```Objective-C
 #ifdef REDPACKET_AVALABLE
 #pragma mark - Alipay

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RedpacketAlipayNotifaction object:nil];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    if ([url.host isEqualToString:@"safepay"]) {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RedpacketAlipayNotifaction object:resultDic];
        }];
    }
    return YES;
}

// NOTE: 9.0以后使用新API接口
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<NSString*, id> *)options
{
    if ([url.host isEqualToString:@"safepay"]) {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            [[NSNotificationCenter defaultCenter] postNotificationName:RedpacketAlipayNotifaction object:resultDic];
        }];
    }
    return YES;
}

 #endif

```

__________________
>## 可能的错误

Bulid Settings 中，Other Linker Flags标记
如果没有请加上 -Objc
如果是-force_load，请加上libRedpacket.a的路径地址

* Build Phases中支付宝的依赖库**CoreMotion.framework**是否缺失。

* 参见5，检查支付宝相关配置是否正确。
 [支付宝集成链接](https://doc.open.alipay.com/doc2/detail.htm?spm=a219a.7629140.0.0.UccR9D&treeId=59&articleId=103676&docType=1)

