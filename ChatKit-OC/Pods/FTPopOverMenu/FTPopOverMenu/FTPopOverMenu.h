//
//  FTPopOverMenu.h
//  FTPopOverMenu
//
//  Created by liufengting on 16/4/5.
//  Copyright © 2016年 liufengting ( https://github.com/liufengting ). All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  FTPopOverMenuDoneBlock
 *
 *  @param index SlectedIndex
 */
typedef void (^FTPopOverMenuDoneBlock)(NSInteger selectedIndex);
/**
 *  FTPopOverMenuDismissBlock
 */
typedef void (^FTPopOverMenuDismissBlock)();

/**
 *  -----------------------FTPopOverMenuConfiguration-----------------------
 */
@interface FTPopOverMenuConfiguration : NSObject

@property (nonatomic, assign)CGFloat menuTextMargin;// Default is 6.
@property (nonatomic, assign)CGFloat menuIconMargin;// Default is 6.
@property (nonatomic, assign)CGFloat menuRowHeight;
@property (nonatomic, assign)CGFloat menuWidth;
@property (nonatomic, strong)UIColor *textColor;
@property (nonatomic, strong)UIColor *tintColor;
@property (nonatomic, strong)UIColor *borderColor;
@property (nonatomic, assign)CGFloat borderWidth;
@property (nonatomic, strong)UIFont *textFont;
@property (nonatomic, assign)NSTextAlignment textAlignment;
@property (nonatomic, assign)BOOL ignoreImageOriginalColor;// Default is 'NO', if sets to 'YES', images color will be same as textColor.
@property (nonatomic, assign)BOOL allowRoundedArrow;// Default is 'NO', if sets to 'YES', the arrow will be drawn with round corner.
@property (nonatomic, assign)NSTimeInterval animationDuration;
/**
 *  defaultConfiguration
 *
 *  @return curren configuration
 */
+ (FTPopOverMenuConfiguration *)defaultConfiguration;

@end

/**
 *  -----------------------FTPopOverMenuCell-----------------------
 */
@interface FTPopOverMenuCell : UITableViewCell

@end
/**
 *  -----------------------FTPopOverMenuView-----------------------
 */
@interface FTPopOverMenuView : UIControl

@end

/**
 *  -----------------------FTPopOverMenu-----------------------
 */
@interface FTPopOverMenu : NSObject

/**
 *  setTintColor "Function deprecated. User '[FTPopOverMenuConfiguration defaultConfiguration]' instead."
 *
 *  @param tintColor tintColor
 */
+(void)setTintColor:(UIColor *)tintColor __deprecated_msg("Function deprecated. User '[FTPopOverMenuConfiguration defaultConfiguration]' instead.");

/**
 *  setTextColor "Function deprecated. User '[FTPopOverMenuConfiguration defaultConfiguration]' instead."
 *
 *  @param textColor textColor
 */
+(void)setTextColor:(UIColor *)textColor __deprecated_msg("Function deprecated. User '[FTPopOverMenuConfiguration defaultConfiguration]' instead.");

/**
 *  setPreferedWidth "Function deprecated. User '[FTPopOverMenuConfiguration defaultConfiguration]' instead."
 *
 *  @param preferedWidth preferedWidth
 */
+(void)setPreferedWidth:(CGFloat )preferedWidth __deprecated_msg("Function deprecated. User '[FTPopOverMenuConfiguration defaultConfiguration]' instead.");

/**
 *  show method with sender without images
 *
 *  @param sender       sender
 *  @param menuArray    menuArray
 *  @param doneBlock    FTPopOverMenuDoneBlock
 *  @param dismissBlock FTPopOverMenuDismissBlock
 */
+ (void) showForSender:(UIView *)sender
              withMenu:(NSArray<NSString*> *)menuArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock __deprecated_msg("Function deprecated. Still working. Use replacemet please.");

/**
 show method with sender without images

 @param sender sender
 @param menuArray menuArray
 @param doneBlock doneBlock
 @param dismissBlock dismissBlock
 */
+ (void) showForSender:(UIView *)sender
         withMenuArray:(NSArray<NSString*> *)menuArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock;
/**
 *  show method with sender with imageNameArray
 *
 *  @param sender         sender
 *  @param menuArray      menuArray
 *  @param imageNameArray imageNameArray
 *  @param doneBlock      FTPopOverMenuDoneBlock
 *  @param dismissBlock   FTPopOverMenuDismissBlock
 */
+ (void) showForSender:(UIView *)sender
              withMenu:(NSArray<NSString*> *)menuArray
        imageNameArray:(NSArray<NSString*> *)imageNameArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock __deprecated_msg("Function deprecated. Still working. Use replacemet please.");

