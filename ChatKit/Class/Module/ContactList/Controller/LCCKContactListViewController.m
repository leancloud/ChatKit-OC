//
//  LCCKContactListViewController.m
//  LeanCloudChatKit-iOS
//
//  v0.8.5 Created by ElonChan on 16/2/22.
//  Copyright © 2016年 LeanCloud. All rights reserved.
//

#import "LCCKContactListViewController.h"
#import "LCCKContactCell.h"
#import "LCCKAlertController.h"
#import "LCCKUIService.h"

#if __has_include(<CYLDeallocBlockExecutor/CYLDeallocBlockExecutor.h>)
#import <CYLDeallocBlockExecutor/CYLDeallocBlockExecutor.h>
#else
#import "CYLDeallocBlockExecutor.h"
#endif

NSString *const LCCKContactListViewControllerContactsDidChanged = @"LCCKContactListViewControllerContactsDidChanged";
static NSString *const LCCKContactListViewControllerIdentifier = @"LCCKContactListViewControllerIdentifier";

@interface LCCKContactListViewController ()<UISearchBarDelegate,UISearchDisplayDelegate>
@property (nonatomic, copy) LCCKSelectedContactCallback selectedContactCallback;

@property (nonatomic, copy) LCCKSelectedContactsCallback selectedContactsCallback;
@property (nonatomic, copy) LCCKDeleteContactCallback deleteContactCallback;

#pragma mark - origin TableView
///=============================================================================
/// @name origin TableView
///=============================================================================

@property (nonatomic, copy) NSDictionary *originSections;
@property (nonatomic, copy) NSArray<NSString *> *userNames;
@property (nonatomic, assign) NSInteger numberOfSectionsInTableView;

#pragma mark - searchResults TableView
///=============================================================================
/// @name searchResults TableView
///=============================================================================

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, strong) UISearchDisplayController *searchController;
#pragma clang diagnostic pop
@property (nonatomic, copy) NSArray *searchContacts;
@property (nonatomic, copy) NSDictionary *searchSections;
@property (nonatomic, copy) NSSet<NSString *> *searchUserIds;

#pragma mark - TableView Contoller
///=============================================================================
/// @name TableView Contoller
///=============================================================================

@property (nonatomic, strong) NSMutableDictionary *dictionaryTableRowCheckedState;
@property (nonatomic, copy) NSString *selectedContact;
@property (nonatomic, strong) NSMutableArray *selectedContacts;

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, copy) NSSet *visiableUserIds;
@property (nonatomic, copy) NSSet *visiableContacts;
@property (nonatomic, assign, getter=isNeedReloadDataSource) BOOL needReloadDataSource;

@end

@implementation LCCKContactListViewController
@synthesize title = _title;

- (instancetype)initWithContacts:(NSSet<LCCKContact *> *)contacts
                            mode:(LCCKContactListMode)mode {
    return [self initWithContacts:contacts excludedUserIds:nil mode:mode];
}

- (instancetype)initWithContacts:(NSSet<LCCKContact *> *)contacts
                 excludedUserIds:(NSSet *)excludedUserIds
                            mode:(LCCKContactListMode)mode {
    return [self initWithContacts:contacts userIds:[NSSet set] excludedUserIds:excludedUserIds mode:mode];
}

- (instancetype)initWithUserIds:(NSSet<NSString *> *)userIds
                excludedUserIds:(NSSet *)excludedUserIds
                           mode:(LCCKContactListMode)contactListMode {
    return [self initWithContacts:nil userIds:userIds excludedUserIds:excludedUserIds mode:contactListMode];
}

- (instancetype)initWithUserIds:(NSSet<NSString *> *)userIds
                           mode:(LCCKContactListMode)contactListMode {
    return [self initWithUserIds:userIds excludedUserIds:nil mode:contactListMode];
}

