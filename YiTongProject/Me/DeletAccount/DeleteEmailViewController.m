//
//  DeleteEmailViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/26.
//

#import "DeleteEmailViewController.h"
#import "CountDownButton.h"
#import "EmailValidator.h"
//#import "AccountDeletionView.h"
@interface DeleteEmailViewController ()<UIGestureRecognizerDelegate,UINavigationControllerDelegate,UITextFieldDelegate>
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UIButton *btnConfirm;
@property (strong, nonatomic) CountDownButton *btnSendCode;
@property (strong, nonatomic) UIView *codeView;

@property (strong, nonatomic) UITextField *txtEmail;
@property (strong, nonatomic) UITextField *txtCode;
@end

@implementation DeleteEmailViewController
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
    [self.view addSubview:self.headerView];
    [self.view addSubview:self.btnConfirm];
}
- (UIView *)headerView {
    if (!_headerView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, statusBarH + navigationBarHeight, SCREEN_WIDTH, 380)];//410
        
        UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(26, 45, SCREEN_WIDTH - 2 * 26, 25)];
        lblTitle.textColor = BLACK_COLOR_1F;
        lblTitle.text = NSLocalizedString(@"Verify Your Email",@"");
        lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
        [self.headerView addSubview:lblTitle];
        
        UILabel *lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(26, lblTitle.frame.origin.y + lblTitle.frame.size.height  + 6, SCREEN_WIDTH - 2 * 26, 50)];
        lblSubtitle.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
        lblSubtitle.textAlignment = NSTextAlignmentLeft;
        lblSubtitle.text = NSLocalizedString(@"Please confirm your email to continue",@"");
        lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        [self.headerView addSubview:lblSubtitle];
        
        for (int i = 0; i < 2; i ++) {
            UIView *grayView = [[UIView alloc]initWithFrame:CGRectMake(Distance＿X, lblSubtitle.frame.origin.y + lblSubtitle.frame.size.height + 52 + 80 * i , SCREEN_WIDTH - 2 * Distance＿X, 48)];
            [grayView.layer setBorderWidth:1];//边框
            grayView.layer.borderColor = [self.view colorWithHexString:@"#DADCE5" alpha:1].CGColor;
            grayView.layer.cornerRadius = 8;
            grayView.tag = 50 + i;
            [self.headerView addSubview:grayView];
            
            UITextField *txtField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, grayView.frame.size.width, grayView.frame.size.height)];
            txtField.delegate = self;
            txtField.tag = 200 + i;
            txtField.tintColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
            txtField.tintColor = [self.view colorWithHexString:@"#4C9BEF" alpha:1];
            txtField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0,0,15,0)];
            txtField.leftViewMode= UITextFieldViewModeAlways;
            txtField.textColor = [self.view colorWithHexString:@"#212121" alpha:1];
            txtField.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
            txtField.placeholder = @[@"",NSLocalizedString(@"Enter The Verification Code",@"")][i];
            [grayView addSubview:txtField];
            if(i==1){
                txtField.frame = CGRectMake(0, 0, grayView.frame.size.width - 106, grayView.frame.size.height);
            }
        }
        self.codeView = (UIView *)[self.headerView viewWithTag:51];
        self.txtEmail = (UITextField *)[self.headerView viewWithTag:200];
        self.txtCode = (UITextField *)[self.headerView viewWithTag:201];
        self.txtCode.keyboardType = UIKeyboardTypeNumberPad;
        [self.codeView addSubview:self.btnSendCode];
        
        [self.txtEmail addTarget:self action:@selector(textFieldEmailDidChange:) forControlEvents:UIControlEventEditingChanged];
        [self.txtCode addTarget:self action:@selector(textFieldCodeDidChange:) forControlEvents:UIControlEventEditingChanged];

        self.txtEmail.userInteractionEnabled = IS_OVERSEAS_VERSION;
        if(self.strEmail.length<=6){
            [self getUserHomeInfo];
        } else {
            self.txtEmail.text = self.strEmail;
            [self textFieldEmailDidChange:self.txtEmail];  
        }

    }
    return _headerView;
}
- (void)textFieldCodeDidChange:(UITextField *)textField {
    if(textField.text.length > 5 ){
        self.btnConfirm.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1]; //#3A89D8
        self.btnConfirm.userInteractionEnabled = YES;
    } else {
        self.btnConfirm.userInteractionEnabled = NO;
        self.btnConfirm.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1]; //
    }
}
- (void)textFieldEmailDidChange:(UITextField *)textField {
    
    if([EmailValidator isValidEmail:textField.text] || [PublicTool isValidPhone:self.txtEmail.text]){
        self.btnSendCode.userInteractionEnabled = YES;
        self.btnSendCode.titleLabel.tintColor = Main_COLOR;
        self.btnSendCode.countdownLabel.textColor = Main_COLOR;
    } else {
        self.btnSendCode.titleLabel.tintColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
        self.btnSendCode.countdownLabel.textColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
        self.btnSendCode.userInteractionEnabled = NO;
    }
}
- (UIButton *)btnConfirm {
    if(!_btnConfirm){
        _btnConfirm = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnConfirm.frame = CGRectMake(26, self.headerView.frame.origin.y + self.headerView.frame.size.height + 10 , SCREEN_WIDTH - 2 * 26, 56);
        _btnConfirm.layer.cornerRadius = 56/2;//圆角
        _btnConfirm.layer.masksToBounds = YES;
        _btnConfirm.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:18];
        [_btnConfirm setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_btnConfirm addTarget:self action:@selector(btnConfirmAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnConfirm setTitle:NSLocalizedString(@"Confirm and Continue",@"") forState:UIControlStateNormal];
        _btnConfirm.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1]; //#3A89D8
        _btnConfirm.titleLabel.textColor = [UIColor whiteColor];
    }
    return _btnConfirm;
}
-(void)btnConfirmAction:(UIButton *)sender {
    [self.txtCode resignFirstResponder];//键盘回收
    
    if(self.txtCode.text.length > 5){
        NSArray *titleArray = @[@"Account Deletion",@"Delete your YTong account? This action is permanent and cannot be undone.",@"Cancel",@"Delete Account"];
        [ReadyLogOutView showViewTitle:@"" buttonArrayTitle:titleArray callBack:^(NSInteger index) {
            if(index == 1000){//左取消 右边 删除
                NSLog(@"-取消--");
            } else {
                [self confirmDeleteUser];
            }
        }];
    } else {
       NSString *str = NSLocalizedString(@"Enter The Verification Code", @"");
        [MBProgressHUD showLabel:str];
    }
    
}
- (void)confirmDeleteUser {
    
    self.btnConfirm.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnConfirm.userInteractionEnabled = YES;
        });
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if(IS_OVERSEAS_VERSION){
        if(![EmailValidator isValidEmail:self.txtEmail.text]){
            return;
        }
        params[@"email"] = self.txtEmail.text;
        params[@"captcha"] = self.txtCode.text;
    } else {
        if(![PublicTool isValidPhone:self.txtEmail.text]){
            return;
        }
        
        params[@"mobile"] = self.txtEmail.text;
        params[@"captcha"] = self.txtCode.text;
    }
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:@[@"/authCn/deleteUser",@"/auth/deleteUser"][IS_OVERSEAS_VERSION] parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {

        [MBProgressHUD showLabel:response.msg];
        if (success) {
            [PublicTool markAsDeleteUserRegistered];
            [[UserModel sharedInstance] logout];
            self.tabBarController.selectedIndex =0;

            if(IS_OVERSEAS_VERSION){
                LoginViewController *loginVC = [LoginViewController new];
                UINavigationController *loginNC = [[UINavigationController alloc]initWithRootViewController:loginVC];
                loginNC.modalPresentationStyle = 0;
                [self.navigationController popToRootViewControllerAnimated:YES];
                [self.navigationController presentViewController:loginNC animated:YES completion:^{}];
            } else {
                
                PhoneLoginViewController *loginVC = [[PhoneLoginViewController alloc] init];
                UINavigationController *loginNC = [[UINavigationController alloc]initWithRootViewController:loginVC];
                loginNC.modalPresentationStyle = 0;
                [self.navigationController popToRootViewControllerAnimated:YES];
                [self.navigationController presentViewController:loginNC animated:YES completion:^{}];
            }
            //用户注销
            [[AnalyticsManager shared] trackEvent:EventTypeCancel event_name:@"注销" params:nil];
            [[SilentReceiptSyncManager sharedManager] reset];
            //
        }
    
    } failure:^(NSError * _Nonnull error) {
        [MBProgressHUD showLabel:error.localizedDescription];//error错误
    }];
}
//点击空白回收键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    [self.headerView endEditing:YES];
}
- (CountDownButton *)btnSendCode {
    if(!_btnSendCode){
        _btnSendCode = [CountDownButton buttonWithType:UIButtonTypeRoundedRect];
        _btnSendCode.frame = CGRectMake(self.codeView.frame.size.width - 105 - 3, 0, 105, self.codeView.frame.size.height);
        [_btnSendCode addTarget:self action:@selector(btnSendCodeAction:) forControlEvents:UIControlEventTouchUpInside];

        _btnSendCode.countDownTime = 60; // 设置倒计时时间（可选）
        UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0, 8, 1, 32)];
        line.backgroundColor = [self.view colorWithHexString:@"#DADCE5" alpha:1];
        [_btnSendCode addSubview:line];
    }
    return _btnSendCode;
}
- (void)btnSendCodeAction:(UIButton *)sender {
    
    self.btnSendCode.userInteractionEnabled = NO;
    self.btnSendCode.countdownLabel.textColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnSendCode.userInteractionEnabled = YES;
        self.btnSendCode.countdownLabel.textColor = Main_COLOR;
        });
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"scene"] = @"cancel";
    if(IS_OVERSEAS_VERSION){
        if(![EmailValidator isValidEmail:self.txtEmail.text]){
            return;
        }
        params[@"email"] = self.txtEmail.text;
    } else {
        if(![PublicTool isValidPhone:self.txtEmail.text]){
            return;
        }
        params[@"mobile"] = self.txtEmail.text;
    }
    //场景（'register'：注册, 'login'：登录, 'reset'：重置密码）
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequestUsers:@[@"/captcha/sendSms",@"/captcha/send"][IS_OVERSEAS_VERSION] parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        //self.lblTips.text = @"";
        if (success) {
            [self.btnSendCode startCountDown];
            [MBProgressHUD showLabel:response.msg];
            self.btnSendCode.titleLabel.tintColor = [self.view colorWithHexString:@"#A4CAF1" alpha:1];
            self.btnSendCode.userInteractionEnabled = NO;
        } else {
            [self.btnSendCode stopCountDown];
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)getUserHomeInfo{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    //params[@"lang"] = [LanguageHelper currentLanguage];//@[@"cn",@"en"][IS_OVERSEAS_VERSION];
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:@"/user/getUserHomeInfo" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        //[self getBanner];
         if (success) {
             
             NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
             //self.strEmail = [NSString stringWithFormat:@"%@",dic[@"email"]];
             self.strEmail = @[[NSString stringWithFormat:@"%@",dic[@"mobile"]],[NSString stringWithFormat:@"%@",dic[@"email"]]][IS_OVERSEAS_VERSION];
             self.txtEmail.text = self.strEmail;
             [self textFieldEmailDidChange:self.txtEmail];
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
 
    } failure:^(NSError * _Nonnull error) {
    }];
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
