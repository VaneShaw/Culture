//
//  LoginViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//
#import <Network/Network.h>  
#import "LoginViewController.h"
#import "LoginFirstView.h"
#import "EmailValidator.h"
#import "CountDownButton.h"
#import "ForgotPasswordViewController.h"
#import "HelpRulesViewController.h"
#import "MessageView.h"
#import "ReceiptSyncManager.h"

@interface LoginViewController ()<UITextFieldDelegate,UITextViewDelegate>
@property (strong, nonatomic) UIImageView *imgAvatar;
@property (strong, nonatomic) UIButton *btnReturnOld;
@property (strong, nonatomic) UIButton *btnReturn;

@property (strong, nonatomic) UIButton *btnStart;
@property (strong, nonatomic) UIButton *btnRegisterEmail;
@property (strong, nonatomic) UIButton *btnSinIn;
@property (strong, nonatomic) UIView *line;
@property (strong, nonatomic) UIButton *btnCode;
@property (strong, nonatomic) UIButton *btnPassword;

@property (strong, nonatomic) UIView *useEmailView;
@property (strong, nonatomic) UIView *usePasswordView;
@property (strong, nonatomic) UILabel *lblTips;
@property (strong, nonatomic) UILabel *lblTips2;
@property (strong, nonatomic) UITextField *txtEmailAddress;
@property (strong, nonatomic) UITextField *txtPassword;
@property (strong, nonatomic) UITextField *txtEmailCode;
@property (strong, nonatomic) UITextField *txtCode;

@property (strong, nonatomic) UIButton *btnHiddenText;//隐藏小眼睛。左边有 右边没有
@property (strong, nonatomic) CountDownButton *btnSendCode;
@property (strong, nonatomic) UIButton *btnForgotPassword;

//@property (strong, nonatomic) UIButton *btnReading;
//@property (strong, nonatomic) NSString *assets_Box;
//@property (assign, nonatomic) BOOL isSelect;
@property (assign, nonatomic) BOOL isEmailAddress;    //邮箱地址是否已填
@property (assign, nonatomic) BOOL isEmailCode;      //邮箱验证码是否已填
@property (assign, nonatomic) BOOL isRegisterCode;//判断注册页的验证码 是否有输入

@property (strong, nonatomic) UITextView *txtAgreement;
@property (strong, nonatomic) UILabel *lblTipsAccount;
@property (strong, nonatomic) UILabel *lblTipsCode;
@property (strong, nonatomic) UIView *mainView;
@property (strong, nonatomic) LoginFirstView *firstView;
@property (strong, nonatomic) AgreementConsentView *agreeView;
@end

