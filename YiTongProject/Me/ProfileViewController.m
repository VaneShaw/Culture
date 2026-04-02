//
//  ProfileViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/24.
//

#import "ProfileViewController.h"
#import "YTVFavoritesListViewController.h"
#import "OrdersViewController.h"
#import "ClearCacheViewController.h"
#import "SettingsViewController.h"
#import "DateHelper.h"
#import "UserinfoViewController.h"
@interface ProfileViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *dataArray;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UIView *loginView;
@property (strong, nonatomic) UIView *footerView;
@property (strong, nonatomic) UIImageView *imgAvatar;
@property (strong, nonatomic) UIButton *btnAvatar;
@property (strong, nonatomic) UIImageView *imgVip;
@property (strong, nonatomic) UIImageView *imgView;
@property (strong, nonatomic) UILabel *lblUserName;
@property (strong, nonatomic) UILabel *lblEmail;

@property (strong, nonatomic) NSString *strEmail;
@property (strong, nonatomic) UIButton *btnSettings;
@property (strong, nonatomic) UIButton *btnLogin;
@property (strong, nonatomic) UIButton *viewVip;
@property (strong, nonatomic) UIButton *btnMembership;
@property (strong, nonatomic) GradientLabel *titleLabel;
@property (strong, nonatomic) NSString *vip_status;
//@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) NSString *trial_time;
@property (nonatomic, assign) BOOL isCheckingVip;//判断这个方法是否已触发 不重复

@end
@implementation ProfileViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
 
    if([[UserModel sharedInstance] isLogin]){
        NSDictionary *dicUser = [KUSER_DEFAULT objectForKey:@"user_info_key"];
        NSString *avatar = [NSString stringWithFormat:@"%@",dicUser[@"avatar"]];
        [self.imgAvatar sd_setImageWithURL:[NSURL URLWithString:avatar]];
        self.lblUserName.text = [NSString stringWithFormat:@"%@",dicUser[@"username"]];
        self.strEmail = @[[[UserModel sharedInstance] mobile],[[UserModel sharedInstance] email]][IS_OVERSEAS_VERSION];
        self.lblEmail.text = [self maskEmail:self.strEmail];
        self.loginView.hidden = YES;
        self.btnSettings.hidden = NO;
        
        [self loadCheckVip];
    } else {
        self.loginView.hidden = NO;
        self.btnSettings.hidden = YES;
    }
}
- (void)viewDidAppear:(BOOL)animated {//视图---出现
    [super viewDidAppear:animated];
    if([[UserModel sharedInstance] isLogin]){
        self.btnSettings.hidden = NO;
    } else {
        self.btnSettings.hidden = YES;
    }
}

- (void)settingsSDKAppEvents {
}
- (void)btnAvatarAction:(UIButton *)sender {
    UserinfoViewController *vc = [UserinfoViewController new];
    vc.hidesBottomBarWhenPushed = YES;
    [vc setSelectedUserNickname:^(NSString * _Nonnull nickname) {
        
    }];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //[self settingsSDKAppEvents];
    self.pageId = @"profile";
    self.view.backgroundColor = [self.view colorWithHexString:@"#F5F9FF" alpha:1];

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.loginView];
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = self.footerView;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadNessageTexts) name:LanguageDidChangeNotification object:nil];
    [self loadNessageTexts];
    [self setupMJRefresh];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(onMembershipUpdated)
                                                   name:IAP_Membership_Notification
                                                 object:nil];
}
//===========上下拉刷新===============================
- (void)setupMJRefresh {
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewTopics)];
        //允许自动改变透明度
    self.tableView.mj_header.automaticallyChangeAlpha = YES;//header开始刷新
    [self.tableView.mj_header beginRefreshing];
    //设置footer，用户滑到最下边就会自动启用footer刷新，故不用写开始刷新的代码
}
   //下拉刷新
