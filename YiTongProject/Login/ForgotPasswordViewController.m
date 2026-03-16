//
//  ForgotPasswordViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/26.
//

#import "ForgotPasswordViewController.h"
#import "PasswordSuccessfulView.h"
#import "EmailValidator.h"
@interface ForgotPasswordViewController ()<UITextFieldDelegate>

@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UIButton *btnStart;
@property (strong, nonatomic) LoginFirstView *firstView;
@end
//忘记密码
@implementation ForgotPasswordViewController


- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
    for (int i = 0; i < 4; i ++) {
        UILabel *lblTips = (UILabel *)[self.firstView viewWithTag:60 + i];
        lblTips.text = @"";
    }
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[KeyboardAvoidingManager sharedManager] unregisterView];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    [self addGlobalBackButtonColor:[UIColor clearColor] headerTitleDic:@{}];
    
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIImage *backgroundImage = [UIImage imageNamed:@"launch_background"];
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    backgroundImageView.image = backgroundImage;
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];

    [self.view addSubview:self.firstView];
    [self.view addSubview:self.btnStart];
    
    [[KeyboardAvoidingManager sharedManager] registerView:self.view containerView:self.view];
    [[KeyboardAvoidingManager sharedManager] setPadding:50];
}
- (LoginFirstView *)firstView {
    if(!_firstView){
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        _firstView = [[LoginFirstView alloc]initWithFrame:CGRectMake(0, 157 + statusBarH - 20 - 43, SCREEN_WIDTH, 420)];
        _firstView.backgroundColor = [UIColor clearColor];
        _firstView.lblHello.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:18];
        //_firstView.lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:18];
        _firstView.clipsToBounds = YES;
        _firstView.lblHello.text = NSLocalizedString(@"Forgot your password?", @"");;
        
        for (int i = 0; i < 4; i ++) {
            UITextField *txtField = (UITextField *)[self.firstView viewWithTag:100 + i];
            NSString *str = @[@"Email Address",@"New Password",@"Confirm Password",@"Enter The Verification Code"][i];
            str = NSLocalizedString(str, @"");
            UIColor *color = [self.view colorWithHexString:@"#C0D0E0" alpha:1];
            txtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:str  attributes:@{NSForegroundColorAttributeName:color}];
            NSString *str2 = @[@"Please enter a valid email address",@"Password must be at least 6 characters",@"Passwords do not match",@"Incorrect code. Please try again"][i];
            str2 = NSLocalizedString(str2, @"");
            UILabel *label = (UILabel *)[self.firstView viewWithTag:60 + i];
            label.text = str2;
        }
    }
    return _firstView;
}
//点击空白回收键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.firstView endEditing:YES];
}
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    NSString *strT = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    if(![string isEqualToString:strT]) {
        return NO;
    }
    return YES;
}
- (UIButton *)btnStart {
    if(!_btnStart){
        _btnStart = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnStart.frame = CGRectMake(Distance＿X, self.firstView.frame.origin.y + self.firstView.frame.size.height + 50, SCREEN_WIDTH - 2 * Distance＿X, 52);
        _btnStart.layer.cornerRadius = 12;//圆角
        _btnStart.layer.masksToBounds = YES;
        _btnStart.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:18];
  
        [_btnStart setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_btnStart addTarget:self action:@selector(btnStartAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnStart setTitle:NSLocalizedString(@"Reset Password", @"") forState:UIControlStateNormal];
        //_btnStart.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
        _btnStart.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1];
        _btnStart.titleLabel.textColor = [UIColor whiteColor];
    }
    return _btnStart;
}
- (void)btnStartAction:(UIButton *)sender {
    NSString *str0 = NSLocalizedString(@"Please enter a valid email address", @"");
    NSString *str1 = NSLocalizedString(@"Password must be at least 6 characters", @"");
    NSString *str2 = NSLocalizedString(@"Passwords do not match", @"");
    NSString *str3 = NSLocalizedString(@"Incorrect code. Please try again", @"");

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
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"email"] = self.firstView.txtEmail.text;
    params[@"password"] = self.firstView.txtPassword.text;
    params[@"repassword"] = self.firstView.txtRepassword.text;
    params[@"captcha"] = self.firstView.txtCode.text;
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequestUsers:@"/auth/resetPassword" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        
        for (int i = 0; i < 4; i ++) {
            UILabel *lblTips = (UILabel *)[self.firstView viewWithTag:60 + i];
            lblTips.text = @"";
        }
         if (success) {
             
            [PasswordSuccessfulView showViewTitle:@"" buttonArrayTitle:@[] callBack:^(NSInteger index) {
            }];
             [KUSER_DEFAULT setObject:self.firstView.txtEmail.text forKey:@"account_key"];
             //[KUSER_DEFAULT setObject:self.firstView.txtPassword.text forKey:@"password_key"];
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.navigationController popViewControllerAnimated:YES];
                 });
             
         } else {
             //self.firstView.lblTipsCode.text = array[3];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
