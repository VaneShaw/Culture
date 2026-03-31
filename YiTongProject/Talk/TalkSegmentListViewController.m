//
//  TalkSegmentListViewController.m
//  YiTongProject
//
//  每个 segment 对应一个独立的列表 VC
//

#import "TalkSegmentListViewController.h"
#import "TalkTableViewCell.h"
#import "TalkTopicHomeViewController.h"
#import <MJRefresh/MJRefresh.h>

@interface YTTalkSceneListItemModel : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *imageUrl;
@property (nonatomic, assign) NSInteger progressPercent;
@end

@implementation YTTalkSceneListItemModel
@end

@interface TalkSegmentListViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<YTTalkSceneListItemModel *> *dataSource;
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
    [self yt_fetchSceneCardsWithType:self.type completion:^(NSArray<YTTalkSceneListItemModel *> *models) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (models) {
            self.dataSource = [models mutableCopy] ?: [NSMutableArray array];
            [self.tableView reloadData];
        }
        [self.tableView.mj_header endRefreshing];
    }];
}

#pragma mark - 数据获取（模拟接口）

- (void)yt_fetchSceneCardsWithType:(NSString *)type completion:(void (^)(NSArray<YTTalkSceneListItemModel *> *models))completion {
    if (self.isRequesting) {
        if (completion) completion(nil);
        return;
    }
    self.isRequesting = YES;

    // TODO: 对接真实接口时：把本地 yt_localModelsForType 替换为网络请求回调即可
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        NSArray<YTTalkSceneListItemModel *> *models = @[];
        if (self) {
            models = [self yt_localModelsForType:type] ?: @[];
            self.isRequesting = NO;
        }
        if (completion) completion(models);
    });
}

- (NSArray<YTTalkSceneListItemModel *> *)yt_localModelsForType:(NSString *)type {
    // 本地数据源：用于接口对接前的 UI 验证
    // NOTE: imageUrl 使用网络占位地址（实际接入时替换为后端下发）
    NSMutableArray<YTTalkSceneListItemModel *> *arr = [NSMutableArray array];

    NSArray<NSDictionary *> *items = nil;
    if ([type isEqualToString:@"hot"]) {
        items = @[
            @{@"title":@"At School", @"subtitle":@"Mastering School\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_hot_0/300/200", @"progressPercent":@(0)},
            @{@"title":@"At Home", @"subtitle":@"Mastering Home\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_hot_1/300/200", @"progressPercent":@(60)},
            @{@"title":@"At Restaurant", @"subtitle":@"Mastering Dining\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_hot_2/300/200", @"progressPercent":@(100)},
            @{@"title":@"At School", @"subtitle":@"Mastering School\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_hot_3/300/200", @"progressPercent":@(60)},
            @{@"title":@"At Home", @"subtitle":@"Mastering Home\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_hot_4/300/200", @"progressPercent":@(0)}
        ];
    } else if ([type isEqualToString:@"new"]) {
        items = @[
            @{@"title":@"At School", @"subtitle":@"Mastering School\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_new_0/300/200", @"progressPercent":@(60)},
            @{@"title":@"At Library", @"subtitle":@"Mastering Library\nStudy & Talk", @"imageUrl":@"https://picsum.photos/seed/talk_list_new_1/300/200", @"progressPercent":@(0)},
            @{@"title":@"At Restaurant", @"subtitle":@"Mastering Dining\nReal-life Dialogue", @"imageUrl":@"https://picsum.photos/seed/talk_list_new_2/300/200", @"progressPercent":@(100)},
            @{@"title":@"At Library", @"subtitle":@"Mastering Library\nStudy & Talk", @"imageUrl":@"https://picsum.photos/seed/talk_list_new_3/300/200", @"progressPercent":@(60)}
        ];
    } else if ([type isEqualToString:@"nearby"]) {
        items = @[
            @{@"title":@"At Park", @"subtitle":@"Talking nearby with confidence", @"imageUrl":@"https://picsum.photos/seed/talk_list_nearby_0/300/200", @"progressPercent":@(0)},
            @{@"title":@"At Cafe", @"subtitle":@"Small talk in everyday life", @"imageUrl":@"https://picsum.photos/seed/talk_list_nearby_1/300/200", @"progressPercent":@(60)},
            @{@"title":@"At Bookstore", @"subtitle":@"Ask about books & suggestions", @"imageUrl":@"https://picsum.photos/seed/talk_list_nearby_2/300/200", @"progressPercent":@(100)},
            @{@"title":@"At Park", @"subtitle":@"Practice common phrases", @"imageUrl":@"https://picsum.photos/seed/talk_list_nearby_3/300/200", @"progressPercent":@(60)}
        ];
    } else if ([type isEqualToString:@"recommended"]) {
        items = @[
            @{@"title":@"Recommended", @"subtitle":@"Start with what fits you best", @"imageUrl":@"https://picsum.photos/seed/talk_list_rec_0/300/200", @"progressPercent":@(60)},
            @{@"title":@"Quick Win", @"subtitle":@"Short lessons, fast improvement", @"imageUrl":@"https://picsum.photos/seed/talk_list_rec_1/300/200", @"progressPercent":@(0)},
            @{@"title":@"Keep Growing", @"subtitle":@"Next steps for better fluency", @"imageUrl":@"https://picsum.photos/seed/talk_list_rec_2/300/200", @"progressPercent":@(100)},
            @{@"title":@"Recommended", @"subtitle":@"More scenes, more practice", @"imageUrl":@"https://picsum.photos/seed/talk_list_rec_3/300/200", @"progressPercent":@(60)}
        ];
    } else {
        items = @[
            @{@"title":@"At School", @"subtitle":@"Mastering School\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_all_0/300/200", @"progressPercent":@(0)},
            @{@"title":@"At Home", @"subtitle":@"Mastering Home\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_all_1/300/200", @"progressPercent":@(60)},
            @{@"title":@"At Restaurant", @"subtitle":@"Mastering Dining\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_all_2/300/200", @"progressPercent":@(100)},
            @{@"title":@"At School", @"subtitle":@"Mastering School\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_all_3/300/200", @"progressPercent":@(0)},
            @{@"title":@"At Home", @"subtitle":@"Mastering Home\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_all_4/300/200", @"progressPercent":@(60)},
            @{@"title":@"At Restaurant", @"subtitle":@"Mastering Dining\nCommunication Skills", @"imageUrl":@"https://picsum.photos/seed/talk_list_all_5/300/200", @"progressPercent":@(100)}
        ];
    }

    for (NSDictionary *dic in items) {
        YTTalkSceneListItemModel *m = [[YTTalkSceneListItemModel alloc] init];
        m.title = dic[@"title"] ?: @"";
        m.subtitle = dic[@"subtitle"] ?: @"";
        m.imageUrl = dic[@"imageUrl"] ?: @"";
        m.progressPercent = [dic[@"progressPercent"] integerValue];
        [arr addObject:m];
    }

    return arr;
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

    YTTalkSceneListItemModel *m = self.dataSource[indexPath.row];
    [cell configureWithTitle:m.title subtitle:m.subtitle imageUrl:m.imageUrl progressPercent:m.progressPercent];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row < 0 || indexPath.row >= self.dataSource.count) return;
    
    TalkTopicHomeViewController *vc = [[TalkTopicHomeViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
