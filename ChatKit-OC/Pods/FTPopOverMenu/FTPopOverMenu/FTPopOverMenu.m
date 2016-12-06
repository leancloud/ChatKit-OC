//
//  FTPopOverMenu.m
//  FTPopOverMenu
//
//  Created by liufengting on 16/4/5.
//  Copyright © 2016年 liufengting ( https://github.com/liufengting ). All rights reserved.
//

#import "FTPopOverMenu.h"

// changeable
#define FTDefaultMargin             4.0
#define FTDefaultMenuArrowWidth     8.0
#define FTDefaultMenuArrowHeight    10.0
#define FTDefaultMenuTextMargin     6.0
#define FTDefaultMenuCornerRadius   4.0
#define FTDefaultAnimationDuration  0.2
// unchangeable, change them at your own risk
#define KSCREEN_WIDTH               [[UIScreen mainScreen] bounds].size.width
#define KSCREEN_HEIGHT              [[UIScreen mainScreen] bounds].size.height
#define FTDefaultBackgroundColor    [UIColor clearColor]
#define FTDefaultTintColor          [UIColor colorWithRed:80/255.f green:80/255.f blue:80/255.f alpha:1.f]
#define FTDefaultTextColor          [UIColor whiteColor]
#define FTDefaultMenuFont           [UIFont systemFontOfSize:14]
#define FTDefaultMenuWidth          120.0
#define FTDefaultMenuIconSize       24.0
#define FTDefaultMenuRowHeight      40.0
#define FTDefaultMenuBorderWidth    0.8

static NSString * const FTPopOverMenuTableViewCellIndentifier = @"FTPopOverMenuTableViewCellIndentifier";

/**
 *  FTPopOverMenuArrowDirection
 */
typedef NS_ENUM(NSUInteger, FTPopOverMenuArrowDirection) {
    /**
     *  Up
     */
    FTPopOverMenuArrowDirectionUp,
    /**
     *  Down
     */
    FTPopOverMenuArrowDirectionDown,
};

#pragma mark - FTPopOverMenuConfiguration

@interface FTPopOverMenuConfiguration ()

@end

@implementation FTPopOverMenuConfiguration

+ (FTPopOverMenuConfiguration *)defaultConfiguration
{
    static dispatch_once_t once = 0;
    static FTPopOverMenuConfiguration *configuration;
    dispatch_once(&once, ^{ configuration = [[FTPopOverMenuConfiguration alloc] init]; });
    return configuration;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.menuRowHeight = FTDefaultMenuRowHeight;
        self.menuWidth = FTDefaultMenuWidth;
        self.textColor = FTDefaultTextColor;
        self.textFont = FTDefaultMenuFont;
        self.tintColor = FTDefaultTintColor;
        self.borderColor = FTDefaultTintColor;
        self.borderWidth = FTDefaultMenuBorderWidth;
        self.textAlignment = NSTextAlignmentLeft;
        self.ignoreImageOriginalColor = NO;
   }
    return self;
}

@end

#pragma mark - FTPopOverMenuCell

@interface FTPopOverMenuCell ()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *menuNameLabel;

@end

@implementation FTPopOverMenuCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style
             reuseIdentifier:(NSString *)reuseIdentifier
                    menuName:(NSString *)menuName
               iconImageName:(NSString *)iconImageName
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UIImage *iconImage;
        if (iconImageName.length) {
            iconImage = [UIImage imageNamed:iconImageName];
        }
        CGFloat margin = ([FTPopOverMenuConfiguration defaultConfiguration].menuRowHeight - FTDefaultMenuIconSize)/2;
        CGRect iconImageRect = CGRectMake(FTDefaultMenuTextMargin, margin, FTDefaultMenuIconSize, FTDefaultMenuIconSize);
        CGRect menuNameRect = CGRectMake(FTDefaultMenuTextMargin*2 + FTDefaultMenuIconSize, 0, [FTPopOverMenuConfiguration defaultConfiguration].menuWidth - FTDefaultMenuIconSize - FTDefaultMenuTextMargin*3, [FTPopOverMenuConfiguration defaultConfiguration].menuRowHeight);
        if (iconImage) {
            if ([FTPopOverMenuConfiguration defaultConfiguration].ignoreImageOriginalColor) {
                iconImage = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
        
            _iconImageView = [[UIImageView alloc]initWithFrame:iconImageRect];
            _iconImageView.backgroundColor = [UIColor clearColor];
            _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
            _iconImageView.tintColor = [FTPopOverMenuConfiguration defaultConfiguration].textColor;
            _iconImageView.image = iconImage;
            [self.contentView addSubview:_iconImageView];
        }else{
            menuNameRect = CGRectMake(FTDefaultMenuTextMargin, 0, [FTPopOverMenuConfiguration defaultConfiguration].menuWidth - FTDefaultMenuTextMargin*2, [FTPopOverMenuConfiguration defaultConfiguration].menuRowHeight);
        }
        _menuNameLabel = [[UILabel alloc]initWithFrame:menuNameRect];
        _menuNameLabel.backgroundColor = [UIColor clearColor];
        _menuNameLabel.font = [FTPopOverMenuConfiguration defaultConfiguration].textFont;
        _menuNameLabel.textColor = [FTPopOverMenuConfiguration defaultConfiguration].textColor;
        _menuNameLabel.textAlignment = [FTPopOverMenuConfiguration defaultConfiguration].textAlignment;
        _menuNameLabel.text = menuName;
        [self.contentView addSubview:_menuNameLabel];
    }
    return self;
}