- (instancetype)initWithContacts:(NSSet<LCCKContact *> *)contacts
                         userIds:(NSSet<NSString *> *)userIds
                 excludedUserIds:(NSSet *)excludedUserIds
                            mode:(LCCKContactListMode)mode {
    self = [super init];
    if (!self) {
        return nil;
    }
    _contacts = contacts;
    _excludedUserIds = excludedUserIds;
    _mode = mode;
    _userIds = userIds;
    //TODO:
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSourceUpdated:) name:LCCKNotificationContactListDataSourceUpdated object:nil];
    __unsafe_unretained __typeof(self) weakSelf = self;
    [self cyl_executeAtDealloc:^{
        [[NSNotificationCenter defaultCenter] removeObserver:weakSelf];
    }];
    return self;
}

#pragma mark -
#pragma mark - Lazy Load Method

/**
 *  lazy load selectedContacts
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)selectedContacts {
    if (_selectedContacts == nil) {
        _selectedContacts = [[NSMutableArray alloc] init];
    }
    return _selectedContacts;
}

/**
 *  lazy load dictionaryTableRowCheckedState
 *
 *  @return NSMutableDictionary
 */
- (NSMutableDictionary *)dictionaryTableRowCheckedState {
    if (_dictionaryTableRowCheckedState == nil) {
        _dictionaryTableRowCheckedState = [[NSMutableDictionary alloc] init];
    }
    return _dictionaryTableRowCheckedState;
}

- (NSSet *)visiableUserIds {
    if (_visiableUserIds) {
        return _visiableUserIds;
    }
    if (!_userIds || _userIds.count == 0) {
        return nil;
    }
    NSMutableSet *visiableUserIds = [NSMutableSet setWithSet:_userIds];
    if (self.excludedUserIds.count > 0) {
        [self.excludedUserIds enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
            [visiableUserIds removeObject:obj];
        }];
    }
    _visiableUserIds = [visiableUserIds copy];
    return _visiableUserIds;
}

- (NSSet *)visiableContacts {
    if (_visiableContacts) {
        return _visiableContacts;
    }
    if (!_contacts || _contacts.count == 0) {
        return nil;
    }
    NSMutableSet *visiableContacts = [NSMutableSet setWithSet:_contacts];
    if (self.excludedUserIds.count > 0) {
        [self.excludedUserIds enumerateObjectsUsingBlock:^(NSString * _Nonnull clientId, BOOL * _Nonnull stop) {
            NSSet *removedSet = [visiableContacts filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"clientId == %@", clientId]];
            [removedSet enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                [visiableContacts removeObject:obj];
            }];
        }];
        _visiableContacts = [visiableContacts copy];
    }
    return _visiableContacts;
}

#pragma mark -
#pragma mark - Setter Method

- (void)setSelectedContact:(NSString *)selectedContact {
    _selectedContact = [selectedContact copy];
    if (selectedContact) {
        [self selectedContactCallback](self, selectedContact); //Callback callback to update parent TVC
    }
}
- (UISearchBar *)searchBar {
    if (!_searchBar) {
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 44)];
        searchBar.delegate = self;
        searchBar.placeholder = @"搜索";
        _searchBar = searchBar;
        self.tableView.tableHeaderView = _searchBar;
    }
    return _searchBar;
}

