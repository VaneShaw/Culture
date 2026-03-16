//
//  SubscriptionSetViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/9.
//

#import "SubscriptionSetViewController.h"
#import "ReceiptSyncManager.h"
@interface SubscriptionSetViewController ()<UIGestureRecognizerDelegate,UINavigationControllerDelegate,UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *dataArray;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UIView *footerView;
@end

@implementation SubscriptionSetViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.delegate = self;
    [self addGlobalBackButtonColor:[self.view colorWithHexString:@"#F1F1F1" alpha:1] headerTitleDic:@{@"title":@"Manage Subscriptions",@"color":@"#1F1F39"}];
    [self.view addSubview:self.tableView];
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = self.footerView;
}
- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 300)];//410
        _headerView.backgroundColor = [UIColor whiteColor];
        
        UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(20, 30, SCREEN_WIDTH - 40, 22)];
        lblTitle.font = [UIFont fontWithName:FONT_NAME_Medium size:16];
        lblTitle.textColor = [self.view colorWithHexString:@"#000000" alpha:1];
        lblTitle.text = NSLocalizedString(@"Restore VIP", @"");
        [_headerView addSubview:lblTitle];
        UILabel *lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(20, 60,SCREEN_WIDTH - 40, 60)];
        lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        lblSubtitle.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
        lblSubtitle.numberOfLines = 0;
     
        NSString *strEmail = @[[[UserModel sharedInstance] mobile],[[UserModel sharedInstance] email]][IS_OVERSEAS_VERSION];
        NSString *strAccount = [self maskEmail:strEmail];
        NSString *str1 = NSLocalizedString(@"Current logged-in account:", @"");
        NSString *str2 = NSLocalizedString(@"If you previously purchased a membership with this account via App Store or Google Play, please click the “Restore Purchase” button below to recover your VIP benefits.", @"");
        lblSubtitle.text = [NSString stringWithFormat:@"%@%@\n%@",str1,strAccount,str2];
        [_headerView addSubview:lblSubtitle];

        //当前登录的账号：157****1902 若您之前使用该账号购买过会员，请点击下方“恢复购 买”按钮，找回您的 VIP 权益。
        CGSize labelSize = [lblSubtitle sizeThatFits:CGSizeMake(SCREEN_WIDTH - 40,MAXFLOAT)];
        lblSubtitle.frame = CGRectMake(20, 60,SCREEN_WIDTH - 40,labelSize.height + 10);
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(20, 60 + labelSize.height + 10 + 20, SCREEN_WIDTH - 40, 44);
        btn.layer.cornerRadius = 8;//圆角
        btn.layer.masksToBounds = YES;
        btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        btn.backgroundColor = [self.view colorWithHexString:@"#4C9BEF" alpha:1];
        [btn setTitle:NSLocalizedString(@"Restore Purchase", @"") forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnResetAction:) forControlEvents:UIControlEventTouchUpInside];
        [_headerView addSubview:btn];
        _headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 60 + labelSize.height + 10 + 20 + 44 + 30);
        
    }
    return _headerView;
}
- (void)btnResetAction:(UIButton *)sender {
    sender.backgroundColor = [self.view colorWithHexString:@"#4C9BEF" alpha:0.9];
    sender.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.userInteractionEnabled = YES;
        sender.backgroundColor = [self.view colorWithHexString:@"#4C9BEF" alpha:1];
        });
    
    if(self.vip_status.intValue == 3 || self.vip_status.intValue == 4){
        NSString *message = @"You’re already subscribed.";
        [MBProgressHUD showLabel:NSLocalizedString(message, @"")];
    } else {
        //判断迁移
        [[ReceiptSyncManager sharedManager] syncReceiptIfNeeded];
    }
    //[self redirectToSubscriptionPage];
}
- (void)redirectToSubscriptionPage {
    // 使用 App Store 的订阅管理链接
    //NSString *urlString = @"https://apps.apple.com/account/subscriptions";
    //NSURL *url = [NSURL URLWithString:urlString];

    NSString *urlString = @"itms-apps://apps.apple.com/account/subscriptions";
    NSURL *url = [NSURL URLWithString:urlString];
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:url
                                           options:@{}
                                 completionHandler:^(BOOL success) {
            if (!success) {
                [self showErrorAlert];
            }
        }];
    } else {
        BOOL success = [[UIApplication sharedApplication] openURL:url];
        if (!success) {
            [self showErrorAlert];
        }
    }
}

- (void)showErrorAlert {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"无法打开"
                         message:@"无法打开App Store订阅页面，请稍后重试"
                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction
        actionWithTitle:@"确定"
                  style:UIAlertActionStyleDefault
                handler:nil];
    
    [alert addAction:okAction];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (UIView *)footerView {
    if (!_footerView) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 300)];//410
        _footerView.backgroundColor = [UIColor whiteColor];
        
        UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(20, 0, SCREEN_WIDTH - 40, 1)];
        lineView.backgroundColor = [self.view colorWithHexString:@"#EAEAEA" alpha:1];
        [_footerView addSubview:lineView];
        
        UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(20, 30, SCREEN_WIDTH - 40, 22)];
        lblTitle.font = [UIFont fontWithName:FONT_NAME_Medium size:16];
        lblTitle.textColor = [self.view colorWithHexString:@"#000000" alpha:1];
        lblTitle.text = NSLocalizedString(@"Unsubscribe Guide", @"");
        [_footerView addSubview:lblTitle];
        

        
        UILabel *lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(20, 60,SCREEN_WIDTH - 40, 60)];
        lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        lblSubtitle.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
        lblSubtitle.numberOfLines = 0;
        
        NSString *str1 = NSLocalizedString(@"iOS / App Store: Open Settings on your iPhone → Tap your Apple ID  at the top → Subscriptions → Find [YTong] → Tap  Cancel Subscription.", @"");
        NSString *str2 = NSLocalizedString(@"Google Play: Open the Google Play Store → Tap your profile icon  at the top right → Payments & subscriptions →  Subscriptions→ Find [YTong] → Tap Cancel Subscription.", @"");
      
        NSString *str11 = NSLocalizedString(@"[Cancel via WeChat]:Open WeChat → Me → Services → Wallet → Payment Settings → Auto-Deduct to cancel.", @"");
        NSString *str22 = NSLocalizedString(@"[Cancel via Alipay]:Open Alipay → Me → Settings → Payment Settings → Auto-Debit to cancel.", @"");
        NSString *str33 = NSLocalizedString(@"[Cancel via Apple]:Go to Settings → Apple ID → Subscriptions and cancel YTong Membership.", @"");
        

        if(IS_OVERSEAS_VERSION){
            lblSubtitle.text =  [NSString stringWithFormat:@"%@\n\n%@",str1,str2];
            
        } else {
            lblSubtitle.text =  [NSString stringWithFormat:@"%@\n\n%@\n\n%@",str11,str22,str33];
            
        }
        
        [_footerView addSubview:lblSubtitle];
        
        CGSize labelSize = [lblSubtitle sizeThatFits:CGSizeMake(SCREEN_WIDTH - 40,MAXFLOAT)];
        lblSubtitle.frame = CGRectMake(20, 60,SCREEN_WIDTH - 40,labelSize.height + 10);
        
        _footerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 60 + labelSize.height + 10 + 20 );
    }
    return _footerView;
}
- (UITableView *)tableView {
    if (!_tableView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
        CGRect frame =  CGRectMake(0, statusBarH + navigationBarHeight , SCREEN_WIDTH, SCREEN_HEIGHT - statusBarH - navigationBarHeight);
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
    return 0;
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

