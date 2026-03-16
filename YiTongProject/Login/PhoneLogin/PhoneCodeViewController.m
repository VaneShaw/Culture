//
//  PhoneCodeViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/1.
//

#import "PhoneCodeViewController.h"
#import "CountDownButton.h"
#import "ReceiptSyncManager.h"
@interface PhoneCodeViewController ()<UITextFieldDelegate>

@property (nonatomic, strong) UILabel *lblTitle;
@property (nonatomic, strong) UILabel *lblSubtitle;
@property (nonatomic, strong) UITextField *hiddenTextField;
@property (nonatomic, strong) NSMutableArray<UILabel *> *codeLabels;
@property (nonatomic, strong) UIButton *btnSendCode;

@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSInteger remainingSeconds;
@property (nonatomic, strong) UILabel *countdownLabel;
@property (nonatomic, strong) UIColor *blueColor;
// 定义一个光标视图
@property (nonatomic, strong) UIView *cursorView;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation PhoneCodeViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.hiddenTextField resignFirstResponder]; // 页面离开时收起键盘
    [self stopCountdown]; // 停止定时器，避免内存泄露
}

/*
"" = "你好，\n欢迎使用实亿易通";
"" = "未注册手机号验证后自动创建实亿易通账号";
"" = "同意并继续";
"" = "我已阅读并同意《用户协议》和《隐私政策》";

"" = "用户协议及隐私政策";
"" = "请输入正确的手机号";
"" = "请输入手机号";
"" = "重新获取";
"" = "验证码已发送至";
"" = "请输入验证码";
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    [self addGlobalBackButton];
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    // 标题
    self.lblTitle = [[UILabel alloc] init];
    self.lblTitle.text = NSLocalizedString(@"请输入验证码",@"");
    self.lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:24];
    self.lblTitle.textColor = BLACK_COLOR_1F;
    self.lblTitle.frame = CGRectMake(Distance＿X, statusBarH + 116, SCREEN_WIDTH - 2 * Distance＿X, 35);
    [self.view addSubview:self.lblTitle];
    self.blueColor = [self.view colorWithHexString:@"#63A8F5" alpha:1];
    // 副标题
    NSString *str = NSLocalizedString(@"验证码已发送至",@"");
    self.lblSubtitle = [[UILabel alloc] init];
    self.lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
    self.lblSubtitle.textColor = self.blueColor;
    self.lblSubtitle.frame = CGRectMake(Distance＿X, self.lblTitle.frame.origin.y + 43, SCREEN_WIDTH - 2 * Distance＿X, 18);
    [self.view addSubview:self.lblSubtitle];
    
    UIColor *grayColor = [self.view colorWithHexString:@"#63637D" alpha:1];
    NSString *content = [NSString stringWithFormat:@"%@ %@",str,self.phone];
    NSMutableAttributedString *noteStr = [[NSMutableAttributedString alloc] initWithString:content];
    [noteStr addAttribute:NSForegroundColorAttributeName value:grayColor range:NSMakeRange(0,str.length)];
    self.lblSubtitle.attributedText = noteStr;
    
    // 隐藏的输入框（接收键盘输入）
    self.hiddenTextField = [[UITextField alloc] init];
    self.hiddenTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.hiddenTextField.delegate = self;
    self.hiddenTextField.textContentType = UITextContentTypeOneTimeCode; // 支持短信验证码自动填充
    self.hiddenTextField.tintColor = [UIColor clearColor];
    self.hiddenTextField.textColor = [UIColor clearColor];

    self.hiddenTextField.tintColor = [self.view colorWithHexString:@"#4C9BEF" alpha:1];
    [self.view addSubview:self.hiddenTextField];

    // 点击页面，弹出键盘
    //UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(becomeInput)];
    //[self.view addGestureRecognizer:tap];
    
    // 6 个验证码框
    self.codeLabels = [NSMutableArray array];
    CGFloat boxWidth = 44;
    CGFloat gap = (SCREEN_WIDTH - 2 * Distance＿X - boxWidth * 6)/5;
    //CGFloat totalWidth = 6 * boxWidth + 5 * gap;
    //CGFloat startX = (self.view.bounds.size.width - totalWidth) / 2;
    CGFloat y = self.lblSubtitle.frame.origin.y + 60;
    
    for (int i = 0; i < 6; i++) {
        UILabel *box = [[UILabel alloc] initWithFrame:CGRectMake(Distance＿X + i * (boxWidth + gap), y, boxWidth, 58)];
        box.textAlignment = NSTextAlignmentCenter;
        box.font = [UIFont fontWithName:FONT_NAME_Semibold size:24];
        box.layer.cornerRadius = 8;
        box.layer.masksToBounds = YES;
        box.textColor = [UIColor blackColor];
        box.backgroundColor = [self.view colorWithHexString:@"#F2F5F8" alpha:1];
        [self.view addSubview:box];
        [self.codeLabels addObject:box];
    }
    [self.hiddenTextField becomeFirstResponder]; // 自动弹出键盘
    [self.view addSubview:self.btnSendCode];
    [self becomeInput];
    
    // 初始化 cursorView
    self.cursorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 28)];
    self.cursorView.backgroundColor = self.blueColor;
    [self.view addSubview:self.cursorView];
    
    UILabel *currentLabel = self.codeLabels[0];
    self.cursorView.center = CGPointMake(CGRectGetMidX(currentLabel.frame),
                                         CGRectGetMidY(currentLabel.frame));
    
    NSString *str1 = @"13888888888";
    NSString *str2 = @"15666666666";
    if([self.phone isEqualToString:str1]) {
        
    } else {
        [self btnSendCodeAction:self.btnSendCode];
    }

}
- (void)becomeInput {
    [self.hiddenTextField becomeFirstResponder];
}
- (UIButton *)btnSendCode {
    if(!_btnSendCode){
        CGFloat y = self.lblSubtitle.frame.origin.y + 60 + 58 + 16;
        _btnSendCode = [UIButton buttonWithType:UIButtonTypeSystem];
        _btnSendCode.frame = CGRectMake((SCREEN_WIDTH - 130)/2, y, 130, 25);
        //_btnSendCode.countDownTime = 60; // 设置倒计时时间（可选）
        [_btnSendCode addTarget:self action:@selector(btnSendCodeAction:) forControlEvents:UIControlEventTouchUpInside];
        //[_btnSendCode addTarget:self action:@selector(startCountdown) forControlEvents:UIControlEventTouchUpInside];

        self.countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 130, 25)];
        self.countdownLabel.textAlignment = NSTextAlignmentCenter;
        self.countdownLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        self.countdownLabel.textColor = self.blueColor ;
        self.countdownLabel.text = NSLocalizedString(@"重新获取", @"");
        [_btnSendCode addSubview:self.countdownLabel];
    }
    return _btnSendCode;
}
#pragma mark - 倒计时逻辑
- (void)startCountdown {
    self.remainingSeconds = 60;
    self.btnSendCode.enabled = NO;

    [self updateResendButtonTitle];
    self.countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(updateCountdown)
                                                         userInfo:nil
                                                          repeats:YES];
    
    // TODO: 这里可以触发发送验证码的接口
    NSLog(@"开始发送验证码...");
}

- (void)updateCountdown {
    self.remainingSeconds--;
    [self updateResendButtonTitle];
    
    if (self.remainingSeconds <= 0) {
        [self stopCountdown];
        self.countdownLabel.textColor = self.blueColor ;
        self.countdownLabel.text = NSLocalizedString(@"重新获取", @"");
        self.btnSendCode.enabled = YES;
    }
}

- (void)updateResendButtonTitle {
    self.btnSendCode.enabled = NO;
    NSString *str = NSLocalizedString(@"Resend",@"");
    NSString *title = [NSString stringWithFormat:@"%@(%lds)",str, (long)self.remainingSeconds];
    self.countdownLabel.textColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
    self.countdownLabel.text = title;
}

- (void)stopCountdown {
    if (self.countdownTimer) {
        [self.countdownTimer invalidate];
        self.countdownTimer = nil;
    }
}
- (void)btnSendCodeAction:(UIButton *)sender {

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"mobile"] = self.phone;

    self.btnSendCode.enabled = NO;
    self.countdownLabel.textColor = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnSendCode.enabled = YES;
        self.countdownLabel.textColor = Main_COLOR;
        });
    
    //场景（'register'：注册, 'login'：登录, 'reset'：重置密码）
    //NSLog(@"------params--[%@]---paramscode--------",self.phone);
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequestUsers:@"/captcha/sendSms" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
         //NSLog(@"-----[%@]---[%@]---[%d]---code",response.data,response.msg,response.code);
         if (success) {
             [self startCountdown];
        } else {
            [self stopCountdown];
            //self.lblTipsEmail.text = (response.code == 1001) ? response.msg : @"";
            if(response.code == 1001){
            }
        }
        [MBProgressHUD showLabel:response.msg];

    } failure:^(NSError * _Nonnull error) {
    }];
}
#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // 当前输入内容
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    // 限制最多 6 位
    if (newString.length > 6) {
        return NO;
    }
    textField.text = newString;
    // 更新显示框
    for (int i = 0; i < 6; i++) {
        if (i < newString.length) {
            self.codeLabels[i].text = [newString substringWithRange:NSMakeRange(i, 1)];
            self.codeLabels[i].layer.borderColor = self.blueColor.CGColor;
            self.codeLabels[i].layer.borderWidth = 1.0;
        } else {
            self.codeLabels[i].layer.borderWidth = 0;
            self.codeLabels[i].text = @"";
        }
    }
    
    // 输入满 6 位时触发接口
    if (newString.length == 6) {
        [self performSelector:@selector(triggerVerify:) withObject:newString afterDelay:0.2];
        self.cursorView.hidden = YES;
    }  else {
        // 输入完自动跳到下一个格子
        self.selectedIndex = MIN(textField.text.length, 5);
        [self updateSelection];
    }

    return NO; // 已手动更新 textField.text
}
// 监听输入框变化


// 更新边框和光标位置
- (void)updateSelection {
    for (int i = 0; i < self.codeLabels.count; i++) {
        UILabel *label = self.codeLabels[i];
        //label.layer.borderColor = (i == self.selectedIndex) ? self.blueColor.CGColor : [UIColor lightGrayColor].CGColor;
        if(i==self.selectedIndex){
            label.layer.borderColor = self.blueColor.CGColor;
        }
    }
    if (self.selectedIndex < self.codeLabels.count) {
        UILabel *currentLabel = self.codeLabels[self.selectedIndex];
        self.cursorView.hidden = NO;
        self.cursorView.center = CGPointMake(CGRectGetMidX(currentLabel.frame),
                                             CGRectGetMidY(currentLabel.frame));
    } else {
        self.cursorView.hidden = YES;
    }
}
//------------------------------------------------------
#pragma mark - 验证接口
- (void)triggerVerify:(NSString *)code {
    NSLog(@"验证码输入完成: %@", code);
    //[self btnSendCodeAction:self.btnSendCode];
    // TODO: 调用你的验证接口
    // 比如: [NetworkManager verifyCode:code success:... failure:...];
    [self btnCodeLoginAction:code];
}
- (void)btnCodeLoginAction:(NSString *)code {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"mobile"] = self.phone;//
    params[@"captcha"] = code;    //
    params = [LanguageHelper currentLanguageParams:params];
    params[@"platform"] = @"2";
    
    params[@"channel"] = @"apple";
    params[@"oaid"] = [KeychainUUID getUUID];
    params[@"imei"] = @"app_uuid";
    params[@"guest_uuid"] = [KUSER_DEFAULT objectForKey:Guest_Uuid_Key];

    [HttpTools postRequestUsers:@"/authCn/login" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        //[MBProgressHUD hideHUD];
        //NSLog(@"右边------[%d]-[%@]----------------右边-----",response.code,response.data);
         if (success) {
             //[KUSER_DEFAULT setObject:self.phone forKey:@"phone_key"];
             [self loginSuccess:response.data];
         } else {
             [MBProgressHUD showLabel:response.msg];
         }
        //NSLog(@"msg---------[%@]----------------ccc",response.msg);
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)loginSuccess:(NSDictionary *)data{
    [KUSER_DEFAULT setBool:YES forKey:@"DataChanged_KEY"];
    [PublicTool resetTriggered];
    [UserStateManager shared].needRefreshLoginUI = YES;//用户登录成功
    //[MobClick event:@"button_click" attributes:@{@"button_name":@"登录"}];
    //[MobClick event:@"register" attributes:@{@"username": self.username}];
    //[UMConfigure event:@"register" attributes:@{@"user_id": @"123456"}];
    // 埋点注册成功
    /*[MobClick event:@"user_register" attributes:@{
                    @"method": @"phone",
                    @"source": @"AppStore"
            }];
    [MobClick event:@"purchase" attributes:@{
            @"item_id": @"12345",
            @"item_name": @"会员",
            @"price": @"9.99"
    }];*/
   
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
        if (self.loginCompletion) {
            self.loginCompletion();
        }
    }

    NSString *is_register = [NSString stringWithFormat:@"%@",dicUser[@"is_register"]];//1 注册 0 登录
    if(is_register.intValue == 1){//注册
        if (IS_UM_SDK) {//埋点
            NSString *userId = [[UserModel sharedInstance] userId];
            [[UMAnalyticsManager sharedManager] trackUserRegister:userId];
        }
        [[AnalyticsManager shared] trackEvent:EventTypeRegister event_name:@"注册" params:nil];
    } else {//0 登录

        [[AnalyticsManager shared] trackEvent:EventTypeLogin event_name:@"登录" params:nil];
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
