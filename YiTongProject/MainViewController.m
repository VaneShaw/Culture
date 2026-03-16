//
//  MainViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//
#import <Network/Network.h>  // 一定要加在最上面
#import "MainViewController.h"
#import "GradientProgressView.h"
#import "HomeTableViewCell.h"
#import "StartPinyinViewController.h"

#import "HanziListViewController.h"
#import "ReadStoryViewController.h"

#import "DeviceUUIDManager.h"
#import "PaymentViewController.h"
#import "SubscriptionAlertHelper.h"
#import "MemberRetentionView.h"
#import "RestoreVipView.h"
#import "ReceiptSyncManager.h"
#import "StoryGodsViewController.h"
#import "AnalyticsContext.h"
@interface MainViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *dataArrays;
@property (nonatomic, copy) NSString *localJSONString;   // 用于缓存对比
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UILabel *lblStartsNow;
@property (strong, nonatomic) UILabel *lblName;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) UIView *navigationView;
@property (strong, nonatomic) UIImageView *imgAvatar;
@property (strong, nonatomic) GradientProgressView *progressView;
@property (assign, nonatomic) int page;//当前页面
@property (assign, nonatomic) int pageCount;//总页面
@property (nonatomic, assign) BOOL isMethodRunning;
@property (strong, nonatomic) NoNetworkView *noNetView;
@end
@implementation MainViewController
- (void)viewWillAppear:(BOOL)animated {//视图即将出现
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    
    if([PublicTool hasTriggered]){
        [self loadNewMessage];
        [self monitoringNetwork];
    } else {
        if([KUSER_DEFAULT boolForKey:@"DataChanged_KEY"]){
            [self loadNewMessage];
        }
    }
}
- (void)viewDidAppear:(BOOL)animated {//视图---出现
    [super viewDidAppear:animated];
    //AnalyticsContext *ctx = [AnalyticsContext shared];
    //ctx.currentPage = self.pageId;   // ⭐ 关键
}
- (void)viewWillDisappear:(BOOL)animated {//视图即将消失
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}
- (void)viewDidDisappear:(BOOL)animated{  //视图--消失
    [super viewWillDisappear:animated];
}
/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UMAnalyticsManager sharedManager] trackPageBegin:NSStringFromClass([self class])];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UMAnalyticsManager sharedManager] trackPageEnd:NSStringFromClass([self class])];
}
*/
- (void)viewDidLoad {
    [super viewDidLoad];
    self.username = @"";
    self.pageId = @"home";
    [KUSER_DEFAULT setObject:self.pageId forKey:@"analytics_last_page"];
    // Do any additional setup after loading the view.

    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.dataArrays = [NSMutableArray new];
    self.isMethodRunning = NO;
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.navigationView];
    [KUSER_DEFAULT setBool:NO forKey:@"Quiz_key_1"];
    
    UIView *footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, CGFLOAT_MIN)];
    self.tableView.tableFooterView = footerView;
    self.dataArrays = [NSMutableArray new];
    self.page = 1;
    self.pageCount = PAGE_COUNT;
    [self setupMJRefresh];
    
    if(![PublicTool triggerStatus]){
        [self startNetworkMonitor];
    } else{
        if([[UserModel sharedInstance] isLogin]){
            self.username = [[UserModel sharedInstance] username];
        } else {
            self.username = @[@"欢迎来到易通",@"Welcome to YTong"][IS_OVERSEAS_VERSION];
            self.imgAvatar.image = [UIImage imageNamed:@"default_avatar"];
        }
        self.tableView.tableHeaderView = self.headerView;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadNessageTexts) name:LanguageDidChangeNotification object:nil];
    [self loadNessageTexts];
    
    NoNetworkView *noNetView = [[NoNetworkView alloc] initWithFrame:self.view.bounds];
    self.noNetView = noNetView;
    noNetView.refreshHandler = ^{       // 刷新逻辑，比如重新发起网络请求
        [self loadNewMessage];
    };
    [self.view addSubview:self.noNetView];
    self.noNetView.hidden = YES;
    
    self.dataArrays = [[DataCacheManager loadDataForClass:[self class]] mutableCopy];
    if (self.dataArrays.count > 0) {
        [self.tableView reloadData];
    }  else {
        self.noNetView.alpha = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.noNetView.alpha = 1;
        });
        self.noNetView.hidden = [KUSER_DEFAULT boolForKey:@"notwork_key"];
    }
    [self monitoringNetwork];
    if (IS_UM_SDK) {//埋点
        //NSLog(@"----you me----------");
    } else {
        //NSLog(@"fei-------------");
    }
    
    //NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    //NSString *uuid = [KeychainUUID getUUID];
    //NSLog(@"fei-------------uuid=[%@]-------",uuid);
 
    NSString *guest_uuid = [KUSER_DEFAULT objectForKey:Guest_Uuid_Key];
    if([KeychainUUID isEmptyString:guest_uuid]){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self createGuest];
        });
    }
}
- (void)createGuest {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"device_id"] = [KeychainUUID getUUID];
    NSString *url = @[@"/authCn/createGuest",@"/auth/createGuest"][IS_OVERSEAS_VERSION];
    [HttpTools postRequestUsers:url parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        if (success) {
            NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
            NSString *guest_uuid = [NSString stringWithFormat:@"%@",dic[Guest_Uuid_Key]];
            [KUSER_DEFAULT setObject:guest_uuid forKey:Guest_Uuid_Key];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (long long)currentTimeMillis {
    return (long long)([[NSDate date] timeIntervalSince1970] * 1000);
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
- (void)startNetworkMonitor {
    if (@available(iOS 12.0, *)) {
        nw_path_monitor_t monitor = nw_path_monitor_create();
        nw_path_monitor_set_queue(monitor, dispatch_get_main_queue());
        nw_path_monitor_set_update_handler(monitor, ^(nw_path_t path) {
            if (nw_path_get_status(path) == nw_path_status_satisfied) {
                NSLog(@"网络可用 ✅");
                [self loadNewMessage];// 用户允许后再触发请求
                [KUSER_DEFAULT setBool:YES forKey:@"notwork_key"];
            } else {
                self.noNetView.hidden = NO;
                NSLog(@" ❌网络不可用 ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌ ❌");
                //[self addAlertView];
                //[MBProgressHUD showLabel:NSLocalizedString(@"Network is unavailable. Please check your Wi-Fi or cellular data settings.", @"")];
            }
        });
        nw_path_monitor_start(monitor);
    }
}
- (UIView *)navigationView {
    if (!_navigationView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        _navigationView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, statusBarH)];
        _navigationView.backgroundColor = [UIColor whiteColor];
    }
    return _navigationView;
}
- (UITableView *)tableView {
    if (!_tableView) {
        //CGRect rectNav = self.navigationController.navigationBar.frame;
        //int y = rectNav.size.height + ;
        CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGRect frame =  CGRectMake(0, statusBarH, SCREEN_WIDTH, SCREEN_HEIGHT - statusBarH - tabBarHeight);
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
- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 150)];
        for (int i = 0; i < 2; i ++) {
            UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿M, 22 + 80 * i, 300, 80 - i * 60)];
            lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
            lblTitle.textColor = BLACK_COLOR_1F;
            lblTitle.text = @[@"",@""][i];
            [_headerView addSubview:lblTitle];
            if(i==0){
                lblTitle.numberOfLines = 2;
                lblTitle.font = [UIFont fontWithName:FONT_NAME_Helvetica size:27];
                self.lblName = lblTitle;
            } else {
                self.lblStartsNow = lblTitle;
            }
        }
        [_headerView addSubview:self.imgAvatar];
    }
    return _headerView;
}
- (UIImageView *)imgAvatar {
    if(!_imgAvatar){
        int width = 60;
        _imgAvatar = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - Distance＿M - width, 34, width, width)];
        _imgAvatar.layer.cornerRadius = width/2;//圆角
        _imgAvatar.layer.masksToBounds = YES;
        _imgAvatar.layer.borderColor = [self.view colorWithHexString:@"#F1F9FF" alpha:1].CGColor;
        _imgAvatar.layer.borderWidth = 2;  //边框
    }
    return _imgAvatar;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HomeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil){
        cell = [[HomeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    if (indexPath.row < 0 || indexPath.row >= self.dataArrays.count) {
        return cell;
    }
    [cell setCell:self.dataArrays[indexPath.row]];
    __weak typeof(cell) weakCell = cell;
    __weak typeof(self) weakSelf = self;
    NSString *type = [NSString stringWithFormat:@"%@",self.dataArrays[indexPath.row][@"type"]];
    switch (type.intValue) {
        case 1:
        {
        }
            break;
        case 2:
        {
            [cell setSelectedTypeIndex:^(NSInteger index) {
                if (!weakCell || !weakCell.imagesArray || index < 0 || index >= weakCell.imagesArray.count) return;
                NSDictionary *imageDict = weakCell.imagesArray[index];
                if (![imageDict isKindOfClass:[NSDictionary class]]) return;
                NSString *strid = [NSString stringWithFormat:@"%@",imageDict[@"id"]];
                [weakSelf getMythStoryDetail:strid];
            }];
        }
            break;
        case 4:
        {
            [cell setSelectedTypeIndex:^(NSInteger index) {
                if (!weakCell || !weakCell.imagesArray || index < 0 || index >= weakCell.imagesArray.count) return;
                NSDictionary *imageDict = weakCell.imagesArray[index];
                if (![imageDict isKindOfClass:[NSDictionary class]]) return;
                NSString *story_id = [NSString stringWithFormat:@"%@",imageDict[@"id"]];
                if(story_id.intValue > 0){
                    ReadStoryViewController *vc = [ReadStoryViewController new];
                    vc.hidesBottomBarWhenPushed = YES;
                    vc.storyId = story_id;
                    [self.navigationController pushViewController:vc animated:YES];
                }
            }];
        }
            break;
        case 5:{
            [cell setSelectedTypeIndex:^(NSInteger index) {
                NSString *story_id = [KUSER_DEFAULT objectForKey:Story_Scroll_Index];
                if(story_id.intValue < 1){
                    if (weakCell && weakCell.imagesArray && index >= 0 && index < weakCell.imagesArray.count) {
                        NSDictionary *imageDict = weakCell.imagesArray[index];
                        if ([imageDict isKindOfClass:[NSDictionary class]]) {
                            story_id = [NSString stringWithFormat:@"%@",imageDict[@"id"]];
                        }
                    }
                }
                [self pushStoryGodsViewStoryId:story_id];
            }];
        }
            break;
        default:
            break;
    }
    return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArrays.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < 0 || indexPath.row >= self.dataArrays.count) {
        return 220 + 18;
    }
    NSDictionary *dic = [NSDictionary dictionaryWithDictionary:self.dataArrays[indexPath.row]];
    NSArray *imagesArray;
    if ([dic[@"images"] isKindOfClass:[NSArray class]]) {
        imagesArray = [NSArray arrayWithArray:dic[@"images"]];
    }
    BOOL isBanner = imagesArray.count > 0 ? YES:NO;
    float height1 = (SCREEN_WIDTH-60) * (282.0/630.0);
    return  (79 + height1 - 220) * isBanner + 220 + 18;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN; // 比 0.1 更小的值
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row < 0 || indexPath.row >= self.dataArrays.count) return;
    NSString *type = [NSString stringWithFormat:@"%@",self.dataArrays[indexPath.row][@"type"]];
    switch (type.intValue) {//1:拼音,2:神话故事,3:汉字,4:成语故事
        case 1:{
            [KUSER_DEFAULT setBool:NO forKey:@"IS_Formal_Hanzi"];
            StartPinyinViewController *startPinyinVC = [StartPinyinViewController new];
            startPinyinVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:startPinyinVC animated:YES];
        }
            break;
        case 2:{
            HomeTableViewCell *cell = (HomeTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            if (cell && cell.imagesArray && cell.bannerScrollView.currentIndex >= 0 && cell.bannerScrollView.currentIndex < cell.imagesArray.count) {
                NSDictionary *imageDict = cell.imagesArray[cell.bannerScrollView.currentIndex];
                if ([imageDict isKindOfClass:[NSDictionary class]]) {
                    NSString *strid = [NSString stringWithFormat:@"%@",imageDict[@"id"]];
                    [self getMythStoryDetail:strid];
                }
            }
        }
            break;
        case 3:{
                [ColorManager saveColorKeyForRow:0];
                [KUSER_DEFAULT setBool:YES forKey:@"IS_Formal_Hanzi"];
                HanziListViewController *hanziVC = [HanziListViewController new];
                hanziVC.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:hanziVC animated:YES];
        }
            break;
        case 4:{
            HomeTableViewCell *cell = (HomeTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            if (cell && cell.imagesArray && cell.bannerScrollView.currentIndex >= 0 && cell.bannerScrollView.currentIndex < cell.imagesArray.count) {
                NSDictionary *imageDict = cell.imagesArray[cell.bannerScrollView.currentIndex];
                if ([imageDict isKindOfClass:[NSDictionary class]]) {
                    NSString *story_id = [NSString stringWithFormat:@"%@",imageDict[@"id"]];
                    if(story_id.intValue > 0){
                        ReadStoryViewController *vc = [ReadStoryViewController new];
                        vc.hidesBottomBarWhenPushed = YES;
                        vc.storyId = story_id;
                        [self.navigationController pushViewController:vc animated:YES];
                    }
                }
            }
        }
            break;
        case 5:{
            HomeTableViewCell *cell = (HomeTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            NSString *story_id = [KUSER_DEFAULT objectForKey:Story_Scroll_Index];
            if(story_id.intValue < 1){
                if (cell && cell.imagesArray && cell.bannerScrollView.currentIndex >= 0 && cell.bannerScrollView.currentIndex < cell.imagesArray.count) {
                    NSDictionary *imageDict = cell.imagesArray[cell.bannerScrollView.currentIndex];
                    if ([imageDict isKindOfClass:[NSDictionary class]]) {
                        story_id = [NSString stringWithFormat:@"%@",imageDict[@"id"]];
                    }
                }
            }
            [self pushStoryGodsViewStoryId:story_id];
           
        }
            break;
        default:
            break;
    }
}

/*
#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
//===========上下拉刷新===============================
- (void)setupMJRefresh {
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewTopics)];
        //允许自动改变透明度
    self.tableView.mj_header.automaticallyChangeAlpha = YES;//header开始刷新
    [self.tableView.mj_header beginRefreshing];
    //设置footer，用户滑到最下边就会自动启用footer刷新，故不用写开始刷新的代码
    //self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreTopics)];
    //[MJRefreshConfig defaultConfig].languageCode = @"zh-Hans";
    //[MJRefreshConfig defaultConfig].languageCode = @"ko";
}
   //下拉刷新
- (void)loadNewTopics {
    self.page = 1;
    //下拉先停止footer刷新
    //NSLog(@"---333---------------logo--");
    if(self.dataArrays.count > 0){
        [KUSER_DEFAULT setBool:YES forKey:@"DataChanged_KEY"];
    }
    [self loadNewMessage];
    [self.tableView.mj_header endRefreshing];
    [self.tableView.mj_footer endRefreshing];
    //NSLog(@"---11-------logo----------");
}
- (void)loadMoreTopics {//上
}
- (void)loadNessageTexts {
    NSString *hi = NSLocalizedString(@"Hi", @"");
    self.lblName.text = [NSString stringWithFormat:@"%@,\n%@",hi,self.username];
    self.lblStartsNow.text = NSLocalizedString(@"Learning starts now", @"");
}
- (void)loadNewMessage {

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"is_user_info"] = @"1";
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:@"/home/getBanner" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        self.tableView.tableHeaderView = self.headerView;
        self.noNetView.hidden = YES;
        [KUSER_DEFAULT setBool:NO forKey:@"DataChanged_KEY"];
    
        if (success) {
            NSDictionary *userInfo = response.data[@"user_info"];
            if (![userInfo isKindOfClass:[NSDictionary class]]) {
                userInfo = @{};
            }
            NSDictionary *dicUser = [NSDictionary dictionaryWithDictionary:userInfo];
            NSString *avatar = [NSString stringWithFormat:@"%@",dicUser[@"avatar"]];
            [self.imgAvatar sd_setImageWithURL:[NSURL URLWithString:avatar]];
            self.username = [NSString stringWithFormat:@"%@",dicUser[@"username"]];
            //======================================
            NSDictionary *dicTemp = [KUSER_DEFAULT objectForKey:@"user_info_key"];
            NSMutableDictionary *mutableDicUser = [dicUser mutableCopy];// 将 dicUser 转换为可变字典，以便修改
            // 检查 dicTemp 中的每个键，如果 dicUser 中没有该键，则从 dicTemp 中复制过来
            [dicTemp enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![mutableDicUser objectForKey:key]) {
                    [mutableDicUser setObject:obj forKey:key];
                }
            }];
            [KUSER_DEFAULT setObject:mutableDicUser forKey:@"user_info_key"];
            //======================================
            [self loadNessageTexts];
            NSArray *listArray = response.data[@"list"];
            if (![listArray isKindOfClass:[NSArray class]]) {
                listArray = @[];
            }
            NSArray *newArray = [NSArray arrayWithArray:listArray];
            
            //NSLog(@"newArray------11----[%@]-----------22---------",newArray[4]);
            if ([DataCacheManager hasDataChanged:newArray forClass:[self class]]) {
                self.dataArrays = [newArray mutableCopy];
                [self.tableView reloadData];
            }
            [self.tableView.mj_header endRefreshing];
            [self.tableView.mj_footer endRefreshing];
    
            //NSLog(@"---------------xc-------[%@]",response.data);
            NSDictionary *userVip = response.data[@"user_vip"];
            if (![userVip isKindOfClass:[NSDictionary class]]) {
                userVip = @{};
            }
            NSDictionary *dicVip = [NSDictionary dictionaryWithDictionary:userVip];
            //NSString *vip_type = [NSString stringWithFormat:@"%@",dicVip[@"vip_type"]];
            //is_vip 0 : 1
            NSString *is_vip = [NSString stringWithFormat:@"%@",dicVip[@"is_vip"]];
            //NSLog(@"-----main---------dicVip------[%@][%@]-----is_vip[%@]",dicVip,dicUser,is_vip);
            //=====================================================================
            if(IS_Member){
                if(!is_vip.boolValue && [UserStateManager shared].needRefreshLoginUI){
                    //用户登录成功-判断迁移
                    if ([[ReceiptSyncManager sharedManager] canSyncReceiptThisMonth]) {
                        [[ReceiptSyncManager sharedManager] syncReceiptIfNeeded];
                    }
                    [UserStateManager shared].needRefreshLoginUI = NO;
                }
                [[SilentReceiptSyncManager sharedManager] startSilentSyncIfLoggedIn:is_vip.boolValue];
            }
            //======================================================================
            //1订阅   2取消订阅
            NSString *can_subscribe = [NSString stringWithFormat:@"%@",dicVip[@"can_subscribe"]];
            NSString *remaining_days = [NSString stringWithFormat:@"%@",dicVip[@"remaining_days"]];
            
//           can_subscribe = @"2";
//           is_vip = @"1";
//           remaining_days = @"7";
            
            if(can_subscribe.intValue == 2 && is_vip.intValue == 1){
                NSString *expired_at = [NSString stringWithFormat:@"%@",dicVip[@"expired_at"]];
                NSInteger daysLeft = [remaining_days integerValue];
                NSTimeInterval expireTimestamp = [expired_at doubleValue];
                
            if ([SubscriptionAlertHelper shouldShowAlertForDaysLeft:daysLeft expireTimestamp:expireTimestamp]) {
                //在首页判断 剩余 1天 or 7天弹窗
                [AccessExpiresView showViewTitle:remaining_days dataArray:@[] callBack:^(NSInteger index) {
                    NSString *urlString = @"itms-apps://apps.apple.com/account/subscriptions";
                    NSURL *url = [NSURL URLWithString:urlString];
                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
                        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                    }
                }];
            }
        }
             
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)pushStoryGodsViewStoryId:(NSString *)story_id {
    if(story_id.intValue > 0){
        [KUSER_DEFAULT setObject:@"0" forKey:Story_Scroll_Index];
        NSInteger row = [KUSER_DEFAULT integerForKey:Story_Scroll_Row];
        if(story_id.intValue > 0 && row != 0){
            [KUSER_DEFAULT setBool:YES forKey:Story_Scroll_IsVC];
        }//有问题111
         StoryGodsViewController *vc = [StoryGodsViewController new];
         vc.hidesBottomBarWhenPushed = YES;
         vc.storyId = story_id;
         vc.isFairy = 2;
         vc.modeType = 2;
         [self.navigationController pushViewController:vc animated:YES];
    }
}
- (void)getMythStoryDetail:(NSString *)story_id{
    if(story_id.intValue > 0){
        ReadStoryViewController *vc = [ReadStoryViewController new];
        vc.hidesBottomBarWhenPushed = YES;
        vc.storyId = story_id;
        vc.isFairy = 1;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end







