//
//  YTVFavoritesListViewController.m
//  YiTongProject
//

#import "YTVFavoritesListViewController.h"
#import "YTVFavoritesListViewModel.h"
#import "YTVFavoritesListCell.h"
#import "YTVShortVideoFeedViewController.h"
#import "YTVVideoFeedItem.h"
#import "HeaderConfig.h"

static NSString * const kYTVFavListCellId = @"YTVFavoritesListCell";

@interface YTVFavoritesListViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) YTVFavoritesListViewModel *listViewModel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *emptyContainer;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIButton *gridLayoutButton;
@end

@implementation YTVFavoritesListViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.hidesBottomBarWhenPushed = YES;
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    [self addGlobalBackButtonColor:[UIColor blackColor]
                    headerTitleDic:@{ @"title": @"YTV_favorites_list_title", @"color": @"#FFFFFF" }];
    self.listViewModel = [[YTVFavoritesListViewModel alloc] init];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.emptyContainer];
    [self.emptyContainer addSubview:self.emptyLabel];
    [self.view addSubview:self.gridLayoutButton];
    CGFloat topInset = [PublicTool getStatusBarHeight] + 52;
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(topInset);
        make.left.right.bottom.equalTo(self.view);
    }];
    [self.emptyContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tableView);
    }];
    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.emptyContainer);
        make.centerY.equalTo(self.emptyContainer).offset(-40);
        make.left.greaterThanOrEqualTo(self.emptyContainer).offset(32);
        make.right.lessThanOrEqualTo(self.emptyContainer).offset(-32);
    }];
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    [self.gridLayoutButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(44);
        make.right.equalTo(self.view).offset(-12);
        make.top.equalTo(self.view).offset(statusBarH + 2);
    }];
    [self.view sendSubviewToBack:self.tableView];
    [self.view bringSubviewToFront:self.gridLayoutButton];
    [self ytv_setupRefreshHeader];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    [self ytv_beginRefresh];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)ytv_setupRefreshHeader {
    __weak typeof(self) weakSelf = self;
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self ytv_handleRefresh];
    }];
    header.automaticallyChangeAlpha = YES;
    self.tableView.mj_header = header;
}

- (void)ytv_beginRefresh {
    if (self.tableView.mj_header.isRefreshing || self.listViewModel.isLoading) {
        return;
    }
    [self.tableView.mj_header beginRefreshing];
}

/// 统一走下拉刷新回调拉取收藏列表；未登录仅刷新空态。
- (void)ytv_handleRefresh {
    if (![[UserModel sharedInstance] isLogin]) {
        [self.listViewModel clearItemsForLogout];
        [self.tableView reloadData];
        [self ytv_applyEmptyState:YES message:NSLocalizedString(@"YTV_favorites_list_need_login", @"")];
        [self.tableView.mj_header endRefreshing];
        return;
    }
    [self.listViewModel loadDiskCacheOnly];
    [self.tableView reloadData];
    [self ytv_applyEmptyState:self.listViewModel.items.count == 0 message:@""];
    __weak typeof(self) weakSelf = self;
    [self.listViewModel reloadFromCacheThenNetworkWithCompletion:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        [self.tableView reloadData];
        BOOL empty = self.listViewModel.items.count == 0;
        NSString *msg = empty
            ? NSLocalizedString(@"YTV_favorites_list_empty", @"")
            : @"";
        [self ytv_applyEmptyState:empty message:msg];
        [self.tableView.mj_header endRefreshing];
        if (error && self.listViewModel.items.count == 0) {
            [MBProgressHUD showLabel:error.localizedDescription.length ? error.localizedDescription : NSLocalizedString(@"YTV_feed_load_failed", @"")];
        }
    }];
}

- (void)ytv_applyEmptyState:(BOOL)empty message:(NSString *)message {
    self.emptyContainer.hidden = !empty;
    self.tableView.hidden = NO;
    self.emptyLabel.text = message;
}

/// 预留：宫格/列表布局切换（当前无第二套布局）。
- (void)ytv_didTapGridLayout {
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.listViewModel.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YTVFavoritesListCell *cell = [tableView dequeueReusableCellWithIdentifier:kYTVFavListCellId forIndexPath:indexPath];
    YTVVideoFeedItem *item = self.listViewModel.items[(NSUInteger)indexPath.row];
    [cell ytv_configureWithItem:item];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    YTVVideoFeedItem *item = self.listViewModel.items[(NSUInteger)indexPath.row];
    NSArray *seed = self.listViewModel.items;
    YTVShortVideoFeedViewController *feed = [[YTVShortVideoFeedViewController alloc] initWithFavoritesSeedItems:seed
                                                                                                  entryVideoId:item.videoId];
    feed.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:feed animated:YES];
}

#pragma mark - Lazy

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor blackColor];
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 300;
        [_tableView registerClass:[YTVFavoritesListCell class] forCellReuseIdentifier:kYTVFavListCellId];
    }
    return _tableView;
}

- (UIView *)emptyContainer {
    if (!_emptyContainer) {
        _emptyContainer = [[UIView alloc] init];
        _emptyContainer.backgroundColor = [UIColor clearColor];
        _emptyContainer.hidden = YES;
        _emptyContainer.userInteractionEnabled = NO;
    }
    return _emptyContainer;
}

- (UILabel *)emptyLabel {
    if (!_emptyLabel) {
        _emptyLabel = [[UILabel alloc] init];
        _emptyLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
        _emptyLabel.textColor = [self.view colorWithHexString:@"#8E8E93" alpha:1];
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.numberOfLines = 0;
    }
    return _emptyLabel;
}

- (UIButton *)gridLayoutButton {
    if (!_gridLayoutButton) {
        _gridLayoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *img = nil;
        if (@available(iOS 13.0, *)) {
            img = [UIImage systemImageNamed:@"square.grid.2x2"];
        }
        if (img) {
            img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_gridLayoutButton setImage:img forState:UIControlStateNormal];
            _gridLayoutButton.tintColor = [UIColor whiteColor];
        }
        [_gridLayoutButton addTarget:self action:@selector(ytv_didTapGridLayout) forControlEvents:UIControlEventTouchUpInside];
        _gridLayoutButton.accessibilityLabel = NSLocalizedString(@"YTV_favorites_grid_layout", @"");
    }
    return _gridLayoutButton;
}

@end