@implementation LoginViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    //UserModel *model = [UserModelData sharedUserModelData].currentUserModel;
   
    //if (model) {
    if([KUSER_DEFAULT objectForKey:@"account_key"]){
        self.txtEmailAddress.text = [KUSER_DEFAULT objectForKey:@"account_key"];
        self.txtEmailCode.text = [KUSER_DEFAULT objectForKey:@"account_key"];
        [self textFieldEmailAddressDidChange:self.txtEmailAddress];
        [self textFieldDidChange:self.txtEmailCode];
    }
}
- (void)viewDidDisappear:(BOOL)animated{
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [[KeyboardAvoidingManager sharedManager] registerView:self.view containerView:self.view];
    [[KeyboardAvoidingManager sharedManager] setPadding:150];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    [KUSER_DEFAULT setBool:NO forKey:@"is_select_key"];

    self.isEmailAddress = NO;
    self.isEmailCode = NO;
    self.isRegisterCode = NO;

    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIImage *backgroundImage = [UIImage imageNamed:@"launch_background"];
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    backgroundImageView.image = backgroundImage;
    
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    [self.view addSubview:self.mainView];
    [self.view addSubview:self.firstView];
    
    [self.mainView addSubview:self.imgAvatar];
    [self.mainView addSubview:self.btnPassword];
    [self.mainView addSubview:self.btnCode];

    [self.mainView addSubview:self.btnForgotPassword];
    [self.view addSubview:self.btnStart];
    [self.view addSubview:self.btnRegisterEmail];
    [self.view addSubview:self.btnSinIn];
    //[self.view addSubview:self.btnReturn];
    [self.view addSubview:self.btnReturn];//上架必备
    
    for (int i = 0; i < 2; i ++) {
        UIView *grayView = [[UIView alloc]initWithFrame:CGRectMake(Distance＿X, self.btnPassword.frame.origin.y + self.btnPassword.frame.size.height + 42 + 76 * i , SCREEN_WIDTH - 2 * Distance＿X, 48)];
        [grayView.layer setBorderWidth:1];//边框
        grayView.layer.borderColor = [self.view colorWithHexString:@"#DADCE5" alpha:1].CGColor;
        grayView.layer.cornerRadius = 8;
        grayView.tag = 50 + i;
        [self.mainView addSubview:grayView];
        
        //改动x353
        UITextField *txtField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, grayView.frame.size.width-35, grayView.frame.size.height)];
        txtField.delegate = self;
        txtField.tag = 200 + i;
        txtField.tintColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
        txtField.tintColor = [self.view colorWithHexString:@"#4C9BEF" alpha:1];
        txtField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0,0,15,0)];
        txtField.leftViewMode= UITextFieldViewModeAlways;
        txtField.textColor = [self.view colorWithHexString:@"#212121" alpha:1];
        txtField.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        [grayView addSubview:txtField];
        
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿X + 5, grayView.frame.origin.y + 52,SCREEN_WIDTH - 2 *Distance＿X, 14)];
        label.font = [UIFont fontWithName:FONT_NAME_Regular size:10];
        label.textColor = [self.view colorWithHexString:@"#EF5350" alpha:1];
        label.tag = 60 + i;
        //label.text = @"Incorrect password. Please try again";
        [self.mainView addSubview:label];
    }

    self.useEmailView = (UIView *)[self.view viewWithTag:50];
    self.usePasswordView = (UIView *)[self.view viewWithTag:51];
    self.lblTips = (UILabel *)[self.mainView viewWithTag:60];
    self.lblTips2 = (UILabel *)[self.mainView viewWithTag:61];
    
    for (int i = 0; i < 2; i ++) {
        UITextField *txtField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, self.usePasswordView.frame.size.width-25, self.usePasswordView.frame.size.height)];
        txtField.delegate = self;
        txtField.tag = 202 + i;
        txtField.tintColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
        txtField.tintColor = [self.view colorWithHexString:@"#4C9BEF" alpha:1];
        txtField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0,0,10,0)];
        txtField.leftViewMode= UITextFieldViewModeAlways;
        txtField.textColor = [self.view colorWithHexString:@"#212121" alpha:1];
        txtField.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        if(i == 0){
            [self.useEmailView addSubview:txtField];
        } else {
            [self.usePasswordView addSubview:txtField];
        }
    }
    self.txtEmailAddress = (UITextField *)[self.useEmailView viewWithTag:200];
    self.txtPassword = (UITextField *)[self.usePasswordView viewWithTag:201];
    self.txtEmailCode = (UITextField *)[self.useEmailView viewWithTag:202];
    self.txtCode = (UITextField *)[self.usePasswordView viewWithTag:203];
    self.txtCode.frame = CGRectMake(0, 0, self.usePasswordView.frame.size.width-105, self.usePasswordView.frame.size.height);
 
    [self.txtEmailAddress addTarget:self action:@selector(textFieldEmailAddressDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.txtEmailCode addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.txtPassword addTarget:self action:@selector(textFieldtxtPasswordDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.txtCode addTarget:self action:@selector(textFieldtxtCodeDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    self.txtPassword.secureTextEntry = YES;
    self.txtPassword.keyboardType = UIKeyboardTypeDefault;
    self.txtCode.keyboardType = UIKeyboardTypeNumberPad;
    [self.usePasswordView addSubview:self.btnHiddenText];
    [self.usePasswordView addSubview:self.btnSendCode];
    self.txtPassword.secureTextEntry = YES;
    
    //[self.view addSubview:self.btnReading];
    [self.view addSubview:self.txtAgreement];
    [self btnPasswordAction:self.btnPassword];
    self.mainView.hidden = ![PublicTool hasRegistered];
    self.firstView.hidden = [PublicTool hasRegistered];

    self.btnSinIn.hidden = self.firstView.hidden;
    self.btnRegisterEmail.hidden = !self.btnSinIn.hidden;
    
    if([KUSER_DEFAULT objectForKey:@"account_key"]){
        self.txtEmailAddress.text = [KUSER_DEFAULT objectForKey:@"account_key"];
    }
    for (int i = 0; i < 4; i ++) {
        UITextField *txtField = (UITextField *)[self.view viewWithTag:200 + i];
        NSString *str = @[@"please Enter Your Email Address",@"Confirm Password",@"Enter your email",@"Enter The Verification Code"][i];
        str = NSLocalizedString(str,@"");
        UIColor *color = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
        txtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:str  attributes:@{NSForegroundColorAttributeName: color}];
    }
    
    [self addAgreemenView];
    if(![PublicTool triggerStatus]){
        [self startNetworkMonitor];
    }
 

}


- (void)startNetworkMonitor {
    if (@available(iOS 12.0, *)) {
        nw_path_monitor_t monitor = nw_path_monitor_create();
        nw_path_monitor_set_queue(monitor, dispatch_get_main_queue());
        nw_path_monitor_set_update_handler(monitor, ^(nw_path_t path) {
            if (nw_path_get_status(path) == nw_path_status_satisfied) {
                NSLog(@"网络可用 ✅");
                //[self loadNewMessage];// 用户允许后再触发请求
            } else {
                NSLog(@"网络不可用 ❌");
            }
        });
        nw_path_monitor_start(monitor);
    }
}

- (void)addAgreemenView {
    NSURL *url = [NSURL URLWithString:@""];
    AgreementConsentView *agree = [[AgreementConsentView alloc] initWithAgreementURL:url privacyURL:url];
    agree.translatesAutoresizingMaskIntoConstraints = NO;
    // 初始是否勾选
    agree.checked = NO;
    self.agreeView = agree;
    // 回调：勾选/取消
    __weak typeof(self) weakSelf = self;
    agree.onToggle = ^(BOOL checked) {
        NSLog(@"checked? [%d]", checked);
        //checked 1 选中。  0 未打勾
        // 例如：设置注册按钮 enable
        //weakSelf.btnCode.enabled = checked;
        [KUSER_DEFAULT setBool:checked forKey:@"is_select_key"];
        if(checked){
            [self verifyBbuttonHighlighted];
        }
    };
    //BOOL isChecked = agree.isChecked;
    
    agree.onTapLinkName = ^(NSString *name) {
        HelpRulesViewController *rulesVC = [HelpRulesViewController new];
        if ([name isEqualToString:@"用户协议"]) {
            NSLog(@"点了用户协议");
            //rulesVC.title = @"《用户协议》";
            rulesVC.rule_type = @"agreement";
            rulesVC.title = NSLocalizedString(@"[Terms of Service]",@"");
        } else if ([name isEqualToString:@"隐私政策"]) {
            NSLog(@"点了隐私政策");
            //rulesVC.title = @"《隐私政策》";
            //rulesVC.title = NSLocalizedString(@"Privacy Policy",@"");
            rulesVC.title = NSLocalizedString(@"[Privacy Policy]",@"");
            rulesVC.rule_type = @"privacy";
        }
        [self.navigationController pushViewController:rulesVC animated:YES];
    };
    [self.view addSubview:agree];
    [NSLayoutConstraint activateConstraints:@[
        [agree.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [agree.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [agree.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-24]
    ]];
}
//这里 点击需要打勾
- (void)btnReadingAction {
    if(self.agreeView.isChecked){
        [self.agreeView markAsUnchecked];
    } else {
        [self.agreeView markAsChecked];
    }
}
- (void)textFieldtxtPasswordDidChange:(UITextField *)textField {
    [self verifyBbuttonHighlighted];
}
- (void)textFieldtxtCodeDidChange:(UITextField *)textField {
    [self verifyBbuttonHighlighted];
}
- (UIButton *)btnReturnOld {
    if(!_btnReturnOld){
        _btnReturnOld = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        _btnReturnOld.frame = CGRectMake(Distance＿X, 35 + statusBarH, 30,30);
        [_btnReturnOld addTarget:self action:@selector(btnReturnAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnReturnOld setImage:[UIImage imageNamed:@"return_black"] forState:UIControlStateNormal];
    }
    return _btnReturnOld;
}
- (UIButton *)btnReturn {
    if(!_btnReturn){
        _btnReturn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        _btnReturn.frame = CGRectMake(Distance＿X-5, 35 + statusBarH-15 - 20, 40,60);
        [_btnReturn addTarget:self action:@selector(btnReturnAction22:) forControlEvents:UIControlEventTouchUpInside];
        UIImageView *close = [UIImageView new];
        close.frame = CGRectMake(5, 5 + 20, 20, 20);
        close.image = [UIImage imageNamed:@"close_black"];
        [_btnReturn addSubview:close];
  
    }
    return _btnReturn;
}
//登录页
- (void)btnReturnAction22:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//登录页
- (void)btnReturnAction:(UIButton *)sender {
    self.mainView.hidden = NO;
    self.firstView.hidden = YES;

    self.btnSinIn.hidden = self.firstView.hidden;
    self.btnRegisterEmail.hidden = !self.btnSinIn.hidden;
    self.lblTips.text = @"";
    self.lblTips2.text = @"";
    [self verifyBbuttonHighlighted];

}
//注册页
- (void)btnRegisterEmailAction:(UIButton *)sender {
    for (int i = 0; i < 4; i ++) {
        UILabel *lblTips = (UILabel *)[self.firstView viewWithTag:60 + i];
        lblTips.text = @"";
    }
    
    self.mainView.hidden = YES;
    self.firstView.hidden = NO;
  
    self.btnSinIn.hidden = self.firstView.hidden;
    self.btnRegisterEmail.hidden = !self.btnSinIn.hidden;
    [self verifyBbuttonHighlighted];
}
//登录页 -pasword -左
- (void)btnPasswordAction:(UIButton *)sender {
    
    [self.btnPassword setTitleColor:Main_COLOR forState:UIControlStateNormal];
    [self.btnCode setTitleColor:Gray_COLOR forState:UIControlStateNormal];
    [UIView animateWithDuration:0.2 animations:^{
        self.line.frame = CGRectMake(self.imgAvatar.frame.origin.x + self.btnPassword.frame.size.width/4, self.btnPassword.frame.origin.y + 25 ,self.btnPassword.frame.size.width/2, LINE_WIDTH);
    }];
    self.btnHiddenText.hidden = NO;
    self.btnForgotPassword.hidden = NO;
    self.txtEmailAddress.hidden = NO;
    self.txtPassword.hidden = NO;
    
    self.txtEmailCode.hidden = YES;
    self.txtCode.hidden = YES;
    self.btnSendCode.hidden = YES;
    self.lblTips.text = @"";
    self.lblTips2.text = @"";
    [self verifyBbuttonHighlighted];
}
//登录页 -pasword -右
- (void)btnCodeAction:(UIButton *)sender {
    [self.btnPassword setTitleColor:Gray_COLOR forState:UIControlStateNormal];
    [self.btnCode setTitleColor:Main_COLOR forState:UIControlStateNormal];
    [UIView animateWithDuration:0.2 animations:^{
        self.line.frame = CGRectMake(self.imgAvatar.frame.origin.x + self.btnCode.frame.size.width/4 + self.btnPassword.frame.size.width + 5, self.btnCode.frame.origin.y + 25,self.btnCode.frame.size.width/2, LINE_WIDTH);
    }];
    self.btnHiddenText.hidden = YES;
    self.btnForgotPassword.hidden = YES;
    self.txtEmailAddress.hidden = YES;
    self.txtPassword.hidden = YES;
    
    self.txtEmailCode.hidden = NO;
    self.txtCode.hidden = NO;
    self.btnSendCode.hidden = NO;
    self.lblTips.text = @"";
    self.lblTips2.text = @"";
    [self verifyBbuttonHighlighted];
}
- (LoginFirstView *)firstView {
    if(!_firstView){
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        int temp = SCREEN_WIDTH < 390? 50 : 0;
        _firstView = [[LoginFirstView alloc]initWithFrame:CGRectMake(0, 111 + statusBarH - 20 - temp, SCREEN_WIDTH, 420 + 5 + 5)];
        _firstView.backgroundColor = [UIColor clearColor];
        _firstView.clipsToBounds = YES;
        _firstView.lblHello.text = NSLocalizedString(@"Hello, welcome to YTong！",@"");
        _firstView.isRegister = YES;// 当前在注册页，反之 忘记密码页
        //_firstView.lblTitle.text = @"Ready for 汉字? Just enter the code.";

        
        [_firstView setSelectedTypeIndex:^(NSInteger index) {
            if(index > 0){
                self.isRegisterCode = YES;
            } else {
                self.isRegisterCode = NO;
            }
            [self verifyBbuttonHighlighted];
        }];
        [_firstView setSelectedReadTypeIndex:^(NSInteger index) {
            if(index == 101){
                //[self btnReadingAction:self.btnReading];//等待处理
                [self btnReadingAction];
            }
        }];
        
        for (int i = 0; i < 4; i ++) {
            UITextField *txtField = (UITextField *)[self.firstView viewWithTag:100 + i];
            NSString *str = @[@"Enter your email",@"Create a password (6+ chars)",@"Confirm your password",@"Enter The Verification Code"][i];
            str = NSLocalizedString(str,@"");
            UIColor *color = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
            txtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:str  attributes:@{NSForegroundColorAttributeName:color}];
        }
    }
    return _firstView;
}
- (UIView *)mainView {
    if(!_mainView){
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        int temp = SCREEN_WIDTH < 390? 70 : 0;
        _mainView = [[UIView alloc]initWithFrame:CGRectMake(0, 110 + statusBarH - temp, SCREEN_WIDTH, 420)];
        _mainView.backgroundColor = [UIColor clearColor];
        _mainView.clipsToBounds = YES;
    }
    return _mainView;
}
- (UIImageView *)imgAvatar {
    if(!_imgAvatar){
        int width = 54;//210
        _imgAvatar = [[UIImageView alloc]initWithFrame:CGRectMake(Distance＿X, 1, width, width )];
        _imgAvatar.layer.cornerRadius = 5;//圆角
        _imgAvatar.layer.masksToBounds = YES;
        _imgAvatar.image = [UIImage imageNamed:@"logo_blue"];

        UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿X, _imgAvatar.frame.origin.y + _imgAvatar.frame.size.height + 16, SCREEN_WIDTH - 2*Distance＿X , 20)];
        lblTitle.textColor = [UIColor blackColor];
        [self.mainView addSubview:lblTitle];
        lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:18];
        lblTitle.textAlignment = NSTextAlignmentLeft;
        lblTitle.text = NSLocalizedString(@"Continue your learning journey",@"");
    }
    return _imgAvatar;
}
- (UIButton *)btnPassword {
    if(!_btnPassword){
        _btnPassword = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnPassword.frame = CGRectMake(self.imgAvatar.frame.origin.x, self.imgAvatar.frame.origin.y + self.imgAvatar.frame.size.height + 100, 150, 25);
        [_btnPassword setTitleColor:Main_COLOR forState:UIControlStateNormal];
        _btnPassword.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:18];
        [_btnPassword addTarget:self action:@selector(btnPasswordAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnPassword setTitle:NSLocalizedString(@"Use Password",@"") forState:UIControlStateNormal];
        
        UIView *line = [[UIView alloc]init];
        line.layer.cornerRadius = LINE_WIDTH/2;
        line.layer.masksToBounds = YES;
        line.backgroundColor = Main_COLOR;
        self.line = line;
        self.line.frame = CGRectMake(self.imgAvatar.frame.origin.x + self.btnPassword.frame.size.width/4, self.btnPassword.frame.origin.y + 25 ,self.btnPassword.frame.size.width/2, LINE_WIDTH);
        [self.mainView addSubview:self.line];
    }
    return _btnPassword;
}
- (UIButton *)btnCode {
    if(!_btnCode){
        _btnCode = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnCode.frame = CGRectMake(self.btnPassword.frame.origin.x + self.btnPassword.frame.size.width+ 5, self.btnPassword.frame.origin.y, self.btnPassword.frame.size.width, 25);
        [_btnCode setTitleColor:Gray_COLOR forState:UIControlStateNormal];
        _btnCode.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:18];
        [_btnCode addTarget:self action:@selector(btnCodeAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnCode setTitle:NSLocalizedString(@"Use Code",@"") forState:UIControlStateNormal];
    }
    return _btnCode;
}
- (UIButton *)btnHiddenText {
    if(!_btnHiddenText){
        _btnHiddenText = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnHiddenText.frame = CGRectMake(self.usePasswordView.frame.size.width - 45 - 3, 0, 45, self.usePasswordView.frame.size.height);
        [_btnHiddenText addTarget:self action:@selector(btnHiddenAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnHiddenText setImage:[UIImage imageNamed:@"preview＿level"] forState:UIControlStateNormal];
    }
    return _btnHiddenText;
}
- (void)btnHiddenAction:(UIButton *)sender {
    self.txtPassword.secureTextEntry = !self.txtPassword.secureTextEntry;
    if(self.txtPassword.secureTextEntry){
        [self.btnHiddenText setImage:[UIImage imageNamed:@"preview＿level"] forState:UIControlStateNormal];
    } else {
        [self.btnHiddenText setImage:[UIImage imageNamed:@"preview＿open"] forState:UIControlStateNormal];
    }
}
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    NSString *strT = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    if(![string isEqualToString:strT]) {
        return NO;
    }
    return YES;
}
- (CountDownButton *)btnSendCode {
    if(!_btnSendCode){
        _btnSendCode = [CountDownButton buttonWithType:UIButtonTypeRoundedRect];
        _btnSendCode.frame = CGRectMake(self.usePasswordView.frame.size.width - 105 - 3, 0, 105, self.usePasswordView.frame.size.height);
        
        [_btnSendCode addTarget:self action:@selector(btnSendCodeAction:) forControlEvents:UIControlEventTouchUpInside];
        //_btnSendCode.tag = 31;
        _btnSendCode.countDownTime = 60; // 设置倒计时时间（可选）
        UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0, 8, 1, 32)];
        line.backgroundColor = [self.view colorWithHexString:@"#DADCE5" alpha:1];
        [_btnSendCode addSubview:line];
    }
    return _btnSendCode;
}

