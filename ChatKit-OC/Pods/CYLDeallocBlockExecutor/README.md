# CYLDeallocBlockExecutor【你好 block，再见 dealloc】

Hello block，byebye dealloc！一行代码代替dealloc完成“self-manager”


<p align="center">
![pod-v1.0.0](https://img.shields.io/badge/pod-v1.0.0-brightgreen.svg)
![Objective--C-compatible](https://img.shields.io/badge/Objective--C-compatible-orange.svg)   ![platform-iOS-6.0+](https://img.shields.io/badge/platform-iOS%206.0%2B-ff69b4.svg)
</a>



## 导航

  1.  [ 与其他框架的区别 ](https://github.com/ChenYilong/CYLDeallocBlockExecutor#与其他框架的区别) 
  2.  [ 使用CYLDeallocBlockExecutor ](https://github.com/ChenYilong/CYLDeallocBlockExecutor#使用cyldeallocblockexecutor) 
    1.   [第一步：使用cocoaPods导入CYLDeallocBlockExecutor](https://github.com/ChenYilong/CYLDeallocBlockExecutor#第一步使用cocoapods导入CYLDeallocBlockExecutor) 
    2.  [第二步：一行代码搞定](https://github.com/ChenYilong/CYLDeallocBlockExecutor#第二步一行代码搞定) 
    3.  [第三步](https://github.com/ChenYilong/CYLDeallocBlockExecutor#第三步) 
  3.  [ 运行Demo ](https://github.com/ChenYilong/CYLDeallocBlockExecutor#运行demo)
  4.  [应用场景](https://github.com/ChenYilong/CYLDeallocBlockExecutor#应用场景) 
    1.  [管理KVO与NSNotificationCenter的removeObserver操作](https://github.com/ChenYilong/CYLDeallocBlockExecutor#管理kvo与nsnotificationcenter的removeobserver操作) 
    2.   [模拟weak修饰的property的生命周期](https://github.com/ChenYilong/CYLDeallocBlockExecutor#模拟weak修饰的property的生命周期)  
    3.   [更加安全地在 viewDidLoad 里管理应用的生命周期](https://github.com/ChenYilong/CYLDeallocBlockExecutor#更加安全地在viewdidload里管理应用的生命周期) 

## 与其他框架的区别

 -| 特点 |解释
-------------|-------------|-------------
1 | 轻量级、无污染 | 基于 NSObject 分类，无污染，适用于任何 Objective-C 对象，比基于子类化、继承的框架更加轻量级
2 | 高性能 | 使用 runtime 的对象关联（或称为关联引用）技术，随着关联对象的 dealloc，对应的 block 自发执行，性能消耗极低。
3 | 简单，无学习成本 | 一行代码完成，仅需使用  `cyl_executeAtDealloc:`  中的 block 代替  `dealloc` 即可。自动检测对象的 dealloc 的时机，执行 block。
4 | 将分散的代码集中起来 | 你可以使用 [CYLDeallocBlockExecutor](https://github.com/ChenYilong/CYLDeallocBlockExecutor) 将  `KVO`  或 `NSNotificationCenter` 的 `addObserver` 和 `removeObserver`  操作集中放在一个位置，让代码更加直观，易于维护，demo 中也给出了相应的使用方法。
5 |支持CocoaPods |容易集成

（学习交流群：523070828）



## 使用[CYLDeallocBlockExecutor](https://github.com/ChenYilong/CYLDeallocBlockExecutor)

三步完成：

  1.  [ 第一步：使用cocoaPods导入CYLDeallocBlockExecutor ](https://github.com/ChenYilong/CYLDeallocBlockExecutor#第一步使用cocoapods导入CYLDeallocBlockExecutor) 
  2.  [第二步：一行代码搞定](https://github.com/ChenYilong/CYLDeallocBlockExecutor#第二步一行代码搞定) 
  3.  [第三步](https://github.com/ChenYilong/CYLDeallocBlockExecutor#第三步) 


### 第一步：使用CocoaPods导入CYLDeallocBlockExecutor


在 `Podfile` 中进行如下导入：


 ```Objective-C
pod 'CYLDeallocBlockExecutor'
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


 ```Objective-C
pod update
 ```



### 第二步：导入头文件

导入头文件：

 ```Objective-C
#import "CYLDeallocBlockExecutor.h"
 ```

使用方法：

一行代码代替 dealloc：

 ```Objective-C
        [foo cyl_executeAtDealloc:^{
           // do something
        }];
 ```

这里注意：在 `cyl_executeAtDealloc` 的参数 block 中不能使用 weak 修饰符修饰的 self，因为 weak 变量在 dealloc 中会被自定置为 nil。在使用 `cyl_executeAtDealloc` 你需要遵循一个准则：

 > 参数 block 中的内容可以完全放入 dealloc。

因为该 block 就是在 dealloc 执行的时候执行的！


 ```Objective-C
        // NOTE: need to be __unsafe_unretained because __weak var will be reset to nil in dealloc
        __unsafe_unretained typeof(self) weakSelf = self;
        [self cyl_executeAtDealloc:^{
            [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
        }];
 ```


### 第三步

没有第三步！


## 运行Demo

示例 Demo 展示了一个自动换皮肤的功能，

在 demo 中我们使用了 UIView 的一个分类来管理皮肤，并在分类中设置了一个皮肤主题属性，并且使用了通知进行换皮肤操作，所有的 `addObserver` 和 `removeObserver` 操作都在皮肤属性的 setter 方法中实现。


运行好 demo后，请点击设备屏幕，会触发换主题（背景）的事件。


## 应用场景

### 管理KVO与NSNotificationCenter的removeObserver操作

在 `KVO` 、 `NSNotificationCenter` 在 `addObserver` 后，都需要在  `dealloc`  方法中进行 `removeObserver`  操作，一方面代码分散，不易维护，


另一方面如果想在分类中使用 `KVO` 、 `NSNotificationCenter` ，而你又想在  `dealloc`  中进行 `removeObserver` 操作，那应该怎么办？

答：你需要借助 [CYLDeallocBlockExecutor](https://github.com/ChenYilong/CYLDeallocBlockExecutor) ！

Demo 中给出了一个换皮肤的 Demo，演示：

所有的的操作全部都在 Setter 方法中进行，无需借助 Dealloc 方法。

 ```Objective-C
- (void)setThemeMap:(NSDictionary *)themeMap {
    objc_setAssociatedObject(self, &kUIView_ThemeMap, themeMap, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (themeMap) {
        // Need to removeObserver in dealloc
        // NOTE: need to be __unsafe_unretained because __weak var will be reset to nil in dealloc
        __unsafe_unretained typeof(self) weakSelf = self;
        [self cyl_executeAtDealloc:^{
            [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
        }];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kThemeDidChangeNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(themeChanged:)
                                                     name:kThemeDidChangeNotification
                                                   object:nil
         ];
        [self themeChangedWithDict:themeMap];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kThemeDidChangeNotification
                                                      object:nil];
    }
}
 ```

对应的时序图如下所示：


![enter image description here](http://i68.tinypic.com/zx7kgp.jpg)

直接从看图里的第8步骤开始看：
 [CYLDeallocBlockExecutor](https://github.com/ChenYilong/CYLDeallocBlockExecutor) 所起作用的地方从第8步骤开始。

### 模拟weak修饰的property的生命周期

我曾经在我的一篇博文中使用过类似的策略：


全文见： [《runtime 如何实现 weak 属性》]( https://github.com/ChenYilong/iOSInterviewQuestions/blob/master/01《招聘一个靠谱的iOS》面试题参考答案/《招聘一个靠谱的iOS》面试题参考答案（上）.md#8-runtime-如何实现-weak-属性 ) 

下面做下简要叙述：


我们都知道@property的 weak 属性：


 > weak 此特质表明该属性定义了一种“非拥有关系” (nonowning relationship)。为这种属性设置新值时，设置方法既不保留新值，也不释放旧值。此特质同 assign 类似， 然而在属性所指的对象遭到摧毁时，属性值也会清空(nil out)。


那么如何让不使用weak修饰的@property，拥有weak的效果？

代码如下所示：


 ```Objective-C
- (void)setObject:(NSObject *)object
{
    objc_setAssociatedObject(self, "object", object, OBJC_ASSOCIATION_ASSIGN);
    [object cyl_executeAtDealloc:^{
        _object = nil;
    }];
}
 ```

这样就达到了当 objet 为 nil 时，自动将 self.object 置 nil 的目的，从而就模拟了weak修饰的property的生命周期。

### 更加安全地在 viewDidLoad 里管理应用的生命周期

在我的一个框架 [CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController) 中，有一个KVO注册与反注册的实现：

 ```Objective-C
- (void)viewDidLoad {
    [super viewDidLoad];
    // 处理tabBar，使用自定义 tabBar 添加 发布按钮
    [self setUpTabBar];
    // KVO注册监听
    if (!self.isObservingSwappableImageViewDefaultOffset) {
        [self.tabBar addObserver:self forKeyPath:@"swappableImageViewDefaultOffset" options:NSKeyValueObservingOptionNew context:CYLSwappableImageViewDefaultOffsetContext];
        self.observingSwappableImageViewDefaultOffset = YES;
    }
    self.delegate = self;
}

- (void)dealloc {
    // KVO反注册
    if (self.isObservingSwappableImageViewDefaultOffset) {
        [self.tabBar removeObserver:self forKeyPath:@"swappableImageViewDefaultOffset"];
    }
}
 ```

也许你会很奇怪为什么有一个flag在做判断，那是因为 viewDidLoad 在一些场景下没有被调用，但 dealloc 却被调用了。。。什么场景？当 [CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController) 被作为StoryBoard的初始控制器，但是你又重写了下面的方法：

 ```Objective-C
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (!self.isUserLogin) {
        LoginViewController *login = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewController"];
        self.window.rootViewController = login;
    }
    return YES;
}
 ```

Demo 我已经放在仓库里，叫做 CYLTabBarControllerTestDemo
，[CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController) 版本 1.5.5 及之前的版本因为没有 flag 判断，直接会 crash 掉。
这种场景下我这里采用了 flag 来规避，其实也可以用 CYLDeallocBlockExecutor 来达到目的。在 viewDidLoad 做 dealloc 该做的事，即使 viewDidLoad 没有被调用，也没有关系，block里的内容也不会被执行。

同时，如果用 KVO 监听 iVar，如果由于不能确定 iVar 是否为 nil，那么你就可以做出判断，只在有值时监听。同时，释放 KVO 的行为，就可以借助本库，放在这个是否有值的判断里。这样就达到了只在有值时监听，同时在 self 销毁时释放的效果。

（更多iOS开发干货，欢迎关注  [微博@iOS程序犭袁](http://weibo.com/luohanchenyilong/) ）

----------
Posted by [微博@iOS程序犭袁](http://weibo.com/luohanchenyilong/)  
原创文章，版权声明：自由转载-非商用-非衍生-保持署名 | [Creative Commons BY-NC-ND 3.0](http://creativecommons.org/licenses/by-nc-nd/3.0/deed.zh)