@end



#pragma mark - FTPopOverMenuView

@interface FTPopOverMenuView () <UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *menuTableView;
@property (nonatomic, strong) NSArray<NSString *> *menuStringArray;
@property (nonatomic, strong) NSArray<NSString *> *menuIconNameArray;
@property (nonatomic, assign) FTPopOverMenuArrowDirection arrowDirection;
@property (nonatomic, strong) FTPopOverMenuDoneBlock doneBlock;
@property (nonatomic, strong) CAShapeLayer *backgroundLayer;


@property (nonatomic, strong) UIColor *tintColor;

@end

@implementation FTPopOverMenuView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(UITableView *)menuTableView
{
    if (!_menuTableView) {
        _menuTableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
        _menuTableView.backgroundColor = FTDefaultBackgroundColor;
        _menuTableView.separatorColor = [UIColor grayColor];
        _menuTableView.layer.cornerRadius = FTDefaultMenuCornerRadius;
        _menuTableView.scrollEnabled = NO;
        _menuTableView.clipsToBounds = YES;
        _menuTableView.delegate = self;
        _menuTableView.dataSource = self;
        [self addSubview:_menuTableView];
    }
    return _menuTableView;
}



-(void)showWithFrame:(CGRect )frame
          anglePoint:(CGPoint)anglePoint
       withNameArray:(NSArray<NSString*> *)nameArray
      imageNameArray:(NSArray<NSString*> *)imageNameArray
    shouldAutoScroll:(BOOL)shouldAutoScroll
      arrowDirection:(FTPopOverMenuArrowDirection)arrowDirection
           doneBlock:(FTPopOverMenuDoneBlock)doneBlock
{
    self.frame = frame;
    _menuStringArray = nameArray;
    _menuIconNameArray = imageNameArray;
    _arrowDirection = arrowDirection;
    self.doneBlock = doneBlock;
    self.menuTableView.scrollEnabled = shouldAutoScroll;


    CGRect menuRect = CGRectMake(0, FTDefaultMenuArrowHeight, self.frame.size.width, self.frame.size.height - FTDefaultMenuArrowHeight);
    if (_arrowDirection == FTPopOverMenuArrowDirectionDown) {
        menuRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - FTDefaultMenuArrowHeight);
    }
    [self.menuTableView setFrame:menuRect];
    [self.menuTableView reloadData];
 
    [self drawBackgroundLayerWithAnglePoint:anglePoint];
}
-(void)drawBackgroundLayerWithAnglePoint:(CGPoint)anglePoint
{
    if (_backgroundLayer) {
        [_backgroundLayer removeFromSuperlayer];
    }

    UIBezierPath *path = [UIBezierPath bezierPath];

    switch (_arrowDirection) {
        case FTPopOverMenuArrowDirectionUp:{
         
            [path moveToPoint:anglePoint];
            [path addLineToPoint:CGPointMake( anglePoint.x - FTDefaultMenuArrowWidth, FTDefaultMenuArrowHeight)];
            [path addLineToPoint:CGPointMake( FTDefaultMenuCornerRadius, FTDefaultMenuArrowHeight)];
            [path addArcWithCenter:CGPointMake(FTDefaultMenuCornerRadius, FTDefaultMenuArrowHeight + FTDefaultMenuCornerRadius) radius:FTDefaultMenuCornerRadius startAngle:-M_PI_2 endAngle:-M_PI clockwise:NO];
            [path addLineToPoint:CGPointMake( 0, self.bounds.size.height - FTDefaultMenuCornerRadius)];
            [path addArcWithCenter:CGPointMake(FTDefaultMenuCornerRadius, self.bounds.size.height - FTDefaultMenuCornerRadius) radius:FTDefaultMenuCornerRadius startAngle:M_PI endAngle:M_PI_2 clockwise:NO];
            [path addLineToPoint:CGPointMake( self.bounds.size.width - FTDefaultMenuCornerRadius, self.bounds.size.height)];
            [path addArcWithCenter:CGPointMake(self.bounds.size.width - FTDefaultMenuCornerRadius, self.bounds.size.height - FTDefaultMenuCornerRadius) radius:FTDefaultMenuCornerRadius startAngle:M_PI_2 endAngle:0 clockwise:NO];
            [path addLineToPoint:CGPointMake(self.bounds.size.width , FTDefaultMenuCornerRadius + FTDefaultMenuArrowHeight)];
            [path addArcWithCenter:CGPointMake(self.bounds.size.width - FTDefaultMenuCornerRadius, FTDefaultMenuCornerRadius + FTDefaultMenuArrowHeight) radius:FTDefaultMenuCornerRadius startAngle:0 endAngle:-M_PI_2 clockwise:NO];
            [path addLineToPoint:CGPointMake(anglePoint.x + FTDefaultMenuArrowWidth, FTDefaultMenuArrowHeight)];
            [path closePath];

        }break;
        case FTPopOverMenuArrowDirectionDown:{
            
            [path moveToPoint:anglePoint];
            [path addLineToPoint:CGPointMake( anglePoint.x - FTDefaultMenuArrowWidth, anglePoint.y - FTDefaultMenuArrowHeight)];
            [path addLineToPoint:CGPointMake( FTDefaultMenuCornerRadius, anglePoint.y - FTDefaultMenuArrowHeight)];
            [path addArcWithCenter:CGPointMake(FTDefaultMenuCornerRadius, anglePoint.y - FTDefaultMenuArrowHeight - FTDefaultMenuCornerRadius) radius:FTDefaultMenuCornerRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake( 0, FTDefaultMenuCornerRadius)];
            [path addArcWithCenter:CGPointMake(FTDefaultMenuCornerRadius, FTDefaultMenuCornerRadius) radius:FTDefaultMenuCornerRadius startAngle:M_PI endAngle:-M_PI_2 clockwise:YES];
            [path addLineToPoint:CGPointMake( self.bounds.size.width - FTDefaultMenuCornerRadius, 0)];
            [path addArcWithCenter:CGPointMake(self.bounds.size.width - FTDefaultMenuCornerRadius, FTDefaultMenuCornerRadius) radius:FTDefaultMenuCornerRadius startAngle:-M_PI_2 endAngle:0 clockwise:YES];
            [path addLineToPoint:CGPointMake(self.bounds.size.width , anglePoint.y - (FTDefaultMenuCornerRadius + FTDefaultMenuArrowHeight))];
            [path addArcWithCenter:CGPointMake(self.bounds.size.width - FTDefaultMenuCornerRadius, anglePoint.y - (FTDefaultMenuCornerRadius + FTDefaultMenuArrowHeight)) radius:FTDefaultMenuCornerRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
            [path addLineToPoint:CGPointMake(anglePoint.x + FTDefaultMenuArrowWidth, anglePoint.y - FTDefaultMenuArrowHeight)];
            [path closePath];
            
        }break;
        default:
            break;
    }
    
    _backgroundLayer = [CAShapeLayer layer];
    _backgroundLayer.path = path.CGPath;
    _backgroundLayer.lineWidth = [FTPopOverMenuConfiguration defaultConfiguration].borderWidth;
    _backgroundLayer.fillColor = [FTPopOverMenuConfiguration defaultConfiguration].tintColor.CGColor;
    _backgroundLayer.strokeColor = [FTPopOverMenuConfiguration defaultConfiguration].borderColor.CGColor;
    [self.layer insertSublayer:_backgroundLayer atIndex:0];
}


#pragma mark - UITableViewDelegate,UITableViewDataSource
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.f;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [FTPopOverMenuConfiguration defaultConfiguration].menuRowHeight;
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.f;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _menuStringArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *imageName = [NSString string];
    if (_menuIconNameArray.count - 1 >= indexPath.row) {
        imageName = [NSString stringWithFormat:@"%@",_menuIconNameArray[indexPath.row]];
    }
    FTPopOverMenuCell *menuCell = [[FTPopOverMenuCell alloc]initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:FTPopOverMenuTableViewCellIndentifier
                                                                 menuName:[NSString stringWithFormat:@"%@", _menuStringArray[indexPath.row]]
                                                            iconImageName:imageName];
    if (indexPath.row == _menuStringArray.count-1) {
        menuCell.separatorInset = UIEdgeInsetsMake(0, self.bounds.size.width, 0, 0);
    }else{
        menuCell.separatorInset = UIEdgeInsetsMake(0, FTDefaultMenuTextMargin, 0, FTDefaultMenuTextMargin);
    }
    return menuCell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.doneBlock) {
        self.doneBlock(indexPath.row);
    }
}