- (void)setNeedReloadDataSource:(BOOL)needReloadDataSource {
    _needReloadDataSource = needReloadDataSource;
    if (needReloadDataSource) {
        _originSections = nil;
        _visiableUserIds = nil;
        _visiableContacts = nil;
        _numberOfSectionsInTableView = 0;
    }
}

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"联系人";
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.tableFooterView = [[UIView alloc] init];
    NSBundle *bundle = [NSBundle bundleForClass:[LCChatKit class]];
    [self setupSearchBarControllerWithSearchBar:self.searchBar bundle:bundle];
    [self.tableView registerNib:[UINib nibWithNibName:@"LCCKContactCell" bundle:bundle]
         forCellReuseIdentifier:LCCKContactListViewControllerIdentifier];
    self.tableView.separatorColor = [UIColor colorWithWhite:1.f*0xdf/0xff alpha:1.f];
    if ([self.tableView respondsToSelector:@selector(setSectionIndexBackgroundColor:)]) {
        self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    }
    [self.navigationItem setTitle:@"联系人"];
    if (self.mode == LCCKContactListModeNormal) {
        self.navigationItem.title = self.title ?: @"联系人";
    } else {
        self.navigationItem.title = self.title ?: @"选择联系人";
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                        target:self
                                                                                        action:@selector(doneBarButtonItemPressed:)];
        self.navigationItem.rightBarButtonItem = doneButtonItem;
    }

    !self.viewDidLoadBlock ?: self.viewDidLoadBlock(self);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)setupSearchBarControllerWithSearchBar:(UISearchBar *)searchBar bundle:(NSBundle *)bundle {
    UISearchDisplayController *searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    // searchResultsDataSource 就是 UITableViewDataSource
    searchDisplayController.searchResultsDataSource = self;
    // searchResultsDelegate 就是 UITableViewDelegate
    searchDisplayController.searchResultsDelegate = self;
    searchDisplayController.delegate = self;
    self.searchController = searchDisplayController;
    searchDisplayController.searchResultsTableView.tableFooterView = [[UIView alloc] init];
    [searchDisplayController.searchResultsTableView registerNib:[UINib nibWithNibName:@"LCCKContactCell" bundle:bundle]
                                         forCellReuseIdentifier:LCCKContactListViewControllerIdentifier];
}

#pragma clang diagnostic pop

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.presentingViewController) {
        UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(cancelBarButtonItemPressed:)];
        self.navigationItem.leftBarButtonItem = cancelButtonItem;
    }
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [self setDictionaryTableRowCheckedState:[NSMutableDictionary dictionary]];
    !self.viewWillAppearBlock ?: self.viewWillAppearBlock(self, animated);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    [self _reloadData];
    if (!_contacts || _contacts.count == 0) {
        [self forceReloadByUserId];
    }
    !self.viewDidAppearBlock ?: self.viewDidAppearBlock(self, animated);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.mode == LCCKContactListModeMultipleSelection) {
        //  Return an array of selectedContacts
        [self selectedContactsCallback](self, [self.selectedContacts copy]);

        return;
    }
    !self.viewWillDisappearBlock ?: self.viewWillDisappearBlock(self, animated);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.needReloadDataSource = YES;
    !self.viewDidDisappearBlock ?: self.viewDidDisappearBlock(self, animated);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    !self.didReceiveMemoryWarningBlock ?: self.didReceiveMemoryWarningBlock(self);
}