// 模拟发送验证码请求
- (void)sendVerificationCode {
    NSLog(@"发送验证码请求...");
    // 这里替换为实际的网络请求
    // 如果请求失败，可以手动停止倒计时：
    // [_countDownButton stopCountDown];
}

- (UIButton *)btnForgotPassword {
    if(!_btnForgotPassword){
        _btnForgotPassword = [UIButton buttonWithType:UIButtonTypeSystem];
        _btnForgotPassword.frame = CGRectMake(SCREEN_WIDTH - 25 - 108, self.btnPassword.frame.origin.y + 205, 108, 23);
        [_btnForgotPassword addTarget:self action:@selector(btnForgotPasswordAction:) forControlEvents:UIControlEventTouchUpInside];
        _btnForgotPassword.tintColor = [self.view colorWithHexString:@"#63A8F5" alpha:1];
        _btnForgotPassword.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:12];
        [_btnForgotPassword setTitle:NSLocalizedString(@"Forgot Password?",@"") forState:UIControlStateNormal];
        _btnForgotPassword.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_btnForgotPassword sizeToFit];
        
        CALayer *bottomLine = [CALayer layer];
        bottomLine.backgroundColor = Main_COLOR.CGColor; // 横线的颜色
        bottomLine.frame = CGRectMake(0.0f, _btnForgotPassword.bounds.size.height, _btnForgotPassword.bounds.size.width, 1.7f);
        [_btnForgotPassword.layer addSublayer:bottomLine];
    }
    return _btnForgotPassword;
}
- (void)btnForgotPasswordAction:(UIButton *)sender {
    ForgotPasswordViewController *forgotVC = [ForgotPasswordViewController new];
    [self.navigationController pushViewController:forgotVC animated:YES];
}
- (UIButton *)btnStart {
    if(!_btnStart){
        _btnStart = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnStart.frame = CGRectMake(Distance＿X, self.mainView.frame.origin.y + self.mainView.frame.size.height + 15, SCREEN_WIDTH - 2 * Distance＿X, 52);
        _btnStart.layer.cornerRadius = 8;//圆角
        _btnStart.layer.masksToBounds = YES;
        _btnStart.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:18];
        [_btnStart setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_btnStart addTarget:self action:@selector(btnStartAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnStart setTitle:NSLocalizedString(@"Start your journey now",@"") forState:UIControlStateNormal];
        _btnStart.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
        _btnStart.titleLabel.textColor = [UIColor whiteColor];
    }
    return _btnStart;
}