@end


#pragma mark - FTPopOverMenu

@interface FTPopOverMenu () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView * backgroundView;
@property (nonatomic, strong) FTPopOverMenuView *popMenuView;
@property (nonatomic, strong) FTPopOverMenuDoneBlock doneBlock;
@property (nonatomic, strong) FTPopOverMenuDismissBlock dismissBlock;

@property (nonatomic, strong) UIView *sender;
@property (nonatomic, assign) CGRect senderFrame;
@property (nonatomic, strong) NSArray<NSString*> *menuArray;
@property (nonatomic, strong) NSArray<NSString*> *menuImageArray;
@property (nonatomic, assign) BOOL isCurrentlyOnScreen;

@end

@implementation FTPopOverMenu

+ (FTPopOverMenu *)sharedInstance
{
    static dispatch_once_t once = 0;
    static FTPopOverMenu *shared;
    dispatch_once(&once, ^{ shared = [[FTPopOverMenu alloc] init]; });
    return shared;
}

#pragma mark - Public Method

+(void)setTintColor:(UIColor *)tintColor
{
    [FTPopOverMenuConfiguration defaultConfiguration].tintColor = tintColor;
}

+(void)setTextColor:(UIColor *)textColor
{
    [FTPopOverMenuConfiguration defaultConfiguration].textColor = textColor;
}

