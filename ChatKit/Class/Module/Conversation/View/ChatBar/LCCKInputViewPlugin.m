//
//  LCCKInputViewPlugin.m
//  Pods
//
//  v0.7.19 Created by ElonChan (微信向我报BUG:chenyilong1010) on 16/7/19.
//
//

#import "LCCKInputViewPlugin.h"

#if __has_include(<ChatKit/LCChatKit.h>)
#import <ChatKit/LCChatKit.h>
#else
#import "LCChatKit.h"
#endif

#if __has_include(<Masonry/Masonry.h>)
#import <Masonry/Masonry.h>
#else
#import "Masonry.h"
#endif

NSMutableDictionary const *LCCKInputViewPluginDict = nil;
NSMutableArray const *LCCKInputViewPluginArray = nil;

@interface LCCKInputViewPlugin ()

@property (nonatomic, readwrite) LCCKInputViewPluginType pluginType;
@property (strong, nonatomic) UIButton *button;
@property (strong, nonatomic) UILabel *titleLabel;
@property (nonatomic, strong) UIColor *messageInputViewMorePanelTextColor;

@end

@implementation LCCKInputViewPlugin
@synthesize delegate = _delegate;
@synthesize inputViewRef = _inputViewRef;
@synthesize pluginContentView = _pluginContentView;
@synthesize pluginType = _pluginType;
@synthesize pluginIconImage = _pluginIconImage;
@synthesize pluginTitle = _pluginTitle;
@synthesize sendCustomMessageHandler = _sendCustomMessageHandler;

- (instancetype)init {
    if (![self conformsToProtocol:@protocol(LCCKInputViewPluginSubclassing)]) {
        [NSException raise:@"LCCKInputViewPluginNotSubclassException" format:@"Class does not conform LCCKInputViewPluginSubclassing protocol."];
    }
    if ((self = [super init])) {
        self.pluginType = [[self class] classPluginType];
    }
    return self;
}

+ (void)registerCustomInputViewPlugin {
    [self registerSubclass];
}

+ (void)registerSubclass {
    if ([self conformsToProtocol:@protocol(LCCKInputViewPluginSubclassing)]) {
        Class<LCCKInputViewPluginSubclassing> class = self;
        LCCKInputViewPluginType type = [class classPluginType];
        [self registerClass:class forMediaType:type];
    }
}

+ (Class)classForMediaType:(LCCKInputViewPluginType)type {
    NSNumber *typeKey = [NSNumber numberWithInteger:type];
    Class class = [LCCKInputViewPluginDict objectForKey:typeKey];
    if (!class) {
        class = self;
    }
    return class;
}

+ (void)registerClass:(Class)class forMediaType:(LCCKInputViewPluginType)type {
    if (!LCCKInputViewPluginDict) {
        LCCKInputViewPluginDict = [[NSMutableDictionary alloc] init];
    }
    if (!LCCKInputViewPluginArray) {
        LCCKInputViewPluginArray = [[NSMutableArray alloc] init];
    }
    NSNumber *typeKey = [NSNumber numberWithInteger:type];
    Class c = [LCCKInputViewPluginDict objectForKey:typeKey];
    if (!c || [class isSubclassOfClass:c]) {
        [LCCKInputViewPluginDict setObject:class forKey:typeKey];
        NSDictionary *dictionary = @{
                                     LCCKInputViewPluginTypeKey : typeKey,
                                     LCCKInputViewPluginClassKey : class,
                                     };
        [LCCKInputViewPluginArray addObject:dictionary];
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib{
    [self setup];
}

- (void)updateConstraints{
    [super updateConstraints];
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self).with.offset(4);
        make.centerX.equalTo(self);
        make.width.equalTo(@50);
        make.height.equalTo(@50);
    }];
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.button.mas_bottom).with.offset(3);
        make.centerX.equalTo(self.mas_centerX);
    }];
}

#pragma mark - Public Methods

- (void)fillWithPluginTitle:(NSString *)pluginTitle
            pluginIconImage:(UIImage *)pluginIconImage {
    self.titleLabel.text = pluginTitle;
    [self.button setBackgroundImage:pluginIconImage forState:UIControlStateNormal];
}

#pragma mark - Private Methods

- (void)setup {
    [self addSubview:self.button];
    [self addSubview:self.titleLabel];
    [self updateConstraintsIfNeeded];
}

- (void)buttonAction {
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [self.button setHighlighted:YES];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    [self.button setHighlighted:NO];
}

#pragma mark - Getters
- (UIButton *)button {
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        [_button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:13.0f];
        _titleLabel.textColor = self.messageInputViewMorePanelTextColor;
    }
    return _titleLabel;
}

- (void)pluginDidClicked {
    [self sendCustomMessageHandler];
}

- (LCCKConversationViewController *)conversationViewController {
    if ([self.inputViewRef.controllerRef isKindOfClass:[LCCKConversationViewController class]]) {
        return (LCCKConversationViewController *)self.inputViewRef.controllerRef;
    } else {
        return nil;
    }
}

- (UIColor *)messageInputViewMorePanelTextColor {
    if (_messageInputViewMorePanelTextColor) {
        return _messageInputViewMorePanelTextColor;
    }
    _messageInputViewMorePanelTextColor = [[LCCKSettingService sharedInstance] defaultThemeColorForKey:@"MessageInputView-MorePanel-TextColor"];
    return _messageInputViewMorePanelTextColor;
}

@end