- (UIButton *)btnRegisterEmail {
    if(!_btnRegisterEmail){
        _btnRegisterEmail = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnRegisterEmail.frame = CGRectMake(Distance＿X, self.btnStart.frame.origin.y + self.btnStart.frame.size.height + 22, SCREEN_WIDTH - 2 * Distance＿X, 22);
        _btnRegisterEmail.titleLabel.font = [UIFont systemFontOfSize:14];
        [_btnRegisterEmail setTitleColor:[self.view colorWithHexString:@"#63A8F5" alpha:1] forState:UIControlStateNormal];
        [_btnRegisterEmail addTarget:self action:@selector(btnRegisterEmailAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnRegisterEmail setTitle:NSLocalizedString(@"Register With This Email",@"") forState:UIControlStateNormal];
    }
    return _btnRegisterEmail;
}

- (UIButton *)btnSinIn {
    if(!_btnSinIn){
        _btnSinIn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnSinIn.frame = CGRectMake(Distance＿X, self.btnStart.frame.origin.y + self.btnStart.frame.size.height + 22, SCREEN_WIDTH - 2 * Distance＿X, 22);
        _btnSinIn.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:14];
        [_btnSinIn setTitleColor:[self.view colorWithHexString:@"#63A8F5" alpha:1] forState:UIControlStateNormal];
        [_btnSinIn addTarget:self action:@selector(btnReturnAction:) forControlEvents:UIControlEventTouchUpInside];
        
        NSString *str1 = @"Already have an account?";
        NSString *str2 = @" Sign in";
        str1 = NSLocalizedString(str1,@"");
        str2 = NSLocalizedString(str2,@"");
        NSString *text = [NSString stringWithFormat:@"%@%@",str1,str2];
        [_btnSinIn setTitle:text forState:UIControlStateNormal];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:[self.view colorWithHexString:@"#63637D" alpha:1]
                                 range:[text rangeOfString:str1]];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:[self.view colorWithHexString:@"#63A8F5" alpha:1]
                                 range:[text rangeOfString:str2]];
        UIFont *font = [UIFont systemFontOfSize:13];
        [attributedString addAttribute:NSFontAttributeName
                                 value:font
                                 range:NSMakeRange(0, text.length)];
        // 将属性字符串设置为按钮标题
        [_btnSinIn setAttributedTitle:attributedString forState:UIControlStateNormal];
    }
    return _btnSinIn;
}
/*
- (UIButton *)btnReading {
    if(!_btnReading){
        _btnReading = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnReading.frame = CGRectMake(Distance＿X,SCREEN_HEIGHT - 70 - IPHONE_X * 24, 40, 40);
        [_btnReading addTarget:self action:@selector(btnReadingAction:) forControlEvents:UIControlEventTouchUpInside];
 
        self.assets_Box = @[@"not_selected",@"selected_2"][self.isSelect];
        UIImage *image = [UIImage imageNamed:self.assets_Box];
        [_btnReading setImage:image forState:UIControlStateNormal];
        _btnReading.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        //uibutton  怎么改变图片的大小
        _btnReading.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5); // 调整内容边距
        _btnReading.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5); // 调整图片边距
    }
    return _btnReading;
}
- (void)btnReadingAction:(UIButton *)sender {
    if (self.isSelect) {
        self.isSelect = NO;
        self.btnStart.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
        [KUSER_DEFAULT setBool:NO forKey:@"is_select_key"];
    } else {
        self.isSelect = YES;
        [self verifyBbuttonHighlighted];
        [KUSER_DEFAULT setBool:YES forKey:@"is_select"];
    }
    self.assets_Box = @[@"not_selected",@"selected_2"][self.isSelect];
    [sender setImage:[UIImage imageNamed:self.assets_Box] forState:UIControlStateNormal];
}*/
- (void)verifyBbuttonHighlighted {
    //@"#3A89D8" 深蓝        @"#7EBBFF"//浅色
    if(self.firstView.hidden){
        if(self.btnHiddenText.hidden){ //1code    0密码，
            if(self.isEmailCode && self.agreeView.isChecked && self.txtCode.text.length > 1){
                self.btnStart.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1];
            } else {
                self.btnStart.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
            }
        } else {
            if(self.isEmailAddress && self.agreeView.isChecked && self.txtPassword.text.length > 1){
                self.btnStart.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1];
            } else {
                self.btnStart.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
            }
        }
    } else {
        if(self.isRegisterCode && self.agreeView.isChecked){
            self.btnStart.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1];
        } else {
            self.btnStart.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
        }
    }
}
/*
- (UITextView *)txtAgreement {
    if(!_txtAgreement){
        _txtAgreement = [[UITextView alloc] initWithFrame:CGRectMake(self.btnReading.frame.origin.x + self.btnReading.frame.size.width + 2,self.btnReading.frame.origin.y, SCREEN_WIDTH - 100, 40)];
        _txtAgreement.editable = NO; // 禁止编辑
        _txtAgreement.delegate = self;
        _txtAgreement.backgroundColor = [UIColor clearColor];
        _txtAgreement.textColor = BLACK_COLOR;
        //_txtAgreement.font = [UIFont systemFontOfSize:12];
        _txtAgreement.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:14];
        // 2. 创建带可点击部分的 NSAttributedString
        NSString *fullText = @"By logging in, you agree to our [Terms of Service] And [Privacy Policy]";
        fullText = NSLocalizedString(fullText,@"");
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:fullText];
        
        // 3. 设置可点击部分的样式（蓝色 + 下划线）
        NSString *terms = NSLocalizedString(@"[Terms of Service]", @"");
        NSString *privacy = NSLocalizedString(@"[Privacy Policy]", @"");
        NSRange userAgreementRange = [fullText rangeOfString:terms];
        NSRange privacyPolicyRange = [fullText rangeOfString:privacy];
        [attributedString addAttribute:NSLinkAttributeName
                                 value:@"userAgreement://xxx"
                                 range:userAgreementRange];
        [attributedString addAttribute:NSLinkAttributeName
                                 value:@"privacyPolicy://xxx"
                                 range:privacyPolicyRange];
        // 4. 设置整体样式
        [attributedString addAttribute:NSFontAttributeName
                                 value:[UIFont systemFontOfSize:14]
                                 range:NSMakeRange(0, fullText.length)];
        
        // 5. 应用 NSAttributedString
        _txtAgreement.attributedText = attributedString;
        // 6. 调整 UITextView 的链接样式（可选）
        _txtAgreement.linkTextAttributes = @{
            NSForegroundColorAttributeName: Main_COLOR,
            NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)
        };
    }
    return _txtAgreement;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([URL.scheme isEqualToString:@"userAgreement"]) {
    
        HelpRulesViewController *rulesVC = [HelpRulesViewController new];
        //rulesVC.title = @"《用户协议》";
        rulesVC.title = NSLocalizedString(@"Terms of Service",@"");
        rulesVC.rule_type = @"agreement";
        [self.navigationController pushViewController:rulesVC animated:YES];
        // 跳转到用户协议页面
        return NO; // 阻止默认行为（如打开 Safari）
    } else if ([URL.scheme isEqualToString:@"privacyPolicy"]) {

        HelpRulesViewController *rulesVC = [HelpRulesViewController new];
        //rulesVC.title = @"《隐私政策》";
        rulesVC.title = NSLocalizedString(@"Privacy Policy",@"");
        rulesVC.rule_type = @"privacy";
        [self.navigationController pushViewController:rulesVC animated:YES];
        // 跳转到隐私政策页面
        return NO;
    }
    return YES;
}
*/
//点击空白回收键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
//检测UITextField是否输入点击状态
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    int tag = (int)textField.tag - 100;
    for (int i = 0; i < 2; i ++) {
        UIView *grayView = (UIView *)[self.view viewWithTag:50 + i ];
        if(i == tag){
            //grayView.layer.borderColor = [UIColor blueColor].CGColor;
        } else  {
            grayView.layer.borderColor = [self.view colorWithHexString:@"#DADCE5" alpha:1].CGColor;
        }
    }
}
- (void)textFieldEmailAddressDidChange:(UITextField *)textField {
    if([EmailValidator isValidEmail:textField.text]){
        self.isEmailAddress = YES;
    } else {
        self.isEmailAddress = NO;
    }
        [self verifyBbuttonHighlighted];
}
- (void)textFieldDidChange:(UITextField *)textField {

    if([EmailValidator isValidEmail:textField.text]){
        self.btnSendCode.userInteractionEnabled = YES;
        self.btnSendCode.titleLabel.tintColor = Main_COLOR;
        self.btnSendCode.countdownLabel.textColor = Main_COLOR;
        self.isEmailCode = YES;
    } else {
        self.isEmailCode = NO;
        self.btnSendCode.titleLabel.tintColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
        self.btnSendCode.countdownLabel.textColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
        self.btnSendCode.userInteractionEnabled = NO;
    }
    [self verifyBbuttonHighlighted];
}

