//
//  LCCKInputViewPluginTakePhoto.m
//  Pods
//
// v0.5.2 Created by 陈宜龙 on 16/8/11.
//
//

#import "LCCKInputViewPluginTakePhoto.h"

@interface LCCKInputViewPluginTakePhoto()<UIImagePickerControllerDelegate>

@property (nonatomic) LCCKConversationViewController *conversationViewController;
@property (nonatomic, copy) LCCKIdResultBlock sendCustomMessageHandler;

@end

@implementation LCCKInputViewPluginTakePhoto
@synthesize inputViewRef = _inputViewRef;
@synthesize sendCustomMessageHandler = _sendCustomMessageHandler;

#pragma mark -
#pragma mark - LCCKInputViewPluginSubclassing Method

+ (void)load {
    [self registerSubclass];
}

+ (LCCKInputViewPluginType)classPluginType {
    return LCCKInputViewPluginTypeTakePhoto;
}

#pragma mark -
#pragma mark - LCCKInputViewPluginDelegate Method

/*!
 * 插件图标
 */
- (UIImage *)pluginIconImage {
    return [self imageInBundlePathForImageName:@"chat_bar_icons_camera"];
}

/*!
 * 插件名称
 */
- (NSString *)pluginTitle {
    return @"拍摄";
}

/*!
 * 插件对应的 view，会被加载到 inputView 上
 */
- (UIView *)pluginContentView {
    return nil;
}

- (void)dealloc {
    self.inputViewRef = nil;
}

- (void)pluginDidClicked {
    [super pluginDidClicked];
    //显示拍照
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        LCCKShowNotificationBlock showNotificationBlock = [LCCKUIService sharedInstance].showNotificationBlock;
        id<UIApplicationDelegate> delegate = ((id<UIApplicationDelegate>)[[UIApplication sharedApplication] delegate]);
        UIWindow *window = delegate.window;
        !showNotificationBlock ?: showNotificationBlock(window.rootViewController, @"您的设备不支持拍照", @"请尝试在设置中开启拍照权限", LCCKMessageNotificationTypeError);
        return;
    }
    UIImagePickerController *pickerC = [[UIImagePickerController alloc] init];
    pickerC.sourceType = UIImagePickerControllerSourceTypeCamera;
    pickerC.delegate = self;
    [self.conversationViewController presentViewController:pickerC animated:YES completion:nil];
}

- (LCCKIdResultBlock)sendCustomMessageHandler {
    if (_sendCustomMessageHandler) {
        return _sendCustomMessageHandler;
    }
    LCCKIdResultBlock sendCustomMessageHandler = ^(id object, NSError *error) {
        [self.conversationViewController dismissViewControllerAnimated:YES completion:nil];
        UIImage *image = (UIImage *)object;
        if (object) {
            [self.conversationViewController sendImageMessage:image];
        }
        _sendCustomMessageHandler = nil;
    };
    _sendCustomMessageHandler = sendCustomMessageHandler;
    return sendCustomMessageHandler;
}

#pragma mark -
#pragma mark - Private Methods

- (UIImage *)imageInBundlePathForImageName:(NSString *)imageName {
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
    return image;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    !self.sendCustomMessageHandler ?: self.sendCustomMessageHandler(image, nil);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    NSInteger code = 0;
    NSString *errorReasonText = @"cancel image picker without result";
    NSDictionary *errorInfo = @{
                                @"code":@(code),
                                NSLocalizedDescriptionKey : errorReasonText,
                                };
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class])
                                         code:code
                                     userInfo:errorInfo];
    !self.sendCustomMessageHandler ?: self.sendCustomMessageHandler(nil, error);
}

@end
