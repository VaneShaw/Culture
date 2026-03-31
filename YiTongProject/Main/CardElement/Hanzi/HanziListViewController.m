//
//  HanziListViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/17.
//

#import "HanziListViewController.h"
#import "HanziCardViewController.h"
//#import "InitialsTableViewCell.h"
#import "HanziListTableViewCell.h"
#import "CardElementViewController.h"
@interface HanziListViewController ()<UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate,UINavigationControllerDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *dataArrays;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;

@property (nonatomic, assign) BOOL isCategoryListLoaded;
@end

@implementation HanziListViewController

//刷新列表汉字是否已读
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    [KUSER_DEFAULT setObject:@"Listen" forKey:Card_Type];
    
    if ([UserStateManager shared].needRefreshVipUI) {
           [self onMembershipUpdated];
           [UserStateManager shared].needRefreshVipUI = NO;
       }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"hanzi_list";
    //self.category_id = @"26";
    
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.delegate = self;
    [self addGlobalBackButton];

    self.dataArrays = [NSMutableArray new];
    [self.view addSubview:self.tableView];
    self.tableView.tableHeaderView = self.headerView;
    [self setupMJRefresh];
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(onMembershipUpdated)
                                                   name:IAP_Membership_Notification
                                                 object:nil];*/
}
- (void)onMembershipUpdated{
    [self getCategoryList];
}

- (UIView *)headerView {
    if (!_headerView) {
        CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, 165-10);
        _headerView = [[UIView alloc]initWithFrame:frame];
        _headerView.backgroundColor = [UIColor whiteColor];
        [_headerView addSubview:self.lblTitle];
        [_headerView addSubview:self.lblSubtitle];
    }
    return _headerView;
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿M, 35, SCREEN_WIDTH - 2 * Distance＿M, 25)];
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:20];
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(self.lblTitle.frame.origin.x, 12 + self.lblTitle.frame.origin.y + self.lblTitle.frame.size.height, self.lblTitle.frame.size.width, 45)];
        _lblSubtitle.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
        _lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        _lblSubtitle.numberOfLines = 2;
    }
    return _lblSubtitle;
}
- (UITableView *)tableView {
    if (!_tableView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGRect rectNav = self.navigationController.navigationBar.frame;
        CGRect frame =  CGRectMake(0, statusBarH + rectNav.size.height, SCREEN_WIDTH, SCREEN_HEIGHT - statusBarH - rectNav.size.height-IPHONE_X*24);
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
    HanziListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
   if (cell == nil){
       cell = [[HanziListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
   }
    [cell setCell:self.dataArrays[indexPath.row]];
    [cell setSelectedTypeIndex:^(NSInteger selectedIndex) {
        
        if([[UserModel sharedInstance] isLogin]){
            int tag = (int)selectedIndex - 1300;
            NSDictionary *dic = @{@"page":[NSString stringWithFormat:@"%d",tag],@"index":[NSString stringWithFormat:@"%@",@"0"]};
            NSString *category_id = [NSString stringWithFormat:@"%@",self.dataArrays[indexPath.row][@"id"]];
            [[IDStorageManager sharedManager] saveValue:dic forId:category_id];
        }
        [self showCharacterDetailAtIndex:indexPath.row];
    }];
    
   return cell;
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
    [self getCategoryList];
    [self.tableView.mj_header endRefreshing];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArrays.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dic = self.dataArrays[indexPath.row];
    NSArray *array = [NSArray arrayWithArray:dic[@"elements"]];
    //NSInteger isCount = (array.count - 1) / 5 + 1;
    NSInteger isCount = (array.count + 4) / 5;

    return 67 + 12 + 4 + (16 + 50) * isCount - 4 + 16;
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN; // 比 0.1 更小的值
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    [self showCharacterDetailAtIndex:indexPath.row];
    
}
- (void)showCharacterDetailAtIndex:(NSInteger)index {
    if([[UserModel sharedInstance] isLogin]){//需判断登录
        NSString *is_lock = [NSString stringWithFormat:@"%@",self.dataArrays[index][@"is_lock"]];
        if(!IS_Member){
            is_lock = @"0";
        }
        if(is_lock.boolValue){//跳支付
            PaymentViewController *payVC = [PaymentViewController new];
            payVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:payVC animated:YES];

        } else {
            CardElementViewController *cardVC = [CardElementViewController new];
            cardVC.isHanZi = YES;
            cardVC.category_id = [NSString stringWithFormat:@"%@",self.dataArrays[index][@"id"]];
            __weak typeof(self) weakSelf = self;
            [cardVC setSelectedTypeIndex:^(NSInteger index) {
                [weakSelf getCategoryList];
            }];
            [self.navigationController pushViewController:cardVC animated:YES];
        }
       
    } else {
        [[LoginManager sharedManager] handleLoginExpiredWithCompletion:^{
            // 登录完成后的逻辑
            NSLog(@"登录完成，回到调用方法");
            [self getCategoryList];
        }];
    }
}


- (void)getCategoryList{
    __weak typeof(self) weakSelf = self;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    params[@"app_region"] = @[@"domestic",@"overseas"][IS_OVERSEAS_VERSION];
    __block BOOL hudHidden = NO;// 2. 创建一个 __block 标志，防止重复隐藏
    if (!self.isCategoryListLoaded) {
        // 1. 显示加载动画
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        // 3. 设置超时隐藏（例如 4 秒）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!hudHidden) {
                hudHidden = YES;
                __strong typeof(weakSelf) self = weakSelf;
                if (self) {
                    [MBProgressHUD hideHUDForView:self.view animated:YES]; //转圈圈隐藏
                    NSLog(@"⏱ HUD auto hidden after timeout");
                }
            }
        });
    }
    
    [HttpTools postRequest:@"/hanzi/getCategoryList" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (!hudHidden) {
               hudHidden = YES;
               [MBProgressHUD hideHUDForView:self.view animated:YES];
           }
        self.isCategoryListLoaded = YES;
        
         if (success) {
             [MBProgressHUD hideHUDForView:self.view animated:YES];
             NSDictionary *dicData = [NSDictionary dictionaryWithDictionary:response.data];
             self.dataArrays = [NSMutableArray new];
             [self.dataArrays addObjectsFromArray:dicData[@"sub_categories"]];
    
             //==========================================
             NSInteger maxIsCount = 0;
             for (NSDictionary *dic in self.dataArrays) {
                 NSArray *array = dic[@"elements"];
                 NSInteger isCount = (array.count + 4) / 5;
                 maxIsCount = MAX(maxIsCount, isCount);
             }
             [KUSER_DEFAULT setInteger:maxIsCount forKey:@"maxIsCount_key"];
             //==========================================
             
             NSDictionary *dic = [NSDictionary dictionaryWithDictionary:dicData[@"top_category"]];
             if(dic){
                 self.lblTitle.text = [NSString stringWithFormat:@"%@",dic[@"title"]];
                 NSString *remark = [NSString stringWithFormat:@"%@",dic[@"subtitle"]];
                 if([remark isEqualToString:@"<null>"]){
                     remark = @"";
                 }
                 self.lblSubtitle.text = remark;
                 [self.lblSubtitle sizeToFit];
                 CGSize labelSize = [self.lblSubtitle sizeThatFits:CGSizeMake(SCREEN_WIDTH - 2 * Distance＿M,MAXFLOAT)];
                 self.headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 100 + labelSize.height);
             }
             [self.tableView checkEmptyWithDataCount:self.dataArrays.count];
             [self.tableView reloadData];
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
@end


