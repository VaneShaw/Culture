//
//  PhoneLoginViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/1.
//
#import <Network/Network.h>  
#import "PhoneLoginViewController.h"
#import "PhoneCodeViewController.h"
#import "HelpRulesViewController.h"
@interface PhoneLoginViewController ()<UITextFieldDelegate>
@property (strong, nonatomic) UIImageView *imgAvatar;

@property (strong, nonatomic) UIView *txtView;
@property (strong, nonatomic) UITextField *txtPhone;
@property (strong, nonatomic) UIButton *btnCode;
@property (strong, nonatomic) UILabel *lblTips;
@property (strong, nonatomic) AgreementConsentView *agreeView;
@property (strong, nonatomic) UIButton *btnReturn;

@property (assign, nonatomic) BOOL isReturn;
@end

@implementation PhoneLoginViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    self.isReturn = YES;
}
- (void)viewDidAppear:(BOOL)animated {
    [[KeyboardAvoidingManager sharedManager] registerView:self.view containerView:self.view];
    [[KeyboardAvoidingManager sharedManager] setPadding:125];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(self.isReturn){
            [self.txtPhone becomeFirstResponder]; // 自动弹出键盘
        }
    });
    
}
- (void)viewWillDisappear:(BOOL)animated {//视图即将消失
    [super viewWillDisappear:animated];
    self.isReturn = NO;
}
- (void)viewDidDisappear:(BOOL)animated{  //视图--消失
    [self.txtPhone resignFirstResponder];
}
- (UIButton *)btnReturn {
    if(!_btnReturn){
        _btnReturn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        _btnReturn.frame = CGRectMake(Distance＿X-5, 35 + statusBarH-15 - 20, 40,60);
        [_btnReturn addTarget:self action:@selector(btnReturnAction:) forControlEvents:UIControlEventTouchUpInside];
        UIImageView *close = [UIImageView new];
        close.frame = CGRectMake(5, 5 + 20, 20, 20);
        close.image = [UIImage imageNamed:@"close_black"];
        [_btnReturn addSubview:close];
  
    }
    return _btnReturn;
}
//登录页
- (void)btnReturnAction:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    [self.view addSubview:self.btnReturn];
    [self.view addSubview:self.imgAvatar];
    [self.view addSubview:self.txtView];
    
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
    };
    //BOOL isChecked = agree.isChecked;
    agree.onTapLinkName = ^(NSString *name) {
        HelpRulesViewController *rulesVC = [HelpRulesViewController new];
        if ([name isEqualToString:@"用户协议"]) {
            //NSLog(@"点了用户协议");
            //rulesVC.title = NSLocalizedString(@"《用户协议》",@"");
            rulesVC.title = NSLocalizedString(@"[Terms of Service]",@"");
            rulesVC.rule_type = @"agreement";
        } else if ([name isEqualToString:@"隐私政策"]) {
            //NSLog(@"点了隐私政策");
            //rulesVC.title = NSLocalizedString(@"《隐私政策》",@"");
            rulesVC.title = NSLocalizedString(@"[Privacy Policy]",@"");
            rulesVC.rule_type = @"privacy";
        }

        [self.navigationController pushViewController:rulesVC animated:YES];
    };
    [self.view addSubview:agree];
    [NSLayoutConstraint activateConstraints:@[
        [agree.topAnchor constraintEqualToAnchor:self.txtView.bottomAnchor constant:32],
        [agree.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [agree.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
    ]];
    
    [self.view addSubview:self.btnCode];
    [NSLayoutConstraint activateConstraints:@[
        // 顶部约束：在 agree 下方 16pt
        [self.btnCode.topAnchor constraintEqualToAnchor:agree.bottomAnchor constant:16],
        // 左右边距约束：各 26pt
        [self.btnCode.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:26],
        [self.btnCode.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-26],
        [self.btnCode.heightAnchor constraintEqualToConstant:58]
    ]];
    
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

- (UIImageView *)imgAvatar {
    if(!_imgAvatar){
        int width = 48;
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        _imgAvatar = [[UIImageView alloc]initWithFrame:CGRectMake(Distance＿X, statusBarH + 86, width, width)];
        _imgAvatar.layer.cornerRadius = 5;//圆角
        _imgAvatar.layer.masksToBounds = YES;
        _imgAvatar.image = [UIImage imageNamed:@"logo_blue"];

        UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿X, _imgAvatar.frame.origin.y + _imgAvatar.frame.size.height + 16, SCREEN_WIDTH - 2*Distance＿X , 68)];
        lblTitle.textColor = BLACK_COLOR_1F;
        lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:24];
        lblTitle.textAlignment = NSTextAlignmentLeft;
        lblTitle.numberOfLines = 2;//@"\n"
        lblTitle.text = NSLocalizedString(@"你好，\n欢迎使用实亿易通",@"");
        [self.view addSubview:lblTitle];
        
        UILabel *lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿X, _imgAvatar.frame.origin.y + _imgAvatar.frame.size.height + 92, SCREEN_WIDTH - 2*Distance＿X , 18)];
        lblSubtitle.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
        lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
        lblSubtitle.textAlignment = NSTextAlignmentLeft;
        lblSubtitle.text = NSLocalizedString(@"未注册手机号验证后自动创建实亿易通账号",@"");
        [self.view addSubview:lblSubtitle];
    
    }
    return _imgAvatar;
}