-(void)checkInputLength:(NSString *)text{

}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
- (void)btnSendCodeAction:(UIButton *)sender {
    if (!self.agreeView.isChecked) {
        [MessageView showViewTitle:@"" buttonArrayTitle:@[] callBack:^(NSInteger index) {
            if(index == 101){
                //[self btnReadingAction:self.btnReading];//等待处理
                [self btnReadingAction];
            }
        }];
        //[MBProgressHUD showLabel:@"Please agree to the Terms and Privacy Policy"];
        [self.txtEmailCode resignFirstResponder];
        return;
    }
    
    self.lblTips.text = [EmailValidator isValidEmail:self.txtEmailCode.text] ? @"" : NSLocalizedString(@"Please enter a valid email address",@"");
    if(![EmailValidator isValidEmail:self.txtEmailCode.text]){
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"email"] = self.txtEmailCode.text;
    params[@"scene"] = @"login";
    
    self.btnSendCode.userInteractionEnabled = NO;
    self.btnSendCode.countdownLabel.textColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnSendCode.userInteractionEnabled = YES;
        self.btnSendCode.countdownLabel.textColor = Main_COLOR;
        });
    
    //场景（'register'：注册, 'login'：登录, 'reset'：重置密码）
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequestUsers:@"/captcha/send" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        //self.lblTips.text = @"";
        if (success) {
            [self.btnSendCode startCountDown];
            
            [MBProgressHUD showLabel:response.msg];
            self.btnSendCode.titleLabel.tintColor = [self.view colorWithHexString:@"#A4CAF1" alpha:1];
            self.btnSendCode.userInteractionEnabled = NO;
            
        } else {
            
            [self.btnSendCode stopCountDown];
            self.lblTips.text = (response.code == 1001) ? response.msg : @"";
            if(response.code == 1001){
            } else {
                [MBProgressHUD showLabel:response.msg];
            }
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}

