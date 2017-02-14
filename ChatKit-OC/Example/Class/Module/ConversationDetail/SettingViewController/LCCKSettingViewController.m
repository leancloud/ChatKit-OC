//
//  LCChatKit.h
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//  Core class of LeanCloudChatKit


#import "LCCKSettingViewController.h"
#import "LCCKSettingHeaderTitleView.h"
#import "LCCKSettingFooterTitleView.h"
#import "LCCKSettingButtonCell.h"
#import "UIColor+LCCKExtension.h"
#import <ChatKit/LCChatKit.h>

@interface LCCKSettingViewController ()

@end

@implementation LCCKSettingViewController

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.tableView setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, HEIGHT_SETTING_TOP_SPACE)]];
    [self.tableView setTableFooterView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, HEIGHT_SETTING_BOTTOM_SPACE)]];
    [self.tableView setBackgroundColor:[UIColor lcck_colorGrayBG]];
    [self.tableView setLayoutMargins:UIEdgeInsetsMake(0, 15, 0, 0)];
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 15, 0, 0)];
    [self.tableView setSeparatorColor:[UIColor lcck_colorGrayLine]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[LCCKSettingHeaderTitleView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([LCCKSettingHeaderTitleView class])];
    [self.tableView registerClass:[LCCKSettingFooterTitleView class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([LCCKSettingFooterTitleView class])];
    [self.tableView registerClass:[LCCKSettingCell class] forCellReuseIdentifier:NSStringFromClass([LCCKSettingCell class])];
    [self.tableView registerClass:[LCCKSettingButtonCell class] forCellReuseIdentifier:NSStringFromClass([LCCKSettingButtonCell class])];
    [self.tableView registerClass:[LCCKSettingSwitchCell class] forCellReuseIdentifier:NSStringFromClass([LCCKSettingSwitchCell class])];
}

- (void)dealloc
{
#ifdef DEBUG_MEMERY
    NSLog(@"dealloc %@", self.navigationItem.title);
#endif
}

#pragma mark - Delegate -
//MARK: UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.data[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LCCKSettingItem *item = [self.data[indexPath.section] objectAtIndex:indexPath.row];
    id cell = [tableView dequeueReusableCellWithIdentifier:item.cellClassName];
    [cell setItem:item];
    if (item.type == LCCKSettingItemTypeSwitch) {
        [cell setDelegate:self];
    }
    return cell;
}

//MARK: UITableViewDelegate
- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    LCCKSettingGroup *group = self.data[section];
    if (group.headerTitle == nil) {
        return nil;
    }
    LCCKSettingHeaderTitleView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([LCCKSettingHeaderTitleView class])];
    [view setText:group.headerTitle];
    return view;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    LCCKSettingGroup *group = self.data[section];
    if (group.footerTitle == nil) {
        return nil;
    }
    LCCKSettingFooterTitleView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([LCCKSettingFooterTitleView class])];
    [view setText:group.footerTitle];
    return view;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return HEIGHT_SETTING_CELL;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    LCCKSettingGroup *group = self.data[section];
    return 0.5 + (group.headerTitle == nil ? 0 : 5.0f + group.headerHeight);
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    LCCKSettingGroup *group = self.data[section];
    return 20.0f + (group.footerTitle == nil ? 0 : 5.0f + group.footerHeight);
}

//MARK: TLSettingSwitchCellDelegate
- (void)settingSwitchCellForItem:(LCCKSettingItem *)settingItem didChangeStatus:(BOOL)on completionHandler:(LCCKSettingSwitchCellCompletionhandler)completionHandler {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Switch事件未被子类处理" message:[NSString stringWithFormat:@"Title: %@\nStatus: %@", settingItem.title, (on ? @"on" : @"off")] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Getter -
- (NSString *)analyzeTitle
{
    if (_analyzeTitle == nil) {
        return self.navigationItem.title;
    }
    return _analyzeTitle;
}

#pragma mark -
#pragma mark - Private Methods
- (UIImagePickerController *)pickerController {
    if (_pickerController) {
        return _pickerController;
    }
    _pickerController = [[UIImagePickerController alloc] init];
    _pickerController.delegate = self;
    return _pickerController;
}

- (UIImage *)imageInBundlePathForImageName:(NSString *)imageName {
    UIImage *image = [UIImage lcck_imageNamed:imageName bundleName:@"ChatKeyboard" bundleForClass:[self class]];
    return image;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [[LCChatKit sharedInstance] setBackgroundImage:image forConversationId:self.conversation.conversationId scaledToSize:self.view.frame.size];
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)presentSelectMemberViewControllerMemberIds:(NSArray *)memeberIds excludedUserIds:(NSArray *)excludedUserIds callback:(LCCKArrayResultBlock)callback {
    NSArray *users = [[LCChatKit sharedInstance] getCachedProfilesIfExists:memeberIds shouldSameCount:YES error:nil];
    
    NSString *currentClientID = [[LCChatKit sharedInstance] clientId];
    NSMutableArray *mutableArray = [excludedUserIds ?: @[] mutableCopy] ;
    [mutableArray  addObject:currentClientID];
    NSArray *excludedUserIds_ = [mutableArray copy];
    LCCKContactListViewController *contactListViewController = [[LCCKContactListViewController alloc] initWithContacts:[NSSet setWithArray:users] userIds:[NSSet setWithArray:memeberIds] excludedUserIds:[NSSet setWithArray:excludedUserIds_] mode:LCCKContactListModeMultipleSelection];
    [contactListViewController setSelectedContactsCallback:^(UIViewController * _Nonnull viewController, NSArray<NSString *> * _Nonnull peerIds) {
        if (!peerIds || peerIds.count == 0) { return; }
        [[self class] lcck_showHUD];
        !callback ?: callback(peerIds, nil);
    }];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:contactListViewController];
    [self presentViewController:navigationController animated:YES completion:^{}];
}

@end
