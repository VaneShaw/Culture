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

@interface TalkSegmentListViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) void (^scrollCallback)(UIScrollView *scrollView);

@end

@implementation TalkSegmentListViewController

- (instancetype)initWithType:(NSString *)type {
    self = [super init];
    if (self) {
        _type = [type copy];
        _dataSource = [NSMutableArray array];
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
    // TODO: 根据 self.type 请求不同分类的数据
    // 这里先简单模拟数据
    [self.dataSource removeAllObjects];
    for (NSInteger i = 0; i < 10; i++) {
        [self.dataSource addObject:[NSString stringWithFormat:@"%@_row_%ld", self.type, (long)i]];
    }
    [self.tableView reloadData];
    [self.tableView.mj_header endRefreshing];
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
    
    NSInteger row = indexPath.row;
    YTTalkSceneCellStatus status = (YTTalkSceneCellStatus)(row % 3);
    
    // MVP：先用静态文案+两张占位图做 UI 验证，后续再接真实数据模型
    NSString *title = @"At School";
    NSString *subtitle = @"Mastering School\nCommunication Skills";
    NSString *imageName = @"take_img0";
    
    if ([self.type isEqualToString:@"hot"]) {
        title = @"At Home";
        subtitle = @"Mastering Home\nCommunication Skills";
        imageName = @"take_img1";
    } else if ([self.type isEqualToString:@"new"]) {
        title = @"At Restaurant";
        subtitle = @"Mastering Dining\nCommunication Skills";
        imageName = @"take_img1";
    }
    
    [cell configureWithTitle:title subtitle:subtitle imageName:imageName status:status];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TalkTopicHomeViewController *vc = [[TalkTopicHomeViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end