- (void)btnStartAction:(UIButton *)sender {
    if (!self.agreeView.isChecked) {
        //[MBProgressHUD showLabel:@"Please agree to the Terms and Privacy Policy"];
        //[self.txtCode resignFirstResponder];
        [MessageView showViewTitle:@"" buttonArrayTitle:@[] callBack:^(NSInteger index) {
            if(index == 101){
                //[self btnReadingAction:self.btnReading];//等待处理
                [self btnReadingAction];
            }
        }];
        return;
    }
    //NSLog(@"-2----[%d]------isfirst----",[PublicTool isFirstLaunch]);
    if(!self.firstView.hidden){//初次登陆 注册
        [self btnRegistrationAction];
    } else {//老用户登录
        self.lblTips.text = @"";
        self.lblTips2.text = @"";
        if(self.btnHiddenText.hidden){ //1code    0密码，
            [self btnCodeLoginAction];//右
        } else {
            [self btnPasswordLoginAction];//左
        }
    }
    
    sender.userInteractionEnabled = NO;
    sender.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1];
        sender.userInteractionEnabled = YES;
        });

}
//========================================
- (void)btnRegistrationAction {
    
    NSString *str0 = NSLocalizedString(@"Please enter a valid email address",@"");
    NSString *str1 = NSLocalizedString(@"Password must be at least 6 characters",@"");
    NSString *str2 = NSLocalizedString(@"Please make sure the passwords match",@"");
    NSString *str3 = NSLocalizedString(@"Failed to send code. Try again later",@"");
    
    self.firstView.lblTipsEmail.text = [EmailValidator isValidEmail:self.firstView.txtEmail.text] ? @"" : str0;
    if(![EmailValidator isValidEmail:self.firstView.txtEmail.text]){
        return;
    }
    self.firstView.lblTipsPassword.text = [EmailValidator isValidPassword:self.firstView.txtPassword.text] ? @"" : str1;
    if(![EmailValidator isValidPassword:self.firstView.txtPassword.text]){
        return;
    }
    self.firstView.lblTipsConfirmPassword.text = [self.firstView.txtPassword.text isEqualToString:self.firstView.txtRepassword.text] ? @"" : str2;
    if(![self.firstView.txtPassword.text isEqualToString:self.firstView.txtRepassword.text] ){
        return;
    }
    self.firstView.lblTipsCode.text = [EmailValidator isValidInput:self.firstView.txtCode.text] ? @"" : str3;
    if(![EmailValidator isValidInput:self.firstView.txtCode.text]){
        return;
    }
    self.btnStart.userInteractionEnabled = NO;
    self.btnStart.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnStart.userInteractionEnabled = YES;
        self.btnStart.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1];
        });
    
    [MBProgressHUD showMessage:@""];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(Countdown_Seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUD];
    });
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"email"] = self.firstView.txtEmail.text;
    params[@"password"] = self.firstView.txtPassword.text;
    params[@"repassword"] = self.firstView.txtRepassword.text;
    params[@"captcha"] = self.firstView.txtCode.text;
    params = [LanguageHelper currentLanguageParams:params];
    params[@"platform"] = @"2";
    
    params[@"channel"] = @"apple";
    params[@"device_id"] = [KeychainUUID getUUID];
    params[@"device_id_type"] = @"app_uuid";
    params[@"guest_uuid"] = [KUSER_DEFAULT objectForKey:Guest_Uuid_Key];

    
    [HttpTools postRequestUsers:@"/auth/register" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        [MBProgressHUD hideHUD];
        
        for (int i = 0; i < 4; i ++) {
            UILabel *lblTips = (UILabel *)[self.firstView viewWithTag:60 + i];
            lblTips.text = @"";
        }

        if (success) {
            //[MBProgressHUD showLabel:response.msg];
            [self loginSuccess:response.data];
            [self registerLogEvent];//注册成功 添加埋点事件
  
            [KUSER_DEFAULT setObject:self.firstView.txtEmail.text forKey:@"account_key"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self btnReturnAction:self.btnReturnOld];
                self.txtEmailAddress.text = [KUSER_DEFAULT objectForKey:@"account_key"];
                //self.txtPassword.text = [KUSER_DEFAULT objectForKey:@"password_key"];
            });
        } else {
            self.firstView.lblTipsEmail.text = (response.code == 1001) ? response.msg : @"";
            self.firstView.lblTipsPassword.text = (response.code == 1002) ? response.msg : @"";
            self.firstView.lblTipsCode.text = (response.code == 1003) ? response.msg : @"";
            
            if(response.code == 1001 || response.code == 1002|| response.code == 1003){
            } else {
                [MBProgressHUD showLabel:response.msg];
            }
            
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}

