//
//  DeleteAccountViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/26.
//

#import "DeleteAccountViewController.h"
#import "DeleteEmailViewController.h"
@interface DeleteAccountViewController ()<UIGestureRecognizerDelegate,UINavigationControllerDelegate>
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UIButton *btnNext;

@end

@implementation DeleteAccountViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [self.view colorWithHexString:@"#FFFFFF" alpha:1];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.delegate = self;
    [self addGlobalBackButton];
    
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(80, statusBarH, SCREEN_WIDTH - 160, navigationBarHeight)];
    lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
    lblTitle.textColor = BLACK_COLOR_1F;
    lblTitle.textAlignment = NSTextAlignmentCenter;
    lblTitle.text = NSLocalizedString(@"Delete Account1",@"");
    [self.view addSubview:lblTitle];

    
    UIButton *btnNext = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.btnNext = btnNext;
    self.btnNext.frame = CGRectMake(26, self.headerView.frame.origin.y + self.headerView.frame.size.height, SCREEN_WIDTH - 52, 56);
    btnNext.layer.cornerRadius = 28;//圆角
    btnNext.layer.masksToBounds = YES;
    btnNext.titleEdgeInsets = UIEdgeInsetsMake(0,-20, 0, 0);
    btnNext.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
    [btnNext setTintColor:[UIColor blackColor]];//标题图片button
    [btnNext setTitle:NSLocalizedString(@"Next step",@"") forState:UIControlStateNormal];
    btnNext.layer.borderWidth = 1;//边框
    btnNext.layer.borderColor = [UIColor blackColor].CGColor;
    [btnNext addTarget:self action:@selector(btnNextAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnNext];
    [self.view addSubview:self.headerView];
    //UIImageView *imgArrow = [[UIImageView alloc]initWithFrame:CGRectMake(btnNext.frame.size.width/2 + 50, (56-28)/2 + 2,28, 28)];
    //imgArrow.image = [UIImage imageNamed:@"next_black"];
    //[btnNext addSubview:imgArrow];

    //self.imgArrow = [[UIImageView alloc]initWithFrame:CGRectMake(100-15, 0, 15, 15)];
    //[_btnPracticeAll addSubview:self.imgArrow];
    UIImage *arrowImage = [UIImage imageNamed:@"next_black"];
    [btnNext setImage:arrowImage forState:UIControlStateNormal];
    
    btnNext.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    btnNext.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    btnNext.titleEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
    btnNext.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -2);
    btnNext.adjustsImageWhenHighlighted = NO;
 
}
- (void)btnNextAction:(UIButton *)sender {
    DeleteEmailViewController *vc = [DeleteEmailViewController new];
    vc.strEmail = self.strEmail;
    [self.navigationController pushViewController:vc animated:YES];
}
- (UIView *)headerView {
    if (!_headerView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, statusBarH + navigationBarHeight, SCREEN_WIDTH, 400)];//410
  
        UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(26, 45, SCREEN_WIDTH - 2 * Distance＿M, 20)];
        lblTitle.textColor = BLACK_COLOR_1F;
        lblTitle.text = NSLocalizedString(@"Delete Account Notice",@"");
        lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
        [self.headerView addSubview:lblTitle];

        if(IS_OVERSEAS_VERSION){
            for (int i = 0; i < 4; i++) {
                UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(26, lblTitle.frame.origin.y + lblTitle.frame.size.height + 65 * i + 30, 6, 6)];
                imgView.image = [UIImage imageNamed:@"Rectangle_blue"];
                [self.headerView addSubview:imgView];
                
                UILabel *lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(44, lblTitle.frame.origin.y + lblTitle.frame.size.height + 65 * i + 20, SCREEN_WIDTH - 74, 50)];
                lblSubtitle.textColor = [self.view colorWithHexString:@"#1F1F39" alpha:1];
                lblSubtitle.textAlignment = NSTextAlignmentLeft;
                lblSubtitle.numberOfLines = 2;
                NSString *title = @[@"Deleting your account is permanent and irreversibl",@"All of your learning progress will be permanently removed",@"Once deleted, your account and data cannot be recovered",@"If you wish to use the app again, you will need to sign up for a new account."][i];
                title = NSLocalizedString(title,@"");
                lblSubtitle.text = title;
                lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
                [self.headerView addSubview:lblSubtitle];
            }
            
            self.headerView.frame = CGRectMake(0, statusBarH + navigationBarHeight, SCREEN_WIDTH, lblTitle.frame.origin.y + lblTitle.frame.size.height + 65 * 4 + 30 + 20);
        } else {
            for (int i = 0; i < 3; i++) {
                UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(lblTitle.frame.origin.x, lblTitle.frame.origin.y + lblTitle.frame.size.height + 20 * i + 85 + 4.5, 6, 6)];
                imgView.image = [UIImage imageNamed:@"Rectangle_blue"];
                [self.headerView addSubview:imgView];
                
                UILabel *lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(44, lblTitle.frame.origin.y + lblTitle.frame.size.height + 20 * i + 85, SCREEN_WIDTH - 74, 15)];
                lblSubtitle.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
                NSString *title = @[@"账户基本信息（昵称、绑定手机号等）",@"全部学习进度与课程记录",@"其他与该账户相关的所有数据"][i];
                title = NSLocalizedString(title,@"");
                lblSubtitle.text = title;
                lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
                [self.headerView addSubview:lblSubtitle];
            }
            for (int i = 0; i < 2; i++) {
                UILabel *lblTips = [[UILabel alloc]initWithFrame:CGRectMake(lblTitle.frame.origin.x, lblTitle.frame.origin.y + lblTitle.frame.size.height + 140 * i + 20, SCREEN_WIDTH - 52, 40)];
                lblTips.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
                lblTips.numberOfLines = 2;
                NSString *title1 = @[@"账号注销后将无法恢复， \n且以下所有数据将被永久删除，请谨慎操作：",@"注销后如需继续使用本应用，需重新注册新账号。"][i];
                title1 = NSLocalizedString(title1,@"");
                lblTips.text = title1;
                lblTips.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
                [self.headerView addSubview:lblTips];
                lblTips.tag = 200 + i;
            }
            self.headerView.frame = CGRectMake(0, statusBarH + navigationBarHeight, SCREEN_WIDTH, lblTitle.frame.origin.y + lblTitle.frame.size.height + + 140 * 2 + 20 + 20);
        }
        
        UILabel *lblTips = (UILabel *)[self.headerView viewWithTag:201];
        CGSize labelSize = [lblTips sizeThatFits:CGSizeMake(SCREEN_WIDTH - 52,MAXFLOAT)];
        lblTips.frame = CGRectMake(lblTitle.frame.origin.x, lblTitle.frame.origin.y + lblTitle.frame.size.height + 140 * 1 + 20, SCREEN_WIDTH - 52, labelSize.height + 3);
        self.btnNext.frame = CGRectMake(26, self.headerView.frame.origin.y + self.headerView.frame.size.height, SCREEN_WIDTH - 52, 56);
    }
    return _headerView;
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
