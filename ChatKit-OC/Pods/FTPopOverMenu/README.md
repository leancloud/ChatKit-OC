![FTPopOverMenu](https://raw.githubusercontent.com/liufengting/FTResourceRepo/master/Resource/FTPopOverMenu/FTPopOverMenu.jpg)

# FTPopOverMenu

[![Twitter](https://img.shields.io/badge/twitter-@liufengting-blue.svg?style=flat)](http://twitter.com/liufengting) 
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/liufengting/FTPopOverMenu/master/LICENSE)
[![Version](https://img.shields.io/cocoapods/v/FTPopOverMenu.svg?style=flat)](http://cocoapods.org/pods/FTPopOverMenu)
[![Codebeat badge](https://codebeat.co/badges/763991fb-8307-4683-8b19-6c8aba9f1683)](https://codebeat.co/projects/github-com-liufengting-ftpopovermenu)
[![Download](https://img.shields.io/cocoapods/dt/FTPopOverMenu.svg?maxAge=2592000)](http://cocoapods.org/pods/FTPopOverMenu)
[![CocoaPods](https://img.shields.io/cocoapods/at/FTPopOverMenu.svg?maxAge=2592000)](http://cocoapods.org/pods/FTPopOverMenu)
[![CocoaPods](https://img.shields.io/cocoapods/metrics/doc-percent/FTPopOverMenu.svg?maxAge=2592000)](http://cocoapods.org/pods/FTPopOverMenu)
[![CI Status](http://img.shields.io/travis/liufengting/FTPopOverMenu.svg?style=flat)](https://travis-ci.org/liufengting/FTPopOverMenu)
[![GitHub stars](https://img.shields.io/github/stars/liufengting/FTPopOverMenu.svg)](https://github.com/liufengting/FTPopOverMenu/stargazers)
[![Gitter](https://badges.gitter.im/liufengting/FTPopOverMenu.svg)](https://gitter.im/liufengting/FTPopOverMenu?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

`FTPopOverMenu` is a pop over menu for `iOS` which is maybe the easiest one to use, supports both `portrait` and `landscape`. It can show from any `UIView`, any `UIBarButtonItem` and any `CGRect`. Simplest APIs, enable you to change the style in one line of code.

# ScreenShots

<img src="/ScreenShots/Demo.gif" width="250"/>

# Installation

## Manually

* clone this repo.
* Simply drop the '/FTPopOverMenu' folder into your project.
* import 'FTPopOverMenu.h'

## CocoaPods
`FTPopOverMenu` is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'FTPopOverMenu'
```

# Usage

## Customize

Do any of the following settings to set the style (Only set the ones you want to change), maybe do this when app starts or when you want it to show a different style, but remember it's global change.

```objective-c
    FTPopOverMenuConfiguration *configuration = [FTPopOverMenuConfiguration defaultConfiguration];
    configuration.menuRowHeight = ...
    configuration.menuWidth = ...
    configuration.textColor = ...
    configuration.textFont = ...
    configuration.tintColor = ...
    configuration.borderColor = ...
    configuration.borderWidth = ...
    configuration.textAlignment = ...
    configuration.ignoreImageOriginalColor = ...;// set 'ignoreImageOriginalColor' to YES, images color will be same as textColor
```


## ~~setTintColor, default is gray color.~~ deprecated after 1.2.0

```objective-c
    [FTPopOverMenu setTintColor:[UIColor redColor]];
```
## ~~setTextColor, default is white color.~~ deprecated after 1.2.0

```objective-c
    [FTPopOverMenu setTextColor:[UIColor blackColor]];
```

## ~~setPreferedWidth, default is 120, should not be less than 50.~~ deprecated after 1.2.0

```objective-c
    [FTPopOverMenu setPreferedWidth:200];
```

## From SenderView, Menu Without Images.
 
```objective-c
    [FTPopOverMenu showForSender:sender
                        withMenu:@[@"MenuOne",@"MenuTwo",@"MenuThr"]
                       doneBlock:^(NSInteger selectedIndex) {
                           
                       } dismissBlock:^{
                          
                       }];
```

## From SenderView, Menu With Images.
 
```objective-c
    [FTPopOverMenu showForSender:sender
                        withMenu:@[@"MenuOne",@"MenuTwo",@"MenuThr"]
                  imageNameArray:@[@"setting_icon",@"setting_icon",@"setting_icon"]
                       doneBlock:^(NSInteger selectedIndex) {
                           
                       } dismissBlock:^{
                          
                       }];
```
## From SenderFrame/NavigationItem, Menu Without Images.
 
```objective-c
    [FTPopOverMenu showFromSenderFrame:CGRectMake(self.view.frame.size.width - 40, 20, 40, 40)
                              withMenu:@[@"123",@"234",@"345"]
                             doneBlock:^(NSInteger selectedIndex) {
                                 
                             } dismissBlock:^{
                                 
                             }];
```

## From SenderFrame/NavigationItem, Menu With Images.
 
```objective-c
    [FTPopOverMenu showFromSenderFrame:CGRectMake(self.view.frame.size.width - 40, 20, 40, 40)
                              withMenu:@[@"123",@"234",@"345"]
                        imageNameArray:@[@"setting_icon",@"setting_icon",@"setting_icon"]
                             doneBlock:^(NSInteger selectedIndex) {
                                 
                             } dismissBlock:^{
                                 
                             }];
```

## From barButtonItems .

- First: add action with event to you barButtonItems 

```objective-c
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleDone target:self action:@selector(onNavButtonTapped:event:)]];
```

- Second: implement the action

```objective-c
-(void)onNavButtonTapped:(UIBarButtonItem *)sender event:(UIEvent *)event
{

    [FTPopOverMenu showFromEvent:event
                        withMenu:@[@"123",@"234",@"345"]
                  imageNameArray:@[@"setting_icon",@"setting_icon",@"setting_icon"]
                       doneBlock:^(NSInteger selectedIndex) {
                           
                       } dismissBlock:^{
                           
                       }];
}
```

# CHANGELOG

[CHANGELOG](https://github.com/liufengting/FTPopOverMenu/blob/master/CHANGELOG.md)

# More

* Images in the demo from [https://www.iconfinder.com/iconsets/pokemon-go](https://www.iconfinder.com/iconsets/pokemon-go).
* If you like it, or maybe wanna use it in your own projects, please give me a `star`.
* Looking for another way of doing this? Take a look at my another [FTPopMenu at here](https://github.com/liufengting/FTPopMenu).  It was another way of showing pop over menus, which is wrapped from `UIPopoverViewController`, and more genetic and more good-looking. Feel free to try it.
 

<img src="https://raw.githubusercontent.com/liufengting/FTPopMenu/master/ScreenShots/ScreenShots2.png" width="400"/>


# License

`FTPopOverMenu` is available under the `MIT` license. See the `LICENSE` file for more info.