- (void)btnPasswordLoginAction {
     self.lblTips.text = [EmailValidator isValidEmail:self.txtEmailAddress.text] ? @"" : NSLocalizedString(@"Please enter a valid email address",@"");
    if(![EmailValidator isValidEmail:self.txtEmailAddress.text]){
        return;
    }
    
    self.lblTips2.text = [EmailValidator isValidPassword:self.txtPassword.text] ? @"" : NSLocalizedString(@"Password must be at least 6 characters",@"");
     if(![EmailValidator isValidPassword:self.txtPassword.text]){
         return;
     }
     NSMutableDictionary *params = [NSMutableDictionary dictionary];
     params[@"email"] = self.txtEmailAddress.text;//
     params[@"password"] = self.txtPassword.text;
    
    self.btnStart.userInteractionEnabled = NO;
    self.btnStart.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnStart.userInteractionEnabled = YES;
        self.btnStart.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1];
        });
    
    [MBProgressHUD showMessage:@""];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(Countdown_Seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUD];
    });
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequestUsers:@"/auth/login" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        [MBProgressHUD hideHUD];
        
        //NSLog(@"左--------[%@]-[%d]-[%@]---------------------",response.msg,response.code,response.data);
         if (success) {
             [self loginSuccess:response.data];
             [KUSER_DEFAULT setObject:self.txtEmailAddress.text forKey:@"account_key"];
        } else {
                //左
                self.lblTips2.text = (response.code == 1002) ? response.msg : @"";
                if(response.code == 1002){
                } else {
                    [MBProgressHUD showLabel:response.msg];
                }
        }

    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)btnCodeLoginAction {
    
    self.lblTips.text = [EmailValidator isValidEmail:self.txtEmailCode.text] ? @"" : NSLocalizedString(@"Please enter a valid email address",@"");
    if(![EmailValidator isValidEmail:self.txtEmailCode.text]){
        return;
    }
    self.lblTips2.text = [EmailValidator isValidInput:self.txtCode.text] ? @"" : NSLocalizedString(@"Incorrect code. Please try again",@"");
    if(![EmailValidator isValidInput:self.txtCode.text]){
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"email"] = self.txtEmailCode.text;//
    params[@"captcha"] = self.txtCode.text;

    //@"#3A89D8" 深蓝        @"#7EBBFF"//浅色
    
    self.btnStart.userInteractionEnabled = NO;
    self.btnStart.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnStart.userInteractionEnabled = YES;
        self.btnStart.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1];
        });
    
    [MBProgressHUD showMessage:@""];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(Countdown_Seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUD];
    });
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequestUsers:@"/auth/login" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        [MBProgressHUD hideHUD];
        //NSLog(@"右边--------[%@]-[%d]-[%@]---------------------",response.msg,response.code,response.data);
         if (success) {
             [KUSER_DEFAULT setObject:self.txtEmailCode.text forKey:@"account_key"];
             [self loginSuccess:response.data];
        } else {
                //右边
                self.lblTips2.text = (response.code == 1003) ? response.msg : @"";
                if(response.code == 1003){
                } else {
                    [MBProgressHUD showLabel:response.msg];
                }
            
            }
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)registerLogEvent{
    // 注册成功时
    //[FBSDKAppEvents logEvent:FBSDKAppEventNameCompletedRegistration];
    //[AppEvents logEvent:AppEventNameCompletedRegistration]
    
    //[[UMAnalyt       //[MobClick
    if (!IS_UM_SDK) {//埋点  埋点注册成功
        // Facebook
        [[FBSDKAppEvents shared] logEvent:FBSDKAppEventNameCompletedRegistration];
        // AppsFlyer
        [[AppsFlyerLib shared] logEvent:AFEventCompleteRegistration
                             withValues:@{@"af_registration_method": @"email"}];
        // Firebase
        [FIRAnalytics logEventWithName:kFIREventSignUp
                            parameters:@{kFIRParameterMethod: @"email"}];
    }
    [[AnalyticsManager shared] trackEvent:EventTypeRegister event_name:@"注册" params:nil];
}

