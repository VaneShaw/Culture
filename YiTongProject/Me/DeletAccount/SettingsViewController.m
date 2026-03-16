//
//  SettingsViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/26.
//

#import "SettingsViewController.h"
#import "LanguageViewController.h"
#import "DeleteAccountViewController.h"
@interface SettingsViewController ()<UIGestureRecognizerDelegate,UINavigationControllerDelegate,UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *dataArray;
@property (strong, nonatomic) UIView *headerView;
@end

@implementation SettingsViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [self.view colorWithHexString:@"#F5F9FF" alpha:1];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.delegate = self;
    [self addGlobalBackButtonColor:[self.view colorWithHexString:@"#FFFFFF" alpha:1] headerTitleDic:@{}];
    
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(80, statusBarH, SCREEN_WIDTH - 160, navigationBarHeight)];
    lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:16];
    lblTitle.textColor = BLACK_COLOR_1F;
    lblTitle.textAlignment = NSTextAlignmentCenter;
    lblTitle.text = NSLocalizedString(@"Settings",@"");
    [self.view addSubview:lblTitle];
    
    [self.view addSubview:self.tableView];
    self.tableView.tableHeaderView = self.headerView;
}
- (UIView *)headerView {
    if (!_headerView) {
        //NSArray *dataArray = @[NSLocalizedString(@"Log out", @""),NSLocalizedString(@"Delete Account", @""),NSLocalizedString(@"Language", @"")];
        NSArray *dataArray = @[NSLocalizedString(@"Log out", @""),NSLocalizedString(@"Delete Account1", @"")];
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 270 + 70)];//410
      
        for (int i = 0; i < dataArray.count; i++) {
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(Distance＿M, 64 * i, SCREEN_WIDTH - 2 * Distance＿M, 52 + 18 * i)];
            view.backgroundColor = [UIColor whiteColor];
            view.layer.cornerRadius = 12;//圆角
            view.layer.masksToBounds = YES;
            [_headerView addSubview:view];
            
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            btn.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
            btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:16];
            btn.tag = 100 + i;
            [btn setTintColor:BLACK_COLOR_1F];
            btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            [btn addTarget:self action:@selector(btnCellAction:) forControlEvents:UIControlEventTouchUpInside];
            [view addSubview:btn];
            [btn setTitle:dataArray[i] forState:UIControlStateNormal];
            btn.titleEdgeInsets = UIEdgeInsetsMake(0,20, 0, 0);
            if(i==1){
                btn.titleEdgeInsets = UIEdgeInsetsMake(16,20, view.frame.size.height/2, 0);
                
                UILabel *lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(20,40, view.frame.size.width, 14)];
                lblSubtitle.textColor = [self.view colorWithHexString:@[@"#63637D",@"#B5B5B5"][IS_OVERSEAS_VERSION] alpha:1];
                lblSubtitle.textAlignment = NSTextAlignmentLeft;
                lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
                lblSubtitle.text = NSLocalizedString(@"Deleted accounts cannot be restored",@"");
                [btn addSubview:lblSubtitle];
            }
           
            UIImageView *imgArrow = [[UIImageView alloc]initWithFrame:CGRectMake(btn.frame.size.width - 22 - 20, (view.frame.size.height-20)/2, 20, 20)];
            imgArrow.image = [UIImage imageNamed:@"frame_blakc"];
            [btn addSubview:imgArrow];
        }
    }
    return _headerView;
}
- (void)btnCellAction:(UIButton *)sender {

    int tag = (int)sender.tag - 100;
    switch (tag) {
        case 0:
        {
          
            NSArray *titleArray = @[@"Ready to log out?",@"Your learning progress will be saved. You can continue anytime.",@"Cancel",@"Log out"];
            [ReadyLogOutView showViewTitle:@"" buttonArrayTitle:titleArray callBack:^(NSInteger index) {
                if(index==1001){
                    [self btnLogout];
                }
            }];
        }
            break;
        case 1:
        {
            DeleteAccountViewController *vc = [DeleteAccountViewController new];
            vc.strEmail = self.strEmail;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 2:
        {
            LanguageViewController *vc = [LanguageViewController new];
            [self.navigationController pushViewController:vc animated:YES];
           
        }
            break;
        default:
            break;
    }
}
- (void)btnLogout {

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:@[@"/authCn/logout",@"/auth/logout"][IS_OVERSEAS_VERSION] parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {

         if (success) {

             [[UserModel sharedInstance] logout];
             [[AnalyticsManager shared] trackEvent:EventTypeLogout event_name:@"退出" params:nil];

             if(IS_OVERSEAS_VERSION){
                 self.tabBarController.selectedIndex = 0;
//                 LoginViewController *loginVC = [LoginViewController new];
//                 UINavigationController *loginNC = [[UINavigationController alloc]initWithRootViewController:loginVC];
//                 loginNC.modalPresentationStyle = 0;
//                 [theAppDelegate setNavieationBarColor:loginNC];
//                 [self presentViewController:loginNC animated:YES completion:^{
//                     self.tabBarController.selectedIndex = 0;
//                 }];
             } else {
                 self.tabBarController.selectedIndex = 0;
                 
//                 PhoneLoginViewController *loginVC = [[PhoneLoginViewController alloc] init];
//                 UINavigationController *loginNC = [[UINavigationController alloc]initWithRootViewController:loginVC];
//                 loginNC.modalPresentationStyle = 0;
//                 [theAppDelegate setNavieationBarColor:loginNC];
//                 [self presentViewController:loginNC animated:YES completion:^{
//                     self.tabBarController.selectedIndex = 0;
//                 }];
             }
             [self.navigationController popViewControllerAnimated:YES];
         }  else {
             [MBProgressHUD showLabel:response.msg];
         }
        
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (UITableView *)tableView {
    if (!_tableView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height + 27;
        CGRect frame =  CGRectMake(0, statusBarH + navigationBarHeight , SCREEN_WIDTH, SCREEN_HEIGHT - statusBarH - navigationBarHeight);
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