+(void)setPreferedWidth:(CGFloat )preferedWidth
{
    [FTPopOverMenuConfiguration defaultConfiguration].menuWidth = preferedWidth;
}

+ (void) showForSender:(UIView *)sender
              withMenu:(NSArray<NSString*> *)menuArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock
{
    [[self sharedInstance] showForSender:sender senderFrame:CGRectNull withMenu:menuArray imageNameArray:nil doneBlock:doneBlock dismissBlock:dismissBlock];
}
+ (void) showForSender:(UIView *)sender
              withMenu:(NSArray<NSString*> *)menuArray
        imageNameArray:(NSArray<NSString*> *)imageNameArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock;
{
    [[self sharedInstance] showForSender:sender senderFrame:CGRectNull withMenu:menuArray imageNameArray:imageNameArray doneBlock:doneBlock dismissBlock:dismissBlock];
}

+ (void) showFromEvent:(UIEvent *)event
              withMenu:(NSArray<NSString*> *)menuArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock
{
    [[self sharedInstance] showForSender:[event.allTouches.anyObject view] senderFrame:CGRectNull withMenu:menuArray imageNameArray:nil doneBlock:doneBlock dismissBlock:dismissBlock];
}

+ (void) showFromEvent:(UIEvent *)event
              withMenu:(NSArray<NSString*> *)menuArray
        imageNameArray:(NSArray<NSString*> *)imageNameArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock
{
    [[self sharedInstance] showForSender:[event.allTouches.anyObject view] senderFrame:CGRectNull withMenu:menuArray imageNameArray:imageNameArray doneBlock:doneBlock dismissBlock:dismissBlock];
    
}
+ (void) showFromSenderFrame:(CGRect )senderFrame
                   withMenu:(NSArray<NSString*> *)menuArray
                  doneBlock:(FTPopOverMenuDoneBlock)doneBlock
               dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock
{
    [[self sharedInstance] showForSender:nil senderFrame:senderFrame withMenu:menuArray imageNameArray:nil doneBlock:doneBlock dismissBlock:dismissBlock];
}
+ (void) showFromSenderFrame:(CGRect )senderFrame
                    withMenu:(NSArray<NSString*> *)menuArray
              imageNameArray:(NSArray<NSString*> *)imageNameArray
                   doneBlock:(FTPopOverMenuDoneBlock)doneBlock
                dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock
{
    [[self sharedInstance] showForSender:nil senderFrame:senderFrame withMenu:menuArray imageNameArray:imageNameArray doneBlock:doneBlock dismissBlock:dismissBlock];
}