- (void)loadNewTopics {
    if([[UserModel sharedInstance] isLogin]){
        [self loadCheckVip];
    }
    [self.tableView.mj_header endRefreshing];

}
- (void)onMembershipUpdated{
    [self loadCheckVip];
}
- (UIView *)loginView {
    if(!_loginView){
        _loginView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _loginView.backgroundColor = [UIColor whiteColor];
        _loginView.hidden = YES;
        NSString *title = NSLocalizedString(@"Sign in to start your learning journey",@"");
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        UIImageView *imgAvatar = [UIImageView new];
        imgAvatar.frame = CGRectMake((SCREEN_WIDTH - 126)/2, 196 + statusBarH, 126, 100);
        imgAvatar.image = [UIImage imageNamed:@"not_logo"];
        [_loginView addSubview:imgAvatar];
        
        UILabel *lblEmail = [[UILabel alloc]init];
        lblEmail.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
        lblEmail.textAlignment = NSTextAlignmentCenter;
        lblEmail.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        lblEmail.frame = CGRectMake(10, 12 + imgAvatar.frame.origin.y + imgAvatar.frame.size.height, SCREEN_WIDTH -  20, 20);
        lblEmail.text = title;
        [_loginView addSubview:lblEmail];
        
        self.btnLogin.frame = CGRectMake((SCREEN_WIDTH - 161)/2, imgAvatar.frame.origin.y + imgAvatar.frame.size.height + 66 + 0 , 161, 48);
        [_loginView addSubview:self.btnLogin];
    }
    return _loginView;
}
- (UIButton *)btnLogin {
    if(!_btnLogin){
        _btnLogin = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnLogin.layer.cornerRadius = 24;//圆角
        _btnLogin.layer.masksToBounds = YES;
        _btnLogin.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:16];
        [_btnLogin setTintColor:[UIColor whiteColor]];
        [_btnLogin setTitle:NSLocalizedString(@"Sign In Now",@"") forState:UIControlStateNormal];
        [_btnLogin addTarget:self action:@selector(btnLoginAction:) forControlEvents:UIControlEventTouchUpInside];
        _btnLogin.backgroundColor = [self.view colorWithHexString:@"#4C9BEF" alpha:1];
    }
    return _btnLogin;
}
//登录页
- (void)btnLoginAction:(UIButton *)sender {
    NSLog(@"---登录-------------");
    if([[UserModel sharedInstance] isLogin]){//需判断挑战登录
    } else {
        [[LoginManager sharedManager] handleLoginExpiredWithCompletion:^{
            //[self getUserHomeInfo];
        }];
    }
}
- (void)loadNessageTexts {
    for (int i = 0; i < 3; i++) {
        UIButton *btn = (UIButton *)[self.footerView viewWithTag:100 + i];
        NSString *title = @[@"Favorites",@"Orders",@"Clear Cache"][i];
        [btn setTitle:NSLocalizedString(title, @"") forState:UIControlStateNormal];
    }
}
- (void)btnSettingsAction:(UIButton *)sender {
    SettingsViewController *vc = [SettingsViewController new];
    vc.hidesBottomBarWhenPushed = YES;
    vc.strEmail = self.strEmail;
    [self.navigationController pushViewController:vc animated:YES];
}
- (UIView *)headerView {
    if (!_headerView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        //BOOL is_member = IS_Member;
        
        //1 显示 0隐藏
        BOOL is_member = !([[KUSER_DEFAULT objectForKey:IS_Member_key] intValue] == 1);
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 270  + 65 * is_member + statusBarH)];//410
        _headerView.userInteractionEnabled = YES;
        _headerView.clipsToBounds = YES;

        UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 270  + 65 * is_member + statusBarH)];
        imgView.image = [UIImage imageNamed:@"me_bg"];
        [_headerView addSubview:imgView];
        self.imgView = imgView;
        int width = 40;

        UIButton *btnSettings = [UIButton buttonWithType:UIButtonTypeCustom];
        btnSettings.frame = CGRectMake(SCREEN_WIDTH-width-30, statusBarH+20, width, width);
        [btnSettings addTarget:self action:@selector(btnSettingsAction:) forControlEvents:UIControlEventTouchUpInside];
        [btnSettings setImage:[UIImage imageNamed:@"setting_black"] forState:UIControlStateNormal];
        [self.view addSubview:btnSettings];
        self.btnSettings = btnSettings;
        [_headerView addSubview:self.imgAvatar];
        [_headerView addSubview:self.imgVip];
        [_headerView addSubview:self.btnAvatar];
        
        [_headerView addSubview:self.lblUserName];
        [_headerView addSubview:self.lblEmail];
        NSString *avatar = [[UserModel sharedInstance] avatar];
        [self.imgAvatar sd_setImageWithURL:[NSURL URLWithString:avatar]];
           
        self.lblUserName.text = [[UserModel sharedInstance] username];
        self.strEmail = @[[[UserModel sharedInstance] mobile],[[UserModel sharedInstance] email]][IS_OVERSEAS_VERSION];
        self.lblEmail.text = [self maskEmail:self.strEmail];
    
        //-----------------------------------------------------------------------
        if(is_member){
            UIButton *viewVip = [UIButton buttonWithType:UIButtonTypeCustom];
            viewVip.frame = CGRectMake(20, 270 - 12 + statusBarH, SCREEN_WIDTH - 40, 65);
            [_headerView addSubview:viewVip];
            [viewVip addTarget:self action:@selector(btnMembershipAction:) forControlEvents:UIControlEventTouchUpInside];
            self.viewVip = viewVip;
    
            UIImageView *imgIcon = [[UIImageView alloc]initWithFrame:CGRectMake(15, 17, 16 , 13 )];
            imgIcon.tag = 22;
            imgIcon.hidden = YES;
            imgIcon.image = [UIImage imageNamed:@"membership_icon"];
            [viewVip addSubview:imgIcon];
        
            GradientLabel *titleLabel = [[GradientLabel alloc] init];
            self.titleLabel = titleLabel;
            titleLabel.frame = CGRectMake(32, 12,viewVip.frame.size.width - 100 - 32, 22);
            titleLabel.text = NSLocalizedString(@"Membership Center",@"");
            titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
            [viewVip addSubview:titleLabel];
            titleLabel.hidden = YES;
            [titleLabel setGradientColors:@[
                [self.view colorWithHexString:@"#4DECFF" alpha:1], //
                [self.view colorWithHexString:@"#CDF5FF" alpha:1], // CDF5FF
                [self.view colorWithHexString:@"#FEC9FF" alpha:1]  // FEC9FF
            ] locations:nil];
            
            for (int i = 0; i < 2; i++) {
                UILabel *lblTitle = [UILabel new];
                lblTitle.tag = 30 + i;
                if(i==0){
                    lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
                } else {
                    lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
                }
                lblTitle.frame = CGRectMake(15, 12 + 23 * i, viewVip.frame.size.width - 100 - 15, 22 - 2 * i);
               [viewVip addSubview:lblTitle];
            }
         
            UIButton *btnMembership = [UIButton buttonWithType:UIButtonTypeCustom];
            btnMembership.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
            btnMembership.frame = CGRectMake(viewVip.frame.size.width - 89 - 11, (viewVip.frame.size.height - 30)/2, 89, 30);
            btnMembership.userInteractionEnabled = NO;
            [viewVip addSubview:btnMembership];
            self.btnMembership = btnMembership;
            //-----------------------------------------------------------------------
        }
    }
    return _headerView;
}
- (void)btnMembershipAction:(UIButton *)sender {
    
    if(self.vip_status.intValue == 4){
        NSString *urlString = @"itms-apps://apps.apple.com/account/subscriptions";
        NSURL *url = [NSURL URLWithString:urlString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }
    } else {
        PaymentViewController *payVC = [PaymentViewController new];
        payVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:payVC animated:YES];
    }
}
- (void)loadCheckVip {
    if (self.isCheckingVip) return; // 已经在执行中，直接返回
    self.isCheckingVip = YES;
    // 执行你的 VIP 检查逻辑
    NSLog(@"开始检查 VIP");
    // 假设异步请求结束后重置标志
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isCheckingVip = NO;
    });
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"app_region"] = @[@"domestic",@"overseas"][IS_OVERSEAS_VERSION];
    params = [LanguageHelper currentLanguageParams:params];

    [HttpTools postRequest:@"/vip/index" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        if (success) {
            NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
            self.vip_status = [NSString stringWithFormat:@"%@",dic[@"vip_status"]];
            NSString *is_hidden_vip = [NSString stringWithFormat:@"%@",dic[@"is_hidden_vip"]];
            //is_hidden_vip = @"1";
            if (!IS_Member) {
                is_hidden_vip = @"1";
            }
            
            if (is_hidden_vip.intValue == [[KUSER_DEFAULT objectForKey:IS_Member_key] intValue]) {
            } else {
                [KUSER_DEFAULT setObject:is_hidden_vip forKey:IS_Member_key];
                self.headerView = nil;
                self.tableView.tableHeaderView = self.headerView;
                self.imgVip.hidden = is_hidden_vip.boolValue;
            }
            NSLog(@"-----我的页面---------dic=Vip------------[%@]------------",dic);
            //vip 状态 1=非会员，未试用，2=非会员，已过期，3=已订阅（含免费试用），4=已订阅（但取消）
            
            if(self.vip_status.intValue < 5){
                self.trial_time = [NSString stringWithFormat:@"%@",dic[@"trial_time"]];
                NSString *expired_at = [NSString stringWithFormat:@"%@",dic[@"expired_at"]];
                [self setViewVipType:(self.vip_status.intValue - 1) time:expired_at];
            }
            if(self.vip_status.intValue==1 || self.vip_status.intValue==2){
                self.imgVip.hidden = YES;
                self.imgAvatar.layer.borderWidth = 2;
            } else {
                self.imgAvatar.layer.borderWidth = 2 * is_hidden_vip.boolValue;
                self.imgVip.hidden = NO;
            }
            int width = 100;
            self.imgVip.frame = CGRectMake((SCREEN_WIDTH - width)/2 - 5, self.imgAvatar.frame.origin.y - 5, 110, 110 - is_hidden_vip.boolValue * 110);
        }
    }
     failure:^(NSError * _Nonnull error) {
        //NSLog(@"-----me---------dicVip------------[%@]-----error-------",error);
    }];
}
- (void)setViewVipType:(int)type time:(NSString *)timeStr {

    BOOL isIcon = type > 1? YES:NO;
    self.titleLabel.hidden = !isIcon;
    UIImageView *imgIcon = (UIImageView *)[self.viewVip viewWithTag:22];
    imgIcon.hidden = !isIcon;
    
    NSString *localized = [DateHelper autoRenewsOnString:[timeStr doubleValue]];
    NSString *localized2 = [DateHelper subscriptionExpiresString:[timeStr doubleValue]];
    
    NSArray *title0 = @[@"Access All Courses",@"Unlock All Premium Courses",@"",@""];
    //NSArray *title1 = @[@"7-Day Free Trial",@"Your membership has expired.",@"Auto-renews on December 27",@"Subscription expires Dec 27"];
    //@"7-Day Free Trial"
    
    NSString *strFree = [NSString stringWithFormat:@"限时内测特权:0元畅享 %@",self.trial_time];
    if(IS_OVERSEAS_VERSION){
        strFree = [NSString stringWithFormat:@"Early Access ·%@ Free",self.trial_time];
    }
    NSArray *title1 = @[strFree,@"Your membership has expired.",localized,localized2];
    //1=非会员，未试用，2=非会员，已过期，3=已订阅（含免费试用），4=已订阅（但取消
    //3 "Auto-renews on December 27" = "已开通 · 将于5月12日自动续费";
    //4 "Subscription expires Dec 27" = "会员权益将于5月12日到期";
    
    NSArray *colors0 = @[@"#0A59DE",@"#1F1F39",@"#63637D",@"#C3C3FE"];
    NSArray *colors1 = @[@"#0A59DE",@"#63637D",@"#C3C3FE",@"#C3C3FE"];
    NSArray *btnArray = @[@"Free trial",@"Subscribe",@"Membership_me",@"Renew Now"];
    NSString *strImg = @[@"me_membership_0",@"me_membership_1",@"me_membership_2",@"me_membership_2"][type];
    [self.viewVip setBackgroundImage:[UIImage imageNamed:strImg] forState:UIControlStateNormal];
    
    for (int i = 0; i < 2; i++) {
        UILabel *lblTitle = (UILabel *)[self.viewVip viewWithTag:30 + i];
        NSString *strTitle = @[title0[type],title1[type]][i];
        lblTitle.text = NSLocalizedString(strTitle,@"") ;
        if(i==0){
            lblTitle.textColor = [self.view colorWithHexString:colors0[type] alpha:1];
        } else {
            lblTitle.textColor = [self.view colorWithHexString:colors1[type] alpha:1];
        }
    }
    [self.btnMembership setBackgroundImage:[UIImage imageNamed:@[@"me_button_darkblue",@"me_button_colorurs"][type/2]] forState:UIControlStateNormal];
    [self.btnMembership setTitle:NSLocalizedString(btnArray[type],@"") forState:UIControlStateNormal];//未试用
    NSString *strcolor = @[@"#BDE4FF",@"#0D1346"][type/2];
    [self.btnMembership setTitleColor:[self.view colorWithHexString:strcolor alpha:1] forState:UIControlStateNormal];
}