- (void)dealloc {
    !self.viewControllerWillDeallocBlock ?: self.viewControllerWillDeallocBlock(self);
}

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (![tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        if (_numberOfSectionsInTableView > 0) {
            return _numberOfSectionsInTableView;
        }
        _numberOfSectionsInTableView = [self sortedSectionTitlesForTableView:tableView].count;
        return _numberOfSectionsInTableView;
    }
    NSInteger numberOfSectionsInTableView = [self sortedSectionTitlesForTableView:tableView].count;
    return numberOfSectionsInTableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *sectionKey = [self sortedSectionTitlesForTableView:tableView][(NSUInteger)section];
    NSSet *array = [self currentSectionsForTableView:tableView][sectionKey];
    return (NSInteger)array.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LCCKContactCell *cell = [tableView dequeueReusableCellWithIdentifier:LCCKContactListViewControllerIdentifier forIndexPath:indexPath];
    id contact = [self contactAtIndexPath:indexPath tableView:tableView];
    NSURL *avatarURL = nil;
    NSString *name = nil;
    NSString *clientId = nil;
    if ([contact isKindOfClass:[NSString class]]) {
        name = contact;
        clientId = contact;
    } else {
        LCCKContact *contact_ = (LCCKContact *)contact;
        avatarURL = contact_.avatarURL;
        name = contact_.name ?: contact_.clientId;
        clientId = contact_.clientId;
    }
    [cell configureWithAvatarURL:avatarURL title:name subtitle:nil model:self.mode];
    BOOL isChecked = NO;
    if (self.mode == LCCKContactListModeSingleSelection) {
        if (clientId == self.selectedContact) {
            isChecked = YES;
        }
        cell.checked = isChecked;
    } else if (self.mode == LCCKContactListModeMultipleSelection) {
        if ([self.selectedContacts containsObject:clientId]) {
            isChecked = YES;
        }
        self.dictionaryTableRowCheckedState[indexPath] = @(isChecked);
        cell.checked = isChecked;
    } else {
        // NSLog(@"%@ - %@ - has (possible undefined) E~R~R~O~R attempting to set UITableViewCellAccessory at indexPath: %@_", NSStringFromClass(self.class), NSStringFromSelector(_cmd), indexPath);
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self sortedSectionTitlesForTableView:tableView][(NSUInteger)section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self sortedSectionTitlesForTableView:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}
#pragma mark - Helpers

- (id)contactAtIndexPath:(NSIndexPath*)indexPath {
    return [self contactAtIndexPath:indexPath tableView:self.tableView];
}

- (id)contactAtIndexPath:(NSIndexPath*)indexPath tableView:(UITableView *)tableView {
    NSArray *contactsGroupedInSections = [self sortedSectionTitlesForTableView:tableView];
    if (indexPath.section < contactsGroupedInSections.count) {
        NSString *sectionKey = contactsGroupedInSections[(NSUInteger)indexPath.section];
        NSArray *contactsInSection = [self currentSectionsForTableView:tableView][sectionKey];
        if (indexPath.row < contactsInSection.count) {
            id contact = contactsInSection[(NSUInteger)indexPath.row];
            return contact;
        }
    }
    return nil;
}

- (NSString *)currentClientIdAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    
    id contact = [self contactAtIndexPath:indexPath tableView:tableView];
    if ([contact isKindOfClass:[NSString class]]) {
        return contact;
    }
    LCCKContact *contact_ = contact;
    NSString *clientId = contact_.clientId;
    return clientId;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LCCKContactCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *clientId = [self currentClientIdAtIndexPath:indexPath tableView:tableView];
    if (self.mode == LCCKContactListModeSingleSelection) {
        if (clientId == self.selectedContact) {
            cell.checked = NO;
            self.selectedContact = nil;
        } else {
            cell.checked = YES;
            self.selectedContact = clientId;
        }
        [self.searchController setActive:NO animated:NO];
        [self _reloadData:tableView];
        return;
    }
    if (self.mode == LCCKContactListModeMultipleSelection) {
        //  Toggle the cell checked state
        __block BOOL isChecked = !((NSNumber *)self.dictionaryTableRowCheckedState[indexPath]).boolValue;
        self.dictionaryTableRowCheckedState[indexPath] = @(isChecked);
        cell.checked = isChecked;
        if (isChecked) {
            [self.selectedContacts addObject:clientId];
        } else {
            [self.selectedContacts removeObject:clientId];
        }
        [self _reloadData:tableView];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.searchController setActive:NO animated:NO];
    self.selectedContact = clientId;
    [self _reloadData:tableView];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        return NO;
    }
#pragma clang diagnostic pop
    if (self.mode == LCCKContactListModeNormal) {
        return YES;
    }
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)setUserIds:(NSSet<NSString *> *)userIds {
    _userIds = [userIds copy];
    [self forceReloadByUserId];
}

- (NSSet *)userIdsFrom:(NSSet *)contacts {
    NSMutableSet *userIds = [NSMutableSet setWithCapacity:contacts.count];
    [contacts enumerateObjectsUsingBlock:^(id<LCCKUserDelegate> _Nonnull contact, BOOL * _Nonnull stop) {
        [userIds addObject:contact.clientId];
    }];
    return [userIds copy];
}

- (void)setContacts:(NSSet<LCCKContact *> *)contacts {
    _contacts = [contacts copy];
    _userIds = [self userIdsFrom:contacts];
    [self forceReloadByContacts];
}