+(void)dismiss
{
    [[self sharedInstance] dismiss];
}



#pragma mark - Private Methods

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onChangeStatusBarOrientationNotification:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

-(UIView *)backgroundView
{
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc ]initWithFrame:[UIScreen mainScreen].bounds];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundViewTapped:)];
        tap.delegate = self;
        [_backgroundView addGestureRecognizer:tap];
        _backgroundView.backgroundColor = FTDefaultBackgroundColor;
    }
    return _backgroundView;
}
-(FTPopOverMenuView *)popMenuView
{
    if (!_popMenuView) {
        _popMenuView = [[FTPopOverMenuView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _popMenuView.alpha = 0;
    }
    return _popMenuView;
}


-(void)onChangeStatusBarOrientationNotification:(NSNotification *)notification
{
    if (self.isCurrentlyOnScreen) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self adjustPopOverMenu];
        });
    }
}


- (void) showForSender:(UIView *)sender
           senderFrame:(CGRect )senderFrame
              withMenu:(NSArray<NSString*> *)menuArray
        imageNameArray:(NSArray<NSString*> *)imageNameArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock
{
    [self.backgroundView addSubview:self.popMenuView];
    [[[UIApplication sharedApplication] keyWindow] addSubview:self.backgroundView];

    self.sender = sender;
    self.senderFrame = senderFrame;
    self.menuArray = menuArray;
    self.menuImageArray = imageNameArray;
    self.doneBlock = doneBlock;
    self.dismissBlock = dismissBlock;
    
    
    [self adjustPopOverMenu];
}

-(void)adjustPopOverMenu
{
    
    [self.backgroundView setFrame:CGRectMake(0, 0, KSCREEN_WIDTH, KSCREEN_HEIGHT)];
    
    CGRect senderRect ;
    
    if (self.sender) {
        senderRect = [self.sender.superview convertRect:self.sender.frame toView:self.backgroundView];
// if run into touch problems on nav bar, use the fowllowing line.
//        senderRect.origin.y = MAX(64-senderRect.origin.y, senderRect.origin.y);
    }else{
        senderRect = self.senderFrame;
    }
    if (senderRect.origin.y > KSCREEN_HEIGHT) {
        senderRect.origin.y = KSCREEN_HEIGHT;
    }
    
    CGFloat menuHeight = [FTPopOverMenuConfiguration defaultConfiguration].menuRowHeight * self.menuArray.count + FTDefaultMenuArrowHeight;
    CGPoint menuArrowPoint = CGPointMake(senderRect.origin.x + (senderRect.size.width)/2, 0);
    CGFloat menuX = 0;
    CGRect menuRect = CGRectZero;
    BOOL shouldAutoScroll = NO;
    FTPopOverMenuArrowDirection arrowDirection;
    
    if (senderRect.origin.y + senderRect.size.height/2  < KSCREEN_HEIGHT/2) {
        arrowDirection = FTPopOverMenuArrowDirectionUp;
        menuArrowPoint.y = 0;
    }else{
        arrowDirection = FTPopOverMenuArrowDirectionDown;
        menuArrowPoint.y = menuHeight;

    }
    
    if (menuArrowPoint.x + [FTPopOverMenuConfiguration defaultConfiguration].menuWidth/2 + FTDefaultMargin > KSCREEN_WIDTH) {
        menuArrowPoint.x = MIN(menuArrowPoint.x - (KSCREEN_WIDTH - [FTPopOverMenuConfiguration defaultConfiguration].menuWidth - FTDefaultMargin), [FTPopOverMenuConfiguration defaultConfiguration].menuWidth - FTDefaultMenuArrowWidth - FTDefaultMargin);
        menuX = KSCREEN_WIDTH - [FTPopOverMenuConfiguration defaultConfiguration].menuWidth - FTDefaultMargin;
    }else if ( menuArrowPoint.x - [FTPopOverMenuConfiguration defaultConfiguration].menuWidth/2 - FTDefaultMargin < 0){
        menuArrowPoint.x = MAX( FTDefaultMenuCornerRadius + FTDefaultMenuArrowWidth, menuArrowPoint.x - FTDefaultMargin);
        menuX = FTDefaultMargin;
    }else{
        menuArrowPoint.x = [FTPopOverMenuConfiguration defaultConfiguration].menuWidth/2;
        menuX = senderRect.origin.x + (senderRect.size.width)/2 - [FTPopOverMenuConfiguration defaultConfiguration].menuWidth/2;
    }
    
    if (arrowDirection == FTPopOverMenuArrowDirectionUp) {
        menuRect = CGRectMake(menuX, (senderRect.origin.y + senderRect.size.height), [FTPopOverMenuConfiguration defaultConfiguration].menuWidth, menuHeight);
        // if too long and is out of screen
        if (menuRect.origin.y + menuRect.size.height > KSCREEN_HEIGHT) {
            menuRect = CGRectMake(menuX, (senderRect.origin.y + senderRect.size.height), [FTPopOverMenuConfiguration defaultConfiguration].menuWidth, KSCREEN_HEIGHT - menuRect.origin.y - FTDefaultMargin);
            shouldAutoScroll = YES;
        }
    }else{
        
        menuRect = CGRectMake(menuX, (senderRect.origin.y - menuHeight), [FTPopOverMenuConfiguration defaultConfiguration].menuWidth, menuHeight);
        // if too long and is out of screen
        if (menuRect.origin.y  < 0) {
            menuRect = CGRectMake(menuX, FTDefaultMargin, [FTPopOverMenuConfiguration defaultConfiguration].menuWidth, senderRect.origin.y - FTDefaultMargin);
            menuArrowPoint.y = senderRect.origin.y;
            shouldAutoScroll = YES;
        }
    }
    
    CGPoint anchorPoint = CGPointMake(menuArrowPoint.x/menuRect.size.width, 0);
    if (arrowDirection == FTPopOverMenuArrowDirectionDown) {
        anchorPoint = CGPointMake(menuArrowPoint.x/menuRect.size.width, 1);
    }
    
    
    
    _popMenuView.transform = CGAffineTransformMakeScale(1, 1);
 
    [_popMenuView showWithFrame:menuRect
                     anglePoint:menuArrowPoint
                  withNameArray:self.menuArray
                 imageNameArray:self.menuImageArray
               shouldAutoScroll:shouldAutoScroll
                 arrowDirection:arrowDirection
                      doneBlock:^(NSInteger selectedIndex) {
                          [self doneActionWithSelectedIndex:selectedIndex];
                      }];
    
    [self setAnchorPoint:anchorPoint forView:_popMenuView];
    
    _popMenuView.transform = CGAffineTransformMakeScale(0.1, 0.1);
    
    [self show];
}

