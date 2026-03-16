//
//  StartPinyinViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/7/3.
//

#import "StartPinyinViewController.h"
#import "LettersView.h"
#import "ShadowView.h"

#import "PinyinLettersViewController.h"
#import "InitialsViewController.h"
@interface StartPinyinViewController ()<UITableViewDataSource,UITableViewDelegate,UIGestureRecognizerDelegate,UINavigationControllerDelegate>
@property (strong,nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *dataArray;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) LettersView *lettersView;
@property (strong, nonatomic) UIImageView *bubbleView;
@end

@implementation StartPinyinViewController
//刷新列表Start   with Pinyin更新进度

//拼音-分类首页    -拼音字母表，声母，韵母，声调，整体认读音节
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    
    if ([UserStateManager shared].needRefreshVipUI) {
        [self onMembershipUpdated];
        [UserStateManager shared].needRefreshVipUI = NO;
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"pinyin";
    
    // Do any additional setup after loading the view.
    self.navigationItem.title = NSLocalizedString(@"Start with Pinyin", @"");
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.delegate = self;
    [self addGlobalBackButton];
    
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(80, statusBarH, SCREEN_WIDTH - 160, 44)];
    lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:18];
    lblTitle.textColor = BLACK_COLOR_1F;
    lblTitle.textAlignment = NSTextAlignmentCenter;
    lblTitle.text = NSLocalizedString(@"Start with Pinyin", @"");
    [self.view addSubview:lblTitle];
    
    [self.view addSubview:self.tableView];
    self.tableView.tableHeaderView = self.headerView;
    UIView *footerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, CGFLOAT_MIN)];
    self.tableView.tableFooterView = footerView;
    
    NSDictionary *dic = @{@"bg_color" : @"#F2F3F5",
                          @"button" : @"",
                          @"button_color" : @"",
                          @"completed_number" : @"",
                          @"id" : @"",
                          @"label" : @"",
                          @"remark" : @"",
                          @"subtitle" : @"",
                          @"title" : @"",
                          @"total_number" : @""};
    
    self.dataArray = [[DataCacheManager loadDataForClass:[self class]] mutableCopy];
    if (self.dataArray.count > 0) {
        [self setCell:self.dataArray];
    } else {
        self.dataArray = @[dic,dic,dic,dic,dic,dic];
        [self setCell:self.dataArray];
    }
    [self setupMJRefresh];
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(onMembershipUpdated)
                                                   name:IAP_Membership_Notification
                                                 object:nil];*/
    
}
- (void)onMembershipUpdated{
    [self getPinyinCategory];
}
- (UITableView *)tableView {
    if (!_tableView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGRect rectNav = self.navigationController.navigationBar.frame;
        CGRect frame =  CGRectMake(0,statusBarH + rectNav.size.height + 10, SCREEN_WIDTH, SCREEN_HEIGHT - statusBarH - rectNav.size.height - 10);
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
- (void)btnChartAction:(UIButton *)snder {
    PinyinLettersViewController *lettersVC = [PinyinLettersViewController new];
    if(self.dataArray.count>0){
        lettersVC.dic = self.dataArray[0];
    }
    [self.navigationController pushViewController:lettersVC animated:YES];
}
- (void)btnStartAction:(UIButton *)sender {
    
    if([[UserModel sharedInstance] isLogin]){//需判断登录
        int row = (int)sender.tag - 61;
        NSString *is_lock = [NSString stringWithFormat:@"%@",self.dataArray[row+1][@"is_lock"]];
        if(!IS_Member){
            is_lock = @"0";
        }
        if(is_lock.boolValue){//跳支付
            PaymentViewController *payVC = [PaymentViewController new];
            payVC.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:payVC animated:YES];
//            payVC.paymentView.payResultCallback = ^(BOOL success) {
//                if(success){
//                    [self getPinyinCategory];
//                }
//            };
            
        } else {
            
            //必须要拿到这里的key, 后面字典要用到,否则闪退
            //NSString *key = @[@"blue",@"green",@"orange",@"purple"][row%4];
            //[KUSER_DEFAULT setObject:key forKey:@"color_key"];
            [ColorManager saveColorKeyForRow:row];
            NSDictionary *dic = [NSDictionary dictionaryWithDictionary:self.dataArray[row+1]];

            InitialsViewController *initialsVC = [InitialsViewController new];
            initialsVC.category_id = [NSString stringWithFormat:@"%@",dic[@"id"]];
            
            initialsVC.colorButton = [NSString stringWithFormat:@"%@",dic[@"button_color"]];
            __weak typeof(self) weakSelf = self;
            [initialsVC setCompletionBlock:^(NSString * _Nonnull data) {
                if(data.boolValue){
                    [weakSelf getPinyinCategory];
                }
            }];
            [self.navigationController pushViewController:initialsVC animated:YES];
        }
   
    } else {
        [[LoginManager sharedManager] handleLoginExpiredWithCompletion:^{
            // 登录完成后的逻辑
            NSLog(@"登录完成，回到调用方法");
            [self getPinyinCategory];
        }];
    }
    
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
    if(self.dataArray.count > 0){
        [KUSER_DEFAULT setBool:YES forKey:@"DataChanged_KEY"];
    }

    [self getPinyinCategory];
    [self.tableView.mj_header endRefreshing];
}


-(void)setCell:(NSArray *)dataArray {
    NSDictionary *dic0 = dataArray[0];
    NSString *title = [NSString stringWithFormat:@"%@",dic0[@"title"]];
    self.lettersView.lblTitle.text = title;
    self.lettersView.lblSubtitle.text = [NSString stringWithFormat:@"%@",dic0[@"subtitle"]];
    int temp = 20;
    CGSize labelSize3 = [self.lettersView.lblTitle sizeThatFits:CGSizeMake((SCREEN_WIDTH - 55)/2 - 24,MAXFLOAT)];
    self.lettersView.lblTitle.frame = CGRectMake(12, 22, (SCREEN_WIDTH - 55)/2 - temp, labelSize3.height + 2);
    CGSize labelSize4 = [self.lettersView.lblSubtitle sizeThatFits:CGSizeMake((SCREEN_WIDTH - 55)/2 - temp,MAXFLOAT)];
    self.lettersView.lblSubtitle.frame = CGRectMake(12,self.lettersView.lblTitle.frame.size.height + 3 + 22, (SCREEN_WIDTH - 55)/2 - temp, labelSize4.height + 2);
    
    [self.lettersView.btnChart setTitle:[NSString stringWithFormat:@"%@",dic0[@"button"]] forState:UIControlStateNormal];
    NSString *color11 = [NSString stringWithFormat:@"%@",dic0[@"bg_color"]];
    NSString *color22 = [NSString stringWithFormat:@"%@",dic0[@"button_color"]];
    self.lettersView.backgroundColor = [self.view colorWithHexString:color11 alpha:1];
    self.lettersView.btnChart.backgroundColor = [self.view colorWithHexString:color22 alpha:1];
    self.lettersView.btnChart.hidden = [title isEqualToString:@""]? YES:NO;
    self.lettersView.layer.shadowOpacity = 0.2 * !self.lettersView.btnChart.hidden;

    for (int i = 1; i < dataArray.count; i++){
        NSDictionary *dic = dataArray[i];
        ShadowView *shadowView = (ShadowView *)[self.headerView viewWithTag:50 + i];
        shadowView.lblTitle.text = [NSString stringWithFormat:@"%@",dic[@"title"]];
        shadowView.lblSubtitle.text = [NSString stringWithFormat:@"%@",dic[@"subtitle"]];
        shadowView.lblSubtitle.frame = CGRectMake(12, 52, (SCREEN_WIDTH - 55)/2 - temp, 36 + 5);// MAXFLOAT);
        [shadowView.lblSubtitle sizeToFit];
        
        if(i == 4){
            CGSize labelSize = [shadowView.lblTitle sizeThatFits:CGSizeMake((SCREEN_WIDTH - 55)/2 - temp,MAXFLOAT)];
            shadowView.lblTitle.frame = CGRectMake(12, 22, (SCREEN_WIDTH - 55)/2 - temp, labelSize.height + 2);
            CGSize labelSize2 = [shadowView.lblSubtitle sizeThatFits:CGSizeMake((SCREEN_WIDTH - 55)/2 - temp,MAXFLOAT)];
            shadowView.lblSubtitle.frame = CGRectMake(12, shadowView.lblTitle.frame.size.height + 3 + 22, (SCREEN_WIDTH - 55)/2 - temp, labelSize2.height + 2);
        }
        
        shadowView.lblState.text = [NSString stringWithFormat:@"%@",dic[@"label"]];
        [shadowView.btnStart setTitle:[NSString stringWithFormat:@"%@",dic[@"button"]] forState:UIControlStateNormal];
        NSString *color1 = [NSString stringWithFormat:@"%@",dic[@"bg_color"]];
        NSString *color2 = [NSString stringWithFormat:@"%@",dic[@"button_color"]];
        shadowView.backgroundColor = [self.view colorWithHexString:color1 alpha:1];
        shadowView.btnStart.backgroundColor = [self.view colorWithHexString:color2 alpha:1];
        
        NSString *is_lock = [NSString stringWithFormat:@"%@",dic[@"is_lock"]];
        if(!IS_Member){
            is_lock = @"0";
        }
        shadowView.cover.backgroundColor = [self.view colorWithHexString:color1 alpha:0.9];
        [shadowView.cover updateIconImageColor:[self.view colorWithHexString:color2 alpha:1] bgColor:@""];
        shadowView.cover.hidden = !is_lock.boolValue;
#ifdef DEBUG
        //shadowView.cover.hidden = NO;//测试用
#endif
        NSString *str = [NSString stringWithFormat:@"%@/%@",dic[@"completed_number"],dic[@"total_number"]];
        NSArray *components = [str componentsSeparatedByString:@"/"];
        float numerator = [components[0] floatValue];   // 分子（50）
        float denominator = [components[1] floatValue]; // 分母（60）
        float result = numerator / denominator;
        [shadowView.progressView setColorProgress:result color:color2 alpha:0.5 animated:YES];
        if([str isEqualToString:@"/"]){
            str = @"";
        }
        shadowView.lblCompletion.text = str;
        shadowView.progressView.hidden = [str isEqualToString:@""]? YES:NO;
        shadowView.layer.shadowOpacity = 0.2 * !self.lettersView.btnChart.hidden;
    }
}
- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc]init];
        _headerView.backgroundColor = [UIColor whiteColor];
        LettersView *lettersView = [[LettersView alloc] initWithFrame:CGRectMake(20, 10, (SCREEN_WIDTH - 55)/2, 172)];
        lettersView.shadowColor = [UIColor colorWithWhite:0.6 alpha:1.0]; // 深灰色阴影
        lettersView.shadowRadius = 5.0; //更柔和的阴影
        [lettersView.btnView addTarget:self action:@selector(btnChartAction:) forControlEvents:UIControlEventTouchUpInside];
        [_headerView addSubview:lettersView];
        //lettersView.hidden = YES;
        self.lettersView = lettersView;
        
        int cellheight = 238;
        int height = (cellheight + 15);
        int width = SCREEN_WIDTH - 55;
    
        for (int i = 1; i < 5; i++) {
            ShadowView *shadowView = [ShadowView new];
            if(i==4){
                //shadowView.lblTitle.frame = CGRectMake(15, 25, (SCREEN_WIDTH - 55)/2 - 30, 45);
                //shadowView.lblTitle.frame = CGRectMake(12, 22, (SCREEN_WIDTH - 55)/2 - 24, 25);
                //shadowView.lblTitle.numberOfLines = 2;
            }
            if(i%2==0){
                shadowView.frame = CGRectMake(20 + (width/2 + 15)* (i%2), 10 + (cellheight + 15) * (i/2 - 1) + (172 + 15), width/2, cellheight);
            } else {
                shadowView.frame = CGRectMake(20 + (width/2 + 15)* (i%2), 10 + (cellheight + 15) *(i/2) , width/2, cellheight);
            }
            //shadowView.hidden = YES;
            shadowView.tag = 50 + i;
            shadowView.shadowColor = [UIColor colorWithWhite:0.6 alpha:1.0];//深灰色阴影
            shadowView.shadowRadius = 5.0; // 更柔和的阴影
            [_headerView addSubview:shadowView];
            shadowView.btnView.tag = 60 + i;
            [shadowView.btnView addTarget:self action:@selector(btnStartAction:) forControlEvents:UIControlEventTouchUpInside];
        }
   
        _headerView.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.lettersView.frame.size.height + 32 + 2 * height);
        // 创建气泡视图
        UIImageView *bubbleView = [[UIImageView alloc] initWithFrame:CGRectMake(35 + width/2, height * 2 + 35, width/2, 80 + 15)];
        bubbleView.image = [UIImage imageNamed:@"Slice_blue"];
        bubbleView.hidden = YES;
        self.bubbleView = bubbleView;
        
        UILabel *lblMessage = [[UILabel alloc]initWithFrame:CGRectMake(10, 29, bubbleView.frame.size.width-20, 36 + 9)];
        lblMessage.textColor = [self.view colorWithHexString:@"#777777" alpha:1];
        lblMessage.font = [UIFont fontWithName:FONT_NAME_Regular size:10];
        lblMessage.numberOfLines = 3;
        lblMessage.text = NSLocalizedString(@"We recommend learning initials and finals before syllables.", @"");
        lblMessage.textAlignment = NSTextAlignmentCenter;
  
        if(IS_OVERSEAS_VERSION){
            [_headerView addSubview:self.bubbleView];
            [bubbleView addSubview:lblMessage];
        }
    }
    return _headerView;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
   if (cell == nil){
       cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
   }
   return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 0;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN; // 比 0.1 更小的值
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}
/*
#pragma mark - Navigation
 
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)getPinyinCategory{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:@"/pinyin/getPinyinCategory" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        //NSLog(@"--------[%@]-----[%d],,,,[%@]",response.data,response.code,response.msg);
        if (success) {

            NSArray *newArray = [NSArray arrayWithArray:response.data];
            if ([DataCacheManager hasDataChanged:newArray forClass:[self class]]) {
                 self.dataArray = [newArray mutableCopy];
                if(self.dataArray.count == 0) return;
                [self setCell:self.dataArray];
                self.bubbleView.hidden = NO;
             }
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
    

}


@end