- (void)dataSourceUpdated:(NSNotification *)notification {
    if (notification.object == nil) {
        return;
    }
    //TODO:
//    NSDictionary *userInfo = [notification object];
//    NSSet *dataSource = userInfo[LCCKNotificationContactListDataSourceUpdatedUserInfoDataSourceKey];
//    NSString *dataSourceType = userInfo[LCCKNotificationContactListDataSourceUpdatedUserInfoDataSourceTypeKey];
//    if ([dataSourceType isEqualToString:LCCKNotificationContactListDataSourceContactObjType]) {
//        self.contacts = dataSource;
//    } else {
//        
//    }
}

- (void)forceReloadByContacts {
    self.needReloadDataSource = YES;
}

- (void)forceReloadByUserId {
    if (!_userIds || _userIds.count == 0) {
        return;
    }
    /**
     *   这里不考虑查询人数与返回人数不一致的情况，比如查询100人，服务器只返回一人，那么也只显示一人，其余99人不予显示
     */
    LCCKHUDActionBlock theHUDActionBlock = [LCCKUIService sharedInstance].HUDActionBlock;
    if (theHUDActionBlock) {
        theHUDActionBlock(self, nil, @"获取联系人信息...", LCCKMessageHUDActionTypeShow);
    }
    [[LCChatKit sharedInstance] getProfilesInBackgroundForUserIds:[NSArray arrayWithArray:[_userIds allObjects]] callback:^(NSArray<id<LCCKUserDelegate>> *users, NSError *error) {
        if (theHUDActionBlock) {
            theHUDActionBlock(self, nil, nil, LCCKMessageHUDActionTypeHide);
        }
        if (users.count > 0) {
            if (theHUDActionBlock) {
                theHUDActionBlock(self, nil, @"获取成功", LCCKMessageHUDActionTypeSuccess);
            }
            self.contacts = [NSSet setWithArray:users];
        } else {
            //在添加 UserIds（ClientIds） 的情况下，但获取用户信息失败的情况下，也刷新，至少展示 UserIds（ClientIds）。
            self.needReloadDataSource = YES;
            if (theHUDActionBlock) {
                theHUDActionBlock(self, nil, @"获取失败", LCCKMessageHUDActionTypeError);
            }
        }
        [self.tableView reloadData];
    }];
}

- (void)deleteClientId:(NSString *)clientId {
    NSMutableSet<LCCKContact *> *allMutableSet = [NSMutableSet setWithSet:_contacts];
    NSSet *deleteSet = [allMutableSet filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"clientId == %@", clientId]];
    [deleteSet enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        [allMutableSet removeObject:obj];
    }];
    if (_contacts.count == allMutableSet.count) {
         NSMutableSet<NSString *> *array = [NSMutableSet setWithSet:_userIds];
        [array removeObject:clientId];
        self.userIds = [array copy];
    } else {
        self.contacts = [allMutableSet copy];
    }
}

//TOO:
//- (void)deletePeerId:(NSString *)peerId callback:(LCCKDeleteContactCallback)deleteContactCallback {
//    [self deleteClientId:peerId];
//    !deleteContactCallback ?: deleteContactCallback(self, peerId);
//}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.mode == LCCKContactListModeNormal) {
        NSString *peerId = [self currentClientIdAtIndexPath:indexPath tableView:tableView];
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSString *title = [NSString stringWithFormat:@"%@?",
                               LCCKLocalizedStrings(@"ConfirmDeletion")
                               ];
            LCCKAlertController *alert = [LCCKAlertController alertControllerWithTitle:title
                                                                               message:@""
                                                                        preferredStyle:LCCKAlertControllerStyleAlert];
            NSString *cancelActionTitle = LCCKLocalizedStrings(@"cancel");
            LCCKAlertAction* cancelAction = [LCCKAlertAction actionWithTitle:cancelActionTitle style:LCCKAlertActionStyleDefault
                                                                     handler:^(LCCKAlertAction * action) {}];
            [alert addAction:cancelAction];
            NSString *resendActionTitle = LCCKLocalizedStrings(@"ok");
            LCCKAlertAction* resendAction = [LCCKAlertAction actionWithTitle:resendActionTitle style:LCCKAlertActionStyleDefault
                                                                     handler:^(LCCKAlertAction * action) {
                                                                         if (self.deleteContactCallback) {
                                                                             BOOL delegateSuccess = self.deleteContactCallback(self, peerId);
                                                                             if (delegateSuccess) {
                                                                                 [self deleteClientId:peerId];
                                                                                 [self _reloadDataAfterDeleteData:tableView];
                                                                             }
                                                                         }
                                                                     }];
            [alert addAction:resendAction];
            [alert showWithSender:nil controller:self animated:YES completion:NULL];
        }
    }
}