-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

#pragma mark - UIGestureRecognizerDelegate
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint point = [touch locationInView:_popMenuView];
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }else if (CGRectContainsPoint(CGRectMake(0, 0, [FTPopOverMenuConfiguration defaultConfiguration].menuWidth, [FTPopOverMenuConfiguration defaultConfiguration].menuRowHeight), point)) {
        [self doneActionWithSelectedIndex:0];
        return NO;
    }
    return YES;
}

#pragma mark - onBackgroundViewTapped

-(void)onBackgroundViewTapped:(UIGestureRecognizer *)gesture
{
    [self dismiss];
}

#pragma mark - show animation

- (void)show
{
    self.isCurrentlyOnScreen = YES;
    [UIView animateWithDuration:FTDefaultAnimationDuration
                     animations:^{
                         _popMenuView.alpha = 1;
                         _popMenuView.transform = CGAffineTransformMakeScale(1, 1);
                     }];
}

#pragma mark - dismiss animation

- (void)dismiss
{
    self.isCurrentlyOnScreen = NO;
    [self doneActionWithSelectedIndex:-1];
}

#pragma mark - doneActionWithSelectedIndex 

-(void)doneActionWithSelectedIndex:(NSInteger)selectedIndex
{
    [UIView animateWithDuration:FTDefaultAnimationDuration
                     animations:^{
                         _popMenuView.alpha = 0;
                         _popMenuView.transform = CGAffineTransformMakeScale(0.1, 0.1);
                     }completion:^(BOOL finished) {
                         if (finished) {
                             [self.popMenuView removeFromSuperview];
                             [self.backgroundView removeFromSuperview];
                             if (selectedIndex < 0) {
                                 if (self.dismissBlock) {
                                     self.dismissBlock();
                                 }
                             }else{
                                 if (self.doneBlock) {
                                     self.doneBlock(selectedIndex);
                                 }
                             }
                         }
                     }];
}
@end