- (UIView *)txtView {
    if(!_txtView){
        _txtView = [UIView new];
        _txtView.frame = CGRectMake(Distance＿X, self.imgAvatar.frame.origin.y + self.imgAvatar.frame.size.height + 151, SCREEN_WIDTH - 2 * Distance＿X, 58);
        _txtView.layer.cornerRadius = 58/2;//圆角
        _txtView.layer.masksToBounds = YES;
        _txtView.backgroundColor = [self.view colorWithHexString:@"#F8F8F8" alpha:1];
        
        UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(45, _txtView.frame.origin.y + 60,SCREEN_WIDTH - 2 * 80, 14)];
        label.font = [UIFont fontWithName:FONT_NAME_Regular size:10];
        label.textColor = [self.view colorWithHexString:@"#EF5350" alpha:1];
        [self.view addSubview:label];
        self.lblTips = label;
        
        UILabel *lblNumber = [[UILabel alloc]initWithFrame:CGRectMake(0, 15,61, 28)];
        lblNumber.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        lblNumber.text = @"+86";
        lblNumber.textAlignment = NSTextAlignmentCenter;
        lblNumber.textColor = BLACK_COLOR_1F;
        [_txtView addSubview:lblNumber];
        
        UIView *line = [[UIView alloc]initWithFrame:CGRectMake(61, 18, 1, 58 - 36)];
        line.backgroundColor = [self.view colorWithHexString:@"#63A8F5" alpha:1];
        [_txtView addSubview:line];
        [_txtView addSubview:self.txtPhone];
    }
    return _txtView;
}
- (UITextField *)txtPhone {
    if(!_txtPhone){
        _txtPhone = [UITextField new];
        _txtPhone.frame = CGRectMake(81, 0, self.txtView.frame.size.width - 100, 58);
        _txtPhone.delegate = self;
        _txtPhone.tintColor = [self.view colorWithHexString:@"#4C9BEF" alpha:1];
        _txtPhone.textColor = [self.view colorWithHexString:@"#212121" alpha:1];
        _txtPhone.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        _txtPhone.keyboardType = UIKeyboardTypeNumberPad;
        [_txtPhone addTarget:self action:@selector(textFieldPhoneDidChange:) forControlEvents:UIControlEventEditingChanged];
        
        NSString *str = NSLocalizedString(@"请输入手机号",@"");
        UIColor *color = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
        _txtPhone.attributedPlaceholder = [[NSAttributedString alloc] initWithString:str  attributes:@{NSForegroundColorAttributeName: color}];
    }
    return _txtPhone;
}
- (void)textFieldPhoneDidChange:(UITextField *)textField {
    BOOL isCode = [PublicTool isValidPhone:textField.text];
    self.lblTips.text = @"";
    _btnCode.backgroundColor = [self.view colorWithHexString:@[@"#BEDDFF",@"#3A89D8"][isCode] alpha:1];
}
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    NSString *strT = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    if(![string isEqualToString:strT]) {
        return NO;
    }
    return YES;
}
//点击空白回收键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
- (UIButton *)btnCode {
    if(!_btnCode){
        _btnCode = [UIButton buttonWithType:UIButtonTypeCustom];
        //_btnCode.frame = CGRectMake(Distance＿X, self.txtView.frame.origin.y + self.txtView.frame.size.height + 65, SCREEN_WIDTH - 2 * Distance＿X, 58);
        _btnCode.layer.cornerRadius = 58/2;//圆角
        _btnCode.layer.masksToBounds = YES;
        _btnCode.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:18];
        _btnCode.translatesAutoresizingMaskIntoConstraints = NO;
        [_btnCode setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_btnCode addTarget:self action:@selector(btnStartAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnCode setTitle:NSLocalizedString(@"Send Code", @"") forState:UIControlStateNormal];
        _btnCode.backgroundColor = [self.view colorWithHexString:@"#BEDDFF" alpha:1]; //@"#BEDDFF" 浅色    @"#3A89D8" 深蓝
        _btnCode.titleLabel.textColor = [UIColor whiteColor];
        _btnCode.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:20];
        
        UIImage *arrowImage = [UIImage imageNamed:@"next_white"];
        [_btnCode setImage:arrowImage forState:UIControlStateNormal];
        _btnCode.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        _btnCode.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _btnCode.titleEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
        _btnCode.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -2);
        _btnCode.adjustsImageWhenHighlighted = NO;
        
    }
    return _btnCode;
}

