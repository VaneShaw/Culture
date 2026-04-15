//
//  PaymentViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/11/25.
//

#import "PaymentViewController.h"
#import "PaymentTableViewCell.h"
//#import "PaymentModel.h"
#import "HelpRulesViewController.h"

#import "PaymentFooterView.h"
#import "SupportViewController.h"
#import "SubscriptionSetViewController.h"
#import "YTIAPService.h"
#import "ReceiptSyncManager.h"
@interface PaymentViewController ()<UITableViewDataSource,UITableViewDelegate,UINavigationControllerDelegate,UIGestureRecognizerDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) PaymentFooterView *footerView;

@property (nonatomic, strong) NSArray *dataArray; // 存放字典   /模型转字典
@property (nonatomic, strong) UILabel *lblFree;
@property (nonatomic, strong) NSString *vip_status;  //状态
@property (nonatomic, strong) NSString *vip_price; //价格
@property (nonatomic, strong) NSString *service_support;
@property (nonatomic, strong) NSString *trial_time;
@end

@implementation PaymentViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    [self loadCheckVip];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    //iap313   [[YTIAPService shared] finishUnprocessedTransactionsSafely];
}

- (void)loadCheckVip {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"app_region"] = @[@"domestic",@"overseas"][IS_OVERSEAS_VERSION];
    params = [LanguageHelper currentLanguageParams:params];
    __weak typeof(self) weakSelf = self;
    [HttpTools postRequest:@"/vip/index" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (success) {
            NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
            self.service_support = [NSString stringWithFormat:@"%@",dic[@"service_support"]];
            self.trial_time = [NSString stringWithFormat:@"%@",dic[@"trial_time"]];
       
            //NSString *trial_vip = [NSString stringWithFormat:@"%@",dic[@"trial_vip"]];//0未试用1已试用
            //NSString *expired_at = [NSString stringWithFormat:@"%@",dic[@"expired_at"]];//到期时间
            //vip 状态 1=非会员，未试用，2=非会员，已过期，3=已订阅（含免费试用），4=已订阅（但取消）
            NSDictionary *dicProduct = [NSDictionary dictionaryWithDictionary:dic[@"product"]];
            //NSString *currency_cn = [NSString stringWithFormat:@"%@",dic[@"currency_cn"]];
            //NSString *currency_overseas = [NSString stringWithFormat:@"%@",dic[@"currency_overseas"]];
            //NSString *price_cn = [NSString stringWithFormat:@"%@",dicProduct[@"price_cn"]];
            //NSString *price_overseas = [NSString stringWithFormat:@"%@",dicProduct[@"price_overseas"]];
            self.vip_status = [NSString stringWithFormat:@"%@",dic[@"vip_status"]];
            if([KUSER_DEFAULT objectForKey:IAP_Price_key]){
                self.vip_price = [KUSER_DEFAULT objectForKey:IAP_Price_key];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self reloadNewData];
            });
//-----------------------------------------------------------------------------
            if([KUSER_DEFAULT objectForKey:IAP_Price_key]){
                //self.vip_price = [KUSER_DEFAULT objectForKey:IAP_Price_key];
            } //else {
                
                //iap313
                /*NSString *apple_en_product_id = [NSString stringWithFormat:@"%@",dicProduct[@"apple_en_product_id"]];
                NSString *apple_product_id = [NSString stringWithFormat:@"%@",dicProduct[@"apple_product_id"]];
              
                [[YTIAPService shared] requestPriceForProduct:@[apple_product_id,apple_en_product_id][IS_OVERSEAS_VERSION]
                                                   completion:^(NSString *price) {
                    if (price) {
                        [KUSER_DEFAULT setObject:price forKey:IAP_Price_key];
                        self.vip_price = price;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self reloadNewData];
                        });
                    }
                }];*/
                
            //}
//-----------------------------------------------------------------------------
        }
    }
     failure:^(NSError * _Nonnull error) {
    }];
}

