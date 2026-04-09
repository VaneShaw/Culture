//
//  TalkSegmentListViewController.m
//  YiTongProject
//
//  每个 segment 对应一个独立的列表 VC
//

#import "TalkSegmentListViewController.h"
#import "TalkTableViewCell.h"
#import "TalkTopicHomeViewController.h"
#import "YTTalkSceneItem.h"
#import "HeaderConfig.h"
#import <MJRefresh/MJRefresh.h>

@interface TalkSegmentListViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<YTTalkSceneItem *> *dataSource;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) void (^scrollCallback)(UIScrollView *scrollView);
@property (nonatomic, assign) BOOL isRequesting;

@end

@implementation TalkSegmentListViewController

- (instancetype)initWithType:(NSString *)type {
    self = [super init];
    if (self) {
        _type = [type copy];
        _dataSource = [NSMutableArray array];
        _isRequesting = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    [self.view addSubview:self.tableView];
    
    __weak typeof(self) weakSelf = self;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf reloadData];
    }];
    
    // 初次加载
    [self.tableView.mj_header beginRefreshing];
}

#pragma mark - 数据

- (void)reloadData {
    __weak typeof(self) weakSelf = self;
    [self yt_fetchSceneCardsWithType:self.type completion:^(NSArray<YTTalkSceneItem *> *models) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (models) {
            self.dataSource = [models mutableCopy] ?: [NSMutableArray array];
            [self.tableView reloadData];
        }
        [self.tableView.mj_header endRefreshing];
    }];
}

/// 相对路径 `cover_image` 与完整 URL 统一为可加载地址（与 HOST 拼接）
- (NSString *)yt_fullImageURLStringFromCoverPath:(nullable NSString *)coverPath {
    NSString *raw = [coverPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (raw.length == 0) return @"";
    if ([raw.lowercaseString hasPrefix:@"http://"] || [raw.lowercaseString hasPrefix:@"https://"]) {
        return raw;
    }
    NSString *host = [HOST copy];
    while ([host hasSuffix:@"/"]) {
        host = [host substringToIndex:host.length - 1];
    }
    NSString *path = raw;
    if (![path hasPrefix:@"/"]) {
        path = [NSString stringWithFormat:@"/%@", path];
    }
    return [NSString stringWithFormat:@"%@%@", host, path];
}

/// 将 banner tab 的 type 映射为接口 `tab_type`（仅 all/hot/new 为文档约定，其余走 all 避免无效请求）
- (NSString *)yt_tabTypeBodyValueForSegmentType:(NSString *)type {
    NSString *t = [type stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
    if (t.length == 0) return @"all";
    if ([t isEqualToString:@"hot"] || [t isEqualToString:@"new"] || [t isEqualToString:@"all"]) {
        return t;
    }
    return @"all";
}

/// 请求当前 tab 下的场景列表（POST `/talk/scene`，Body：`lang`、`tab_type`）
- (void)yt_fetchSceneCardsWithType:(NSString *)type completion:(void (^)(NSArray<YTTalkSceneItem *> *models))completion {
    if (self.isRequesting) {
        if (completion) completion(nil);
        return;
    }
    self.isRequesting = YES;

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    params[@"tab_type"] = [self yt_tabTypeBodyValueForSegmentType:type];

    __weak typeof(self) weakSelf = self;
    [HttpTools postRequest:@"/talk/scene" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isRequesting = NO;
        NSArray<YTTalkSceneItem *> *list = @[];
        if (success) {
            list = [YTTalkSceneItem itemsByParsingAPIData:response.data];
        }
        if (completion) completion(list);
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isRequesting = NO;
        if (completion) completion(@[]);
    }];
}

#pragma mark - JXPagerViewListViewDelegate

- (UIView *)listView {
    return self.view;
}

- (UIScrollView *)listScrollView {
    return self.tableView;
}

- (void)listViewDidScrollCallback:(void (^)(UIScrollView * _Nonnull))callback {
    self.scrollCallback = callback;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.scrollCallback) {
        self.scrollCallback(scrollView);
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 卡片容器 190 + 上下间隔 20（让阴影/圆角有留白）
    return 210.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TalkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TalkCell"];
    if (!cell) {
        cell = [[TalkTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TalkCell"];
    }

    if (indexPath.row < 0 || indexPath.row >= self.dataSource.count) {
        return cell;
    }

    YTTalkSceneItem *m = self.dataSource[indexPath.row];
    [cell configureWithTitle:m.title ?: @"" subtitle:m.subtitle ?: @"" imageUrl:[self yt_fullImageURLStringFromCoverPath:m.coverImagePath] progressPercent:m.sceneProgressPercent];
    return cell;
}

/// 学习流与本地进度用的 scene 字符串：`/talk/scene` 列表项里的 `id` 即该场景的 `scene_id`，用十进制字符串（与接口一致）
- (NSString *)yt_learningSceneIdForSceneItem:(YTTalkSceneItem *)m {
    if (!m) return @"";
    if (m.sceneId > 0) {
        return [NSString stringWithFormat:@"%ld", (long)m.sceneId];
    }
    return @"scene_school";
}

/// 进入场景首页（与 `TalkTopicHomeViewController` 内学习流登录校验一致，此处先拦列表点击）
- (void)yt_pushTopicHomeWithSceneItem:(YTTalkSceneItem *)m {
    if (!m || !self.navigationController) return;
    TalkTopicHomeViewController *vc = [[TalkTopicHomeViewController alloc] init];
    vc.talkSceneNumericId = m.sceneId;
    vc.talkLearningSceneId = [self yt_learningSceneIdForSceneItem:m];
    vc.scenePageTitle = m.title;
    vc.scenePageSubtitle = m.subtitle;
    vc.sceneListCoverImageURLString = [self yt_fullImageURLStringFromCoverPath:m.coverImagePath];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < 0 || indexPath.row >= self.dataSource.count) return;

    YTTalkSceneItem *m = self.dataSource[indexPath.row];
    if (![[UserModel sharedInstance] isLogin]) {
        __weak typeof(self) weakSelf = self;
        [[LoginManager sharedManager] handleLoginExpiredWithCompletion:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            if ([[UserModel sharedInstance] isLogin]) {
                [self yt_pushTopicHomeWithSceneItem:m];
            }
        }];
        return;
    }
    [self yt_pushTopicHomeWithSceneItem:m];
}

@end