- (void)loginSuccess:(NSDictionary *)data{
    [KUSER_DEFAULT setBool:YES forKey:@"DataChanged_KEY"];
    if (self.loginCompletion) {
        self.loginCompletion();
    }
    [PublicTool resetTriggered];
    [PublicTool markAsRegistered];
    [UserStateManager shared].needRefreshLoginUI = YES;//用户登录成功
    [[AnalyticsManager shared] trackEvent:EventTypeLogin event_name:@"登录" params:nil];

    NSDictionary *dic = [NSDictionary dictionaryWithDictionary:data];
    NSString *access_token = [NSString stringWithFormat:@"Bearer %@",dic[@"access_token"]];
    NSDictionary *dicUser = [NSDictionary dictionaryWithDictionary:dic[@"user"]];
    [[UserModel sharedInstance] saveLoginInfoWithToken:access_token user:dicUser];
    [KUSER_DEFAULT setObject:access_token forKey:@"Authorization_key"];
    [KUSER_DEFAULT setObject:dicUser forKey:@"user_info_key"];
  
    if(self.isCurrent){
        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            // 验证成功后的回调处理（可选）
            //NSLog(@"已返回‘我的’页面");
            if(self.loginCompletion){
                self.loginCompletion();
            }
        }];
    } else {
        [theAppDelegate setTabBarController];
    }


  
}

@end

//如果需要带参数
//NSDictionary *params = @{ FBSDKAppEventParameterNameRegistrationMethod : @"Email" };
//[[FBSDKAppEvents shared] logEvent:FBSDKAppEventNameCompletedRegistration parameters:params];
//新版加参数
//[AppEvents logEvent:AppEventNameCompletedRegistration
          //parameters:@{AppEventParameterNameRegistrationMethod: @"email"}];

//加埋点
//[[FBSDKAppEvents shared] logPurchase:29.99 currency:@"SE"];
//带参数版本
//NSDictionary *params = @{ FBSDKAppEventParameterNameContentType : @"product" };
//[[FBSDKAppEvents shared] logPurchase:29.99 currency:@"SE" parameters:params];

//AppsFlyerLib
/*
 [[AppsFlyerLib shared] logEvent:AFEventCompleteRegistration
                      withValues:@{@"af_registration_method": @"email"}];

 [[AppsFlyerLib shared] logEvent:AFEventPurchase
                      withValues:@{
                         AFEventParamRevenue: @99.9,
                         AFEventParamCurrency: @"CNY",
                         AFEventParamContentId: @"sku123"
                      }];
 自定义事件
 [[AppsFlyerLib shared] logEvent:@"my_custom_event"
                      withValues:@{@"key1": @"value1", @"key2": @"value2"}];
 */