//状态管理
- (void)reloadNewData {

    [self.paymentView setVipStatus:self.vip_status vipPrice:self.vip_price trial_time:self.trial_time];
    if(self.vip_status.intValue == 1){
        self.lblFree.text = NSLocalizedString(@"Free Trial",@"");//未试用
    } else {
        self.lblFree.text = NSLocalizedString(@"Full Access",@"");//已试用
    }

    //多种状态类型 //非会员未试用 self.vip_status = 1
    
   
     if(self.vip_status.intValue == 1){ // 第二行
         //NSString *str0 = NSLocalizedString(@"7-day free trial → Auto-renew after trial",@"");
         //NSString *str2 = NSLocalizedString(@"Cancel anytime during the trial.",@"");
      
         NSString *type = self.trial_time;
         NSString *str0 = [NSString stringWithFormat:@"%@免费试用，试用结束后自动续费",type];
         NSString *str1 = NSLocalizedString(@"Cancel anytime during the trial.",@"");
    
         NSString *str2 = [NSString stringWithFormat:@"会员最低仅 %@/月",self.vip_price];
         NSString *str22 = @"会员最低仅 ";
         //元/月
         if(IS_OVERSEAS_VERSION){
             str0 = [NSString stringWithFormat:@"%@ free trial . Cancel anytime",type.lowercaseString];//xx月份改小写
             str2 = [NSString stringWithFormat:@"Plans from %@/month",self.vip_price];
             str22 = @"Plans from ";
         }
         //self.dataArray = @[@{@"title":@[str0,@""]},@{@"title":@[str1,str11]},@{@"title":@[str2,str2]}];
         self.dataArray = @[@{@"title":@[str0,@""]},@{@"title":@[str1,str1]},@{@"title":@[str2,str22]}];
     } else {
         
         //第一行
         //会员已试用
         NSString *str0 = [NSString stringWithFormat:@"限时 %@ /月，解锁完整学习路径与全部资源",self.vip_price];
         if(IS_OVERSEAS_VERSION){//元/月
             str0 = [NSString stringWithFormat:@"%@/month · Unlock Full Access",self.vip_price];
         }
         NSString *str1 = NSLocalizedString(@"Auto-renew every billing period",@"");
         NSString *str2 = NSLocalizedString(@"Cancel anytime",@"");
         self.dataArray = @[@{@"title":@[str0,@""]},@{@"title":@[str1,str1]},@{@"title":@[str2,str2]}];
     }
     [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.vip_status = @"";
    self.vip_price = @"";
    //self.pageId = @"play";
    //CGFloat statusBarH = [PublicTool getStatusBarHeight];
    //CGRect rectNav = self.navigationController.navigationBar.frame;
    //UIView *navView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, statusBarH + rectNav.size.height - 0)];
    //navView.backgroundColor = VIP_COLOR;
 
    [self.view addSubview:self.tableView];
    //[self.view addSubview:navView];
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = self.footerView;
    [self.view addSubview:self.paymentView];
    [self setupMJRefresh];
    
    [self addGlobalBackButtonColor:[self.view colorWithHexString:@"#FFFFFF" alpha:0.2] headerTitleDic:@{@"title":@"Membership",@"color":@"#FFFFFF"}];
    
    self.view.backgroundColor = VIP_COLOR;
    self.tableView.backgroundColor = VIP_COLOR;
    self.headerView.backgroundColor = VIP_COLOR;
    self.footerView.backgroundColor = VIP_COLOR;
    self.paymentView.backgroundColor = DarkBlue_COLOR;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onMembershipUpdated)
                                                 name:IAP_Membership_Notification
                                               object:nil];
    
    if (@available(iOS 13.0, *)) {
        SKStorefront *storefront = SKPaymentQueue.defaultQueue.storefront;
        NSLog(@"Storefront: %@】------------------------xxx---", storefront.countryCode);
    }
}
- (void)onMembershipUpdated{
    [self loadCheckVip];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] init];
        _headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 160);
        [self setupHeaderSubviews];
    }
    return _headerView;
}
- (void)setupHeaderSubviews {
    UIView *headerView = self.headerView;
    // ------- 大图标 -------
       UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"vip_icon_big"]];
       iconView.translatesAutoresizingMaskIntoConstraints = NO;
       iconView.contentMode = UIViewContentModeScaleAspectFit;
       [headerView addSubview:iconView];

        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"title_icon_blue"]];
        icon.translatesAutoresizingMaskIntoConstraints = NO;
        icon.contentMode = UIViewContentModeScaleAspectFit;
        [headerView addSubview:icon];
    
        UILabel *lblFree = [[UILabel alloc] init];
        lblFree.translatesAutoresizingMaskIntoConstraints = NO;
        self.lblFree = lblFree;

        lblFree.font = [UIFont fontWithName:FONT_NAME_Medium size:13];
        lblFree.textAlignment = NSTextAlignmentCenter;
        lblFree.textColor = [self.view colorWithHexString:@"#1F1F39" alpha:1];
        [icon addSubview:lblFree];
   
       // ------- 标题 -------
        GradientLabel *titleLabel_main = [[GradientLabel alloc] init];
        titleLabel_main.translatesAutoresizingMaskIntoConstraints = NO;
     
       titleLabel_main.textAlignment = NSTextAlignmentCenter;
       titleLabel_main.numberOfLines = 0;
        [headerView addSubview:titleLabel_main];
       [titleLabel_main setGradientColors:@[
            [self.view colorWithHexString:@"#4DECFF" alpha:1], //
            [self.view colorWithHexString:@"#CDF5FF" alpha:1], // CDF5FF
            [self.view colorWithHexString:@"#FEC9FF" alpha:1]  // FEC9FF
        ] locations:nil];

        titleLabel_main.text = NSLocalizedString(@"Unlock Premium",@"");
        titleLabel_main.font = [UIFont fontWithName:FONT_NAME_Semibold size:26];
       // ------- 副标题 -------
       UILabel *subtitleLabel = [[UILabel alloc] init];
       subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
       subtitleLabel.text = NSLocalizedString(@"Unlimited access to all learning content",@"");
       subtitleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
       subtitleLabel.textColor = [self.view colorWithHexString:@"#B0B0E0" alpha:1];
       subtitleLabel.numberOfLines = 0;
       subtitleLabel.textAlignment = NSTextAlignmentCenter;
       [headerView addSubview:subtitleLabel];

       // ------- 布局（AutoLayout） -------
       [NSLayoutConstraint activateConstraints:@[
           // 图标居中
           [iconView.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor],
           [iconView.topAnchor constraintEqualToAnchor:headerView.topAnchor constant:5],
           [iconView.widthAnchor constraintEqualToConstant:260],
           [iconView.heightAnchor constraintEqualToConstant:260],
           
           [icon.widthAnchor constraintEqualToConstant:75],
           [icon.heightAnchor constraintEqualToConstant:26],
           [icon.leadingAnchor constraintEqualToAnchor:iconView.trailingAnchor constant:-75],
           [icon.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:-93],
           
           [lblFree.topAnchor constraintEqualToAnchor:icon.topAnchor],
           [lblFree.bottomAnchor constraintEqualToAnchor:icon.bottomAnchor],
           [lblFree.leadingAnchor constraintEqualToAnchor:icon.leadingAnchor],
           [lblFree.trailingAnchor constraintEqualToAnchor:icon.trailingAnchor],
           
           // 标题居中
           [titleLabel_main.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:-64],
           [titleLabel_main.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor constant:20],
           [titleLabel_main.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor constant:-20],

           // 副标题居中
           [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel_main.bottomAnchor constant:16],
           [subtitleLabel.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor constant:20],
           [subtitleLabel.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor constant:-20],
           
           // ⚡关键：让 headerView 自动撑高
           //[subtitleLabel.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor constant:-20],
       ]];
    
    [headerView layoutIfNeeded];
    CGFloat maxWidth = SCREEN_WIDTH - 20*2; // 左右间距
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);

    // 计算副标题高度
    CGSize subtitleSize = [subtitleLabel sizeThatFits:maxSize];
    CGFloat subtitleHeight = subtitleSize.height;

    // 计算副标题 y 轴
    CGFloat subtitleY = CGRectGetMaxY(titleLabel_main.frame) + 10; // 10 是你设置的间距
    self.headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, subtitleY + subtitleHeight + 20);
}
- (PaymentFooterView *)footerView {
    if (!_footerView) {
        _footerView = [[PaymentFooterView alloc] init];
        [_footerView.btnSubscriptions addTarget:self action:@selector(btnSubscriptionsAction:) forControlEvents:UIControlEventTouchUpInside];
        [_footerView.btnHelp addTarget:self action:@selector(btnHelpAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _footerView;
}
- (void)btnHelpAction:(UIButton *)sender {
    SupportViewController *supportVC = [SupportViewController new];
    supportVC.service_support = self.service_support;
    [self.navigationController pushViewController:supportVC animated:YES];
}
- (void)btnSubscriptionsAction:(UIButton *)sender {
    //NSURL *url = [NSURL URLWithString:@"https://apps.apple.com/account/subscriptions"];
    //[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    
    SubscriptionSetViewController *vc = [SubscriptionSetViewController new];
    vc.vip_status = self.vip_status;
    [self.navigationController pushViewController:vc animated:YES];
}
- (PaymentView *)paymentView {
    if (!_paymentView) {
        int payHeight = 146;
        _paymentView = [[PaymentView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - payHeight, SCREEN_WIDTH, payHeight)];
        _paymentView.uvc = self;
    }
    return _paymentView;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
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
    //[self getPracticeZone];
    [self loadCheckVip];
    [self.tableView.mj_header endRefreshing];
}

- (UITableView *)tableView {
    if (!_tableView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight] + 2;
        CGRect rectNav = self.navigationController.navigationBar.frame;
        int payHeight = 146;
        CGRect frame =  CGRectMake(0, statusBarH + rectNav.size.height, SCREEN_WIDTH, SCREEN_HEIGHT - statusBarH -  payHeight - rectNav.size.height);
        _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.sectionFooterHeight = CGFLOAT_MIN;
        _tableView.sectionHeaderHeight = CGFLOAT_MIN;
        _tableView.userInteractionEnabled = YES;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        // 2. 禁用自动调整 contentInset（iOS 11+）
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _tableView;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PaymentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil){
        cell = [[PaymentTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    cell.backgroundColor = VIP_COLOR;
    [cell setCell:self.dataArray[indexPath.row]];
    return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}
// 设置段间距
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

//- (void)getPracticeZone {
//    
//    NSMutableDictionary *params = [NSMutableDictionary dictionary];
//    params = [LanguageHelper currentLanguageParams:params];
//    [HttpTools postRequest:@"/home/getPracticeZone" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
//    
//        if (success) {
//            NSArray *newArray = [NSArray arrayWithArray:response.data];
//        } else {
//            [MBProgressHUD showLabel:response.msg];
//        }
//    } failure:^(NSError * _Nonnull error) {
//    }];
//}


@end