#pragma mark - Data

- (NSDictionary *)currentSectionsForTableView:(UITableView *)tableView {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        return self.searchSections;
    }
#pragma clang diagnostic pop
    return self.originSections;
}

- (NSSet *)contactsFromContactsOrUserIds:(NSSet *)contacts userIds:(NSSet *)userIds{
    if (contacts.count > 0) {
        return contacts;
    } else {
        return userIds;
    }
}

- (NSMutableDictionary *)sortedSectionForUserNames:(NSSet *)contactsOrUserNames {
    NSMutableDictionary *originSections = [NSMutableDictionary dictionary];
    [contactsOrUserNames enumerateObjectsUsingBlock:^(id  _Nonnull contactOrUserName, BOOL * _Nonnull stop) {
        NSString *userName;
        LCCKContact *contact;
        if ([contactOrUserName isKindOfClass:[NSString class]]) {
            userName = (NSString *)contactOrUserName;
        } else {
            contact = (LCCKContact *)contactOrUserName;
            userName = contact.name ?: contact.clientId;
        }

        NSString *indexKey = [self indexTitleForName:userName];
        NSMutableArray *names = originSections[indexKey];
        if (!names) {
            names = [NSMutableArray array];
            originSections[indexKey] = names;
        }
        [names addObject:contactOrUserName];
    }];
    return originSections;
}

- (NSDictionary *)searchSections {
    if (!_searchSections) {
        NSSet *set = [NSSet setWithArray:self.searchContacts];
        _searchSections = [self sortedSectionForUserNames:[self contactsFromContactsOrUserIds:set userIds:self.searchUserIds]];
    }
    return _searchSections;
}

- (NSDictionary *)originSections {
    if (!_originSections) {
        _originSections = [self sortedSectionForUserNames:[self contactsFromContactsOrUserIds:self.visiableContacts userIds:self.visiableUserIds]];
    }
    return _originSections;
}

