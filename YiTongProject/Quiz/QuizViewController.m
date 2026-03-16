//
//  QuizViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/30.
//

#import "QuizViewController.h"
#import "QuizTableViewCell.h"
#import "QuizPinyinViewController.h"
#import "QuizToneViewController.h"
@interface QuizViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (nonatomic, strong) NSMutableArray *dataArrays; // 存放字典   /模型转字典
@property (nonatomic, copy) NSString *localJSONString;   // 用于缓存对比
@property (strong, nonatomic) NoNetworkView *noNetView;

@end
@implementation QuizViewController

- (void)viewDidAppear:(BOOL)animated {//视图---出现
    [super viewDidAppear:animated];
  
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[[UMAnalyticsManager sharedManager] trackPageBegin:NSStringFromClass([self class])];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    //if([PublicTool hasTriggered]){
    if([KUSER_DEFAULT boolForKey:@"Quiz_key_1"]){
        [self getPracticeZone];
        [self monitoringNetwork];
    } else {
        [KUSER_DEFAULT setBool:YES forKey:@"Quiz_key_1"];
    }
    


}
- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    //[[UMAnalyticsManager sharedManager] trackPageEnd:NSStringFromClass([self class])];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"quiz";
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.dataArrays = [NSMutableArray new];
    [self.view addSubview:self.tableView];
    self.tableView.tableHeaderView = self.headerView;
    [self setupMJRefresh];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadNessageTexts) name:LanguageDidChangeNotification object:nil];
    [self loadNessageTexts];

    NoNetworkView *noNetView = [[NoNetworkView alloc] initWithFrame:self.view.bounds];
    self.noNetView = noNetView;
    noNetView.refreshHandler = ^{
        // 刷新逻辑，比如重新发起网络请求
        [self getPracticeZone];
    };
    [self.view addSubview:self.noNetView];
    self.noNetView.hidden = YES;
    // 1. 加载本地缓存
    self.dataArrays = [[DataCacheManager loadDataForClass:[self class]] mutableCopy];
    if (self.dataArrays.count > 0) {
        [self.tableView reloadData];
    } else {
        self.noNetView.alpha = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.noNetView.alpha = 1;
            });
        self.noNetView.hidden = [KUSER_DEFAULT boolForKey:@"notwork_key"];
    }
    [self monitoringNetwork];
    
}
- (void)monitoringNetwork {
    [[NetworkMonitor sharedMonitor] startMonitoring];
    [NetworkMonitor sharedMonitor].statusChangeHandler = ^(NetworkStatusType status) {
      
        switch (status) {
            case NetworkStatusTypeNotReachable:
                self.noNetView.hidden = NO;
                self.noNetView.settingsBtn.hidden = [KUSER_DEFAULT boolForKey:@"notwork_key"];
                NSLog(@"❌ 无网络。❌");
                break;
            case NetworkStatusTypeWiFi:
                NSLog(@"✅ Wi-Fi 网络 v");
                self.noNetView.hidden = YES;
                break;
            case NetworkStatusTypeCellular:
                NSLog(@"📶 蜂窝数据 v");
                self.noNetView.hidden = YES;
                break;
        }
    };
}
- (void)loadNessageTexts {
    //self.lblTitle.text = @"Pick a Topic to Practice";
    
    self.lblTitle.text = NSLocalizedString(@"Pick a Topic to Practice", @"");
    CGSize labelSize = [self.lblTitle sizeThatFits:CGSizeMake(SCREEN_WIDTH - 2 * Distance＿M,MAXFLOAT)];
    int hight = 12;
    self.lblTitle.frame = CGRectMake(Distance＿M, 15 + hight, SCREEN_WIDTH - 2 * Distance＿M, labelSize.height + hight);
    self.headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 30 + self.lblTitle.frame.size.height + hight);
}
//===========上下拉刷新===============================
- (void)setupMJRefresh {
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewTopics)];
        //允许自动改变透明度
    self.tableView.mj_header.automaticallyChangeAlpha = YES;//header开始刷新
    [self.tableView.mj_header beginRefreshing];
    //设置footer，用户滑到最下边就会自动启用footer刷新，故不用写开始刷新的代码
    //self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreTopics)];
}
   //下拉刷新
- (void)loadNewTopics {
    [self getPracticeZone];
    [self.tableView.mj_header endRefreshing];
}
- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 150 + 12)];
        _headerView.backgroundColor = [UIColor whiteColor];
        [_headerView addSubview:self.lblTitle];
    }
    return _headerView;
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿M, 15 + 12, SCREEN_WIDTH - 2 * Distance＿M, 125)];
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Helvetica size:36];
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Helvetica size:27];
        _lblTitle.numberOfLines = 0;
    }
    return _lblTitle;
}
- (UITableView *)tableView {
    if (!_tableView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;
        CGRect frame =  CGRectMake(0, statusBarH , SCREEN_WIDTH, SCREEN_HEIGHT - statusBarH - tabBarHeight);
        _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.sectionFooterHeight = CGFLOAT_MIN;
        _tableView.sectionHeaderHeight = CGFLOAT_MIN;
        _tableView.userInteractionEnabled = YES;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        // 2. 禁用自动调整 contentInset（iOS 11+）
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _tableView;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    QuizTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil){
        cell = [[QuizTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    [cell setCell:self.dataArrays[indexPath.row] index:(int)indexPath.row];
    return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArrays.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//-IS_OVERSEAS_VERSION * 13
    //return 259 + 16 ;
    return 230 + 30 * IS_OVERSEAS_VERSION + 16 ;//上架必备
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if([[UserModel sharedInstance] isLogin]){//需判断用户登录
        // 创建视图控制器
        switch (indexPath.row) {
            case 0:
            {
                QuizPinyinViewController *vc = [QuizPinyinViewController new];
                vc.hidesBottomBarWhenPushed = YES;
                vc.practice_id = [NSString stringWithFormat:@"%@",self.dataArrays[indexPath.row][@"id"]];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 1:
            {
                QuizToneViewController *vc = [QuizToneViewController new];
                vc.hidesBottomBarWhenPushed = YES;
                vc.practice_id = [NSString stringWithFormat:@"%@",self.dataArrays[indexPath.row][@"id"]];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            default:
                break;
        }
    } else {
        [[LoginManager sharedManager] handleLoginExpiredWithCompletion:^{
            // 登录完成后的逻辑
            NSLog(@"登录完成，回到调用方法");
            [self getPracticeZone];
        }];
    }

    
}
- (void)getPracticeZone{
    //[MBProgressHUD showMessage:@""];
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(Countdown_Seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
           //[MBProgressHUD hideHUD];
    });
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:@"/home/getPracticeZone" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        //[MBProgressHUD hideHUD];
        
        self.noNetView.hidden = YES;
        
        if (success) {
            NSArray *newArray = [NSArray arrayWithArray:response.data];
            //self.dataArray = [NSArray arrayWithArray:response.data];
            //[self.tableView checkEmptyWithDataCount:self.dataArray.count];
            //[self.tableView reloadData];
            
            if ([DataCacheManager hasDataChanged:newArray forClass:[self class]]) {
                self.dataArrays = [newArray mutableCopy];
                [self.tableView reloadData];
            }
            
        } else {
            
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
#pragma mark - 加载本地缓存

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


@end