- (UIButton *)btnAvatar {
    if(!_btnAvatar){
        int width = 190;
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        _btnAvatar = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnAvatar.frame = CGRectMake((SCREEN_WIDTH - width)/2, 65 + statusBarH, width, width);
        [_btnAvatar addTarget:self action:@selector(btnAvatarAction:) forControlEvents:UIControlEventTouchUpInside];
        _btnAvatar.backgroundColor = [UIColor clearColor];
    }
    return _btnAvatar;
}
- (UIImageView *)imgAvatar {
    if(!_imgAvatar){
        int width = 100;
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        _imgAvatar = [UIImageView new];
        _imgAvatar.frame = CGRectMake((SCREEN_WIDTH - width)/2, 65 + statusBarH, width, width);
        _imgAvatar.layer.cornerRadius = width/2;//圆角
        _imgAvatar.layer.masksToBounds = YES;
        _imgAvatar.layer.borderWidth = 2;//边框
        _imgAvatar.userInteractionEnabled = NO;
        _imgAvatar.layer.borderColor = [self.view colorWithHexString:@"#F1F9FF" alpha:1].CGColor;

        UIImageView *imgVip = [[UIImageView alloc]init];
        imgVip.image = [UIImage imageNamed:@"user_vip"];
        imgVip.hidden = YES;
        imgVip.userInteractionEnabled = NO;
        self.imgVip = imgVip;
    }
    return _imgAvatar;
}
- (UILabel *)lblUserName {
    if(!_lblUserName){
        _lblUserName = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿M, self.imgAvatar.frame.origin.y + self.imgAvatar.frame.size.height + 16, SCREEN_WIDTH - 2 * Distance＿M, 28)];
        _lblUserName.textColor = BLACK_COLOR_1F;
        _lblUserName.textAlignment = NSTextAlignmentCenter;
        _lblUserName.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:25];
    }
    return _lblUserName;
}
- (UILabel *)lblEmail {
    if(!_lblEmail){
        _lblEmail = [[UILabel alloc]initWithFrame:CGRectMake(self.lblUserName.frame.origin.x, 6 + self.lblUserName.frame.origin.y + self.lblUserName.frame.size.height, self.lblUserName.frame.size.width, 17)];
        _lblEmail.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
        _lblEmail.textAlignment = NSTextAlignmentCenter;
        _lblEmail.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    }
    return _lblEmail;
}
- (UIView *)footerView {
    if (!_footerView) {
        int cellHeight = 56;
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, cellHeight * 3 + 24 + 18 + 52)];
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(Distance＿M, 0, SCREEN_WIDTH - 2 * Distance＿M, cellHeight * 3 + 24)];
        [_footerView addSubview:view];
        view.backgroundColor = [UIColor whiteColor];
        view.layer.cornerRadius = 12;//圆角
        view.layer.masksToBounds = YES;

        for (int i = 0; i < 3; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            btn.frame = CGRectMake(0, cellHeight * i + 12, SCREEN_WIDTH - 2 * Distance＿M, cellHeight);
            [view addSubview:btn];
            UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"profile_%d",i]];

            btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Medium size:15];
            [btn setTintColor:BLACK_COLOR_1F];
            btn.tag = 100 + i;
            btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            btn.titleEdgeInsets = UIEdgeInsetsMake(0,52, 0, 0);
            [btn addTarget:self action:@selector(btnCellAction:) forControlEvents:UIControlEventTouchUpInside];
            UIImageView *img = [[UIImageView alloc]initWithFrame:CGRectMake(20, (cellHeight-18)/2, 18, 18)];
            img.image = image;
            [btn addSubview:img];
          
            UIImageView *imgArrow = [[UIImageView alloc]initWithFrame:CGRectMake(btn.frame.size.width - 22 - 15, (cellHeight-15)/2, 15, 15)];
            imgArrow.image = [UIImage imageNamed:@"arrow_black"];
            [btn addSubview:imgArrow];
        }
    }
    return _footerView;
}
- (void)btnCellAction:(UIButton *)sender {

    int tag = (int)sender.tag - 100;
    switch (tag) {
        case 0:
        {
            YTVFavoritesListViewController *vc = [YTVFavoritesListViewController new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 1:
        {
            OrdersViewController *vc = [OrdersViewController new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 2:
        {
            ClearCacheViewController *vc = [ClearCacheViewController new];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        default:
            break;
    }
}
- (UITableView *)tableView {
    if (!_tableView) {
        CGFloat statusBarH = 0;//[PublicTool getStatusBarHeight];
        CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;
        CGRect frame =  CGRectMake(0, statusBarH , SCREEN_WIDTH, SCREEN_HEIGHT - statusBarH - tabBarHeight);
        _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.sectionFooterHeight = CGFLOAT_MIN;
        _tableView.sectionHeaderHeight = CGFLOAT_MIN;
        _tableView.userInteractionEnabled = YES;
        _tableView.backgroundColor = [self.view colorWithHexString:@"#F5F9FF" alpha:1];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        // 2. 禁用自动调整 contentInset（iOS 11+）
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _tableView;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
   if (cell == nil){
       cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
   }
   return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 76;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView reloadData];
}

- (NSString *)maskEmail:(NSString *)email {
    
    if(IS_OVERSEAS_VERSION){
        if (!email || email.length == 0) {
            return email;
        }
        NSRange atRange = [email rangeOfString:@"@"];
        if (atRange.location == NSNotFound) {
            return email;
        }
        NSString *prefix = [email substringToIndex:atRange.location];
        NSString *suffix = [email substringFromIndex:atRange.location];
        
        // 处理前缀部分
        if (prefix.length <= 4) {
            // 创建指定数量的星号字符串
            NSMutableString *asterisks = [NSMutableString string];
            for (NSInteger i = 0; i < prefix.length; i++) {
                [asterisks appendString:@"*"];
            }
            return [NSString stringWithFormat:@"%@%@", asterisks, suffix];
        } else {
            // 保留前2位和后2位，中间用4个*替换
            NSString *firstPart = [prefix substringToIndex:2];
            NSString *lastPart = [prefix substringFromIndex:prefix.length - 2];
            return [NSString stringWithFormat:@"%@****%@%@", firstPart, lastPart, suffix];
        }
        
    } else {
        
        NSString *phone = email;
        if (!phone || phone.length < 7) {
            return phone; // 长度不够，不处理
        }
        NSString *firstPart = [phone substringToIndex:3];       // 前3位
        NSString *lastPart = [phone substringFromIndex:7];      // 后4位
        return [NSString stringWithFormat:@"%@****%@", firstPart, lastPart];
    }
}
- (void)getUserHomeInfo {
    
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