- (void)btnStartAction:(UIButton *)sender {
  
    if([PublicTool isValidPhone:self.txtPhone.text]){
        if(self.agreeView.isChecked){
            PhoneCodeViewController *vc = [PhoneCodeViewController new];
            vc.isCurrent = self.isCurrent;
            vc.phone = self.txtPhone.text;
            vc.loginCompletion = ^{
                if(self.loginCompletion){
                    self.loginCompletion();
                }
            };
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            NSArray *titleArray = @[@"用户协议及隐私政策",@"我已阅读并同意《用户协议》和《隐私政策》",@"Cancel",@"同意并继续"];
            [ReadyLogOutView showViewTitle:@"1" buttonArrayTitle:titleArray callBack:^(NSInteger index) {
                if(index==1001){
                    [self.agreeView markAsChecked];
                    PhoneCodeViewController *vc = [PhoneCodeViewController new];
                    vc.loginCompletion = ^{
                        if(self.loginCompletion){
                            self.loginCompletion();
                        }
                    };
                    vc.isCurrent = self.isCurrent;
                    vc.phone = self.txtPhone.text;
                    [self.navigationController pushViewController:vc animated:YES];
                } else {
                    if(index==200 || index == 201){
                        [self userAgreementView:(int)index];
                    }
                }
            }];
        }
        self.lblTips.text = @"";
    } else {
        self.lblTips.text = NSLocalizedString(@"请输入正确的手机号",@"");
    }
}
- (void)userAgreementView:(int)index {
    HelpRulesViewController *rulesVC = [HelpRulesViewController new];
    if (index == 200) {
        //rulesVC.title = NSLocalizedString(@"《用户协议》",@"");
        rulesVC.rule_type = @"agreement";
        rulesVC.title = NSLocalizedString(@"[Terms of Service]",@"");
    } else {
        //rulesVC.title = NSLocalizedString(@"《隐私政策》",@"");
        rulesVC.title = NSLocalizedString(@"[Privacy Policy]",@"");
        rulesVC.rule_type = @"privacy";
    }
    [self.navigationController pushViewController:rulesVC animated:YES];
}
/*
- (void)btnSendCodeAction {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"mobile"] = self.txtPhone.text;
    self.btnCode.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnCode.enabled = YES;
        });
    
    //场景（'register'：注册, 'login'：登录, 'reset'：重置密码）
    [HttpTools postRequestUsers:@"/captcha/sendSms" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        self.btnCode.enabled = YES;
         if (success) {
             PhoneCodeViewController *vc = [PhoneCodeViewController new];
             vc.phone = self.txtPhone.text;
             [self.navigationController pushViewController:vc animated:YES];
        }
        [MBProgressHUD showLabel:response.msg];
    } failure:^(NSError * _Nonnull error) {
    }];
}*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