/**
 show method with sender and image resouce Array
 
 @param sender sender
 @param menuArray menuArray
 @param imageArray imageArray
 @param doneBlock doneBlock
 @param dismissBlock dismissBlock
 */
+ (void) showForSender:(UIView *)sender
         withMenuArray:(NSArray<NSString*> *)menuArray
            imageArray:(NSArray *)imageArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock;

/**
 *  show method for barbuttonitems with event without images
 *
 *  @param event          UIEvent
 *  @param menuArray      menuArray
 *  @param doneBlock      FTPopOverMenuDoneBlock
 *  @param dismissBlock   FTPopOverMenuDismissBlock
 */
+ (void) showFromEvent:(UIEvent *)event
              withMenu:(NSArray<NSString*> *)menuArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock __deprecated_msg("Function deprecated. Still working. Use replacemet please.");


/**
 show method for barbuttonitems with event without images

 @param event event
 @param menuArray menuArray
 @param doneBlock doneBlock
 @param dismissBlock dismissBlock
 */
+ (void) showFromEvent:(UIEvent *)event
         withMenuArray:(NSArray<NSString*> *)menuArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock;
/**
 *  show method for barbuttonitems with event and image resouce Array
 *
 *  @param event          UIEvent
 *  @param menuArray      menuArray
 *  @param imageNameArray imageNameArray
 *  @param doneBlock      FTPopOverMenuDoneBlock
 *  @param dismissBlock   FTPopOverMenuDismissBlock
 */
+ (void) showFromEvent:(UIEvent *)event
              withMenu:(NSArray<NSString*> *)menuArray
        imageNameArray:(NSArray<NSString*> *)imageNameArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock __deprecated_msg("Function deprecated. Still working. Use replacemet please.");


/**
 show method for barbuttonitems with event and imageArray

 @param event event
 @param menuArray menuArray
 @param imageArray imageArray
 @param doneBlock doneBlock
 @param dismissBlock dismissBlock
 */
+ (void) showFromEvent:(UIEvent *)event
         withMenuArray:(NSArray<NSString*> *)menuArray
            imageArray:(NSArray *)imageArray
             doneBlock:(FTPopOverMenuDoneBlock)doneBlock
          dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock;

/**
 *  show method with SenderFrame without images
 *
 *  @param senderFrame  senderFrame
 *  @param menuArray    menuArray
 *  @param doneBlock    doneBlock
 *  @param dismissBlock dismissBlock
 */
+ (void) showFromSenderFrame:(CGRect )senderFrame
                    withMenu:(NSArray<NSString*> *)menuArray
                   doneBlock:(FTPopOverMenuDoneBlock)doneBlock
                dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock __deprecated_msg("Function deprecated. Still working. Use replacemet please.");


/**
 show method with SenderFrame without images

 @param senderFrame senderFrame
 @param menuArray menuArray
 @param doneBlock doneBlock
 @param dismissBlock dismissBlock
 */
+ (void) showFromSenderFrame:(CGRect )senderFrame
               withMenuArray:(NSArray<NSString*> *)menuArray
                   doneBlock:(FTPopOverMenuDoneBlock)doneBlock
                dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock;
/**
 *  show method with SenderFrame with imageNameArray
 *
 *  @param senderFrame    senderFrame
 *  @param menuArray      menuArray
 *  @param imageNameArray imageNameArray
 *  @param doneBlock      doneBlock
 *  @param dismissBlock   dismissBlock
 
 */
+ (void) showFromSenderFrame:(CGRect )senderFrame
                    withMenu:(NSArray<NSString*> *)menuArray
              imageNameArray:(NSArray<NSString*> *)imageNameArray
                   doneBlock:(FTPopOverMenuDoneBlock)doneBlock
                dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock __deprecated_msg("Function deprecated. Still working. Use replacemet please.");


/**
 show method with SenderFrame and image resouce Array

 @param senderFrame senderFrame
 @param menuArray menuArray
 @param imageArray imageArray
 @param doneBlock doneBlock
 @param dismissBlock dismissBlock
 */
+ (void) showFromSenderFrame:(CGRect )senderFrame
               withMenuArray:(NSArray<NSString*> *)menuArray
                  imageArray:(NSArray *)imageArray
                   doneBlock:(FTPopOverMenuDoneBlock)doneBlock
                dismissBlock:(FTPopOverMenuDismissBlock)dismissBlock;

/**
 *  dismiss method
 */
+ (void) dismiss;

@end