- (NSArray *)sortedSectionTitlesForTableView:(UITableView *)tableView {
    return [[[self currentSectionsForTableView:tableView] allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSString *)indexTitleForName:(NSString *)name {
    static NSString *otherKey = @"#";
    if (!name) {
        return otherKey;
    }
    NSMutableString *mutableString = [NSMutableString stringWithString:[name substringToIndex:1]];
    CFMutableStringRef mutableStringRef = (__bridge CFMutableStringRef)mutableString;
    CFStringTransform(mutableStringRef, nil, kCFStringTransformToLatin, NO);
    CFStringTransform(mutableStringRef, nil, kCFStringTransformStripCombiningMarks, NO);
    
    NSString *key = [[mutableString uppercaseString] substringToIndex:1];
    unichar capital = [key characterAtIndex:0];
    if (capital >= 'A' && capital <= 'Z') {
        return key;
    }
    return otherKey;
}

- (void)cancelBarButtonItemPressed:(id)sender {
    self.selectedContacts = nil;
    [self dismissViewControllerAnimated:YES completion:NULL];
    !self.viewDidDismissBlock ?: self.viewDidDismissBlock(self);
}

- (void)doneBarButtonItemPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
    !self.viewDidDismissBlock ?: self.viewDidDismissBlock(self);
}

- (void)_reloadDataAfterDeleteData:(UITableView *)tableView {
    [tableView reloadData];
    [self _reloadData:tableView];
}

- (void)reloadAllTableViewData:(UITableView *)tableView {
    [self _reloadData:tableView];
    [self _reloadData:self.tableView];
}

/*!
 *  don't want to reload sections while reloading cells.
 */
- (void)_reloadData:(UITableView *)tableView {
    [tableView reloadRowsAtIndexPaths:[tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)_reloadData {
    [self _reloadData:self.tableView];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self.searchController setActive:YES animated:YES];
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView {
    [self reloadAllTableViewData:tableView];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    UIButton *cancelButton;
    UIView *topView = self.searchBar.subviews[0];
    for (UIView *subView in topView.subviews) {
        if ([subView isKindOfClass:NSClassFromString(@"UINavigationButton")]) {
            cancelButton = (UIButton *)subView;
        }
    }
    if (cancelButton) {
        [cancelButton setTitle:LCCKLocalizedStrings(@"done") forState:UIControlStateNormal];
    }
}

#pragma mark - UISearchDisplayDelegate

// return YES to reload table. called when search string/option changes. convenience methods on top UISearchBar delegate methods
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(nullable NSString *)searchString {
    [self filterContentForSearchText:searchString];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    return YES;
}

#pragma clang diagnostic pop

- (void)filterContentForSearchText:(NSString *)searchString {
    self.searchSections = nil;
    //  for (NSString *searchString in searchItems) {
    // each searchString creates an OR predicate for: name, id
    //
    // example if searchItems contains "iphone 599 2007":
    //      name CONTAINS[c] "lanmaq"
    //      id CONTAINS[c] "1568689942"
    if (!self.visiableContacts) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", searchString];
        self.searchUserIds = [self.visiableUserIds filteredSetUsingPredicate:predicate];
        self.searchContacts = nil;
        return;
    }
    NSMutableSet *searchResults = [self.visiableContacts mutableCopy];


    NSMutableArray *andMatchPredicates = [NSMutableArray array];
    NSMutableArray *searchItemsPredicate = [NSMutableArray array];
    
    // use NSExpression represent expressions in predicates.
    // NSPredicate is made up of smaller, atomic parts: two NSExpressions (a left-hand value and a right-hand value)
    
    // name field matching
    NSExpression *leftExpression = [NSExpression expressionForKeyPath:@"name"];
    NSExpression *rightExpression = [NSExpression expressionForConstantValue:searchString];
    NSPredicate *finalPredicate = [NSComparisonPredicate
                                   predicateWithLeftExpression:leftExpression
                                   rightExpression:rightExpression
                                   modifier:NSDirectPredicateModifier
                                   type:NSContainsPredicateOperatorType
                                   options:NSCaseInsensitivePredicateOption];
    [searchItemsPredicate addObject:finalPredicate];
    
    // userId field matching
    leftExpression = [NSExpression expressionForKeyPath:@"userId"];
    rightExpression = [NSExpression expressionForConstantValue:searchString];
    finalPredicate = [NSComparisonPredicate
                      predicateWithLeftExpression:leftExpression
                      rightExpression:rightExpression
                      modifier:NSDirectPredicateModifier
                      type:NSContainsPredicateOperatorType
                      options:NSCaseInsensitivePredicateOption];
    [searchItemsPredicate addObject:finalPredicate];
    
    // ClientId field matching
    leftExpression = [NSExpression expressionForKeyPath:@"clientId"];
    rightExpression = [NSExpression expressionForConstantValue:searchString];
    finalPredicate = [NSComparisonPredicate
                      predicateWithLeftExpression:leftExpression
                      rightExpression:rightExpression
                      modifier:NSDirectPredicateModifier
                      type:NSContainsPredicateOperatorType
                      options:NSCaseInsensitivePredicateOption];
    [searchItemsPredicate addObject:finalPredicate];
    
    // at this OR predicate to our master AND predicate
    NSCompoundPredicate *orMatchPredicates = [NSCompoundPredicate orPredicateWithSubpredicates:searchItemsPredicate];
    [andMatchPredicates addObject:orMatchPredicates];
    
    // match up the fields of the Product object
    NSCompoundPredicate *finalCompoundPredicate =
    [NSCompoundPredicate andPredicateWithSubpredicates:andMatchPredicates];
    self.searchContacts = [NSArray arrayWithArray:[[searchResults filteredSetUsingPredicate:finalCompoundPredicate] allObjects]];
    [self _reloadData];
}

@end
