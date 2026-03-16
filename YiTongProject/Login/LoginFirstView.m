//
//  LoginFirstView.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/27.
//

#import "LoginFirstView.h"
#import "CountDownButton.h"
#import "EmailValidator.h"
#import "MessageView.h"
@interface LoginFirstView()<UITextFieldDelegate>
@property (strong, nonatomic) UIView *viewCode;
@property (strong, nonatomic) UIImageView *imgAvatar;
@property (strong, nonatomic) CountDownButton *btnSendCode;
@end
@implementation LoginFirstView
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.imgAvatar];
        [self addSubview:self.lblHello];
        //[self addSubview:self.lblTitle];

        for (int i = 0; i < 4; i ++) {
            UIView *grayView = [[UIView alloc]initWithFrame:CGRectMake(Distance＿X, self.lblHello.frame.origin.y + 76 + 76 * i, SCREEN_WIDTH - 2 * Distance＿X, 48)];
            [grayView.layer setBorderWidth:1];//边框
            grayView.layer.borderColor = [self colorWithHexString:@"#DADCE5" alpha:1].CGColor;
            grayView.layer.cornerRadius = 8;
            grayView.tag = 50 + i;
            [self addSubview:grayView];

            UITextField *txtField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, grayView.frame.size.width-15, grayView.frame.size.height)];
            txtField.delegate = self;
            txtField.tag = 100 + i;
            txtField.tintColor = [self colorWithHexString:@"#C0D0E0" alpha:1];
            txtField.tintColor = [self colorWithHexString:@"#4C9BEF" alpha:1];
            txtField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0,0,10,0)];
            txtField.leftViewMode = UITextFieldViewModeAlways;
            txtField.textColor = [self colorWithHexString:@"#212121" alpha:1];
            txtField.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
            [grayView addSubview:txtField];
            txtField.keyboardType = UIKeyboardTypeDefault;
            
            if(i==3){
                txtField.frame = CGRectMake(0, 0, grayView.frame.size.width - 15 - 105, grayView.frame.size.height);
            }
            
            UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿X + 5, grayView.frame.origin.y + 52,SCREEN_WIDTH - 2 *Distance＿X, 14)];
            label.font = [UIFont fontWithName:FONT_NAME_Regular size:10];
            label.tag = 60 + i;
            label.text = @"";
            [self addSubview:label];
            label.textColor = [self colorWithHexString:@"#EF5350" alpha:1];
        }
    
        self.lblTipsEmail = (UILabel *)[self viewWithTag:60];
        self.lblTipsPassword = (UILabel *)[self viewWithTag:61];
        self.lblTipsConfirmPassword = (UILabel *)[self viewWithTag:62];
        self.lblTipsCode = (UILabel *)[self viewWithTag:63];

        for (int i = 0; i < 2; i ++) {
            UIView *grayView = (UIView *)[self viewWithTag:51 + i];
            UIButton *btnHidden = [UIButton buttonWithType:UIButtonTypeCustom];
            btnHidden.frame = CGRectMake(grayView.frame.size.width - 45 - 3, 0, 45, grayView.frame.size.height);
            btnHidden.tag = 70 + i;
            [btnHidden addTarget:self action:@selector(btnHiddenAction:) forControlEvents:UIControlEventTouchUpInside];
            [btnHidden setImage:[UIImage imageNamed:@"preview＿level"] forState:UIControlStateNormal];
            [grayView addSubview:btnHidden];
        }
        self.txtEmail = (UITextField *)[self viewWithTag:100];
        self.txtPassword = (UITextField *)[self viewWithTag:101];
        self.txtRepassword = (UITextField *)[self viewWithTag:102];
        self.txtCode = (UITextField *)[self viewWithTag:103];
        
        self.txtCode.keyboardType = UIKeyboardTypeNumberPad;
        self.txtPassword.secureTextEntry = YES;
        self.txtRepassword.secureTextEntry = YES;
        
        [self.txtEmail addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        self.viewCode = (UIView *)[self viewWithTag:53];
        [self.viewCode addSubview:self.btnSendCode];
        [self.txtCode addTarget:self action:@selector(textFieldtxtCodeDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    return self;
}
//不能输入空格
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    NSString *strT = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
    if(![string isEqualToString:strT]) {
        return NO;
    }
    return YES;
}
- (void)btnHiddenAction:(UIButton *)sender {
    if(sender.tag == 70){
        UIButton *btnHidden = (UIButton *)[self viewWithTag:70];
        self.txtPassword.secureTextEntry = !self.txtPassword.secureTextEntry;
        if(self.txtPassword.secureTextEntry){
            [btnHidden setImage:[UIImage imageNamed:@"preview＿level"] forState:UIControlStateNormal];
        } else {
            [btnHidden setImage:[UIImage imageNamed:@"preview＿open"] forState:UIControlStateNormal];
        }
    } else {
        UIButton *btnHidden = (UIButton *)[self viewWithTag:71];
        self.txtRepassword.secureTextEntry = !self.txtRepassword.secureTextEntry;
        if(self.txtRepassword.secureTextEntry){
            [btnHidden setImage:[UIImage imageNamed:@"preview＿level"] forState:UIControlStateNormal];
        } else {
            [btnHidden setImage:[UIImage imageNamed:@"preview＿open"] forState:UIControlStateNormal];
        }
    }
}
- (UIImageView *)imgAvatar {
    if(!_imgAvatar){
        //int width = 40;//210
        int width = 54;//210
        _imgAvatar = [[UIImageView alloc]initWithFrame:CGRectMake(Distance＿X, 5, width, width )];
        _imgAvatar.layer.cornerRadius = 5;//圆角
        _imgAvatar.layer.masksToBounds = YES;
        _imgAvatar.image = [UIImage imageNamed:@"logo_blue"];
    }
    return _imgAvatar;
}
- (UILabel *)lblHello {
    if(!_lblHello){
        _lblHello = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿X, 55 + 5, SCREEN_WIDTH - 2 *Distance＿X, 42)];
        _lblHello.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:24];
        _lblHello.textColor = BLACK_COLOR;
    }
    return _lblHello;
}

- (CountDownButton *)btnSendCode {
    if(!_btnSendCode){
        _btnSendCode = [CountDownButton buttonWithType:UIButtonTypeRoundedRect];
        _btnSendCode.frame = CGRectMake(self.viewCode.frame.size.width - 105 - 3, 0, 105, self.viewCode.frame.size.height);
        UIView *line = [[UIView alloc]initWithFrame:CGRectMake(0, 8, 1, 32)];
        line.backgroundColor = [self colorWithHexString:@"#DADCE5" alpha:1];
        [_btnSendCode addSubview:line];
        _btnSendCode.countDownTime = 60; // 设置倒计时时间（可选）
        [_btnSendCode addTarget:self action:@selector(btnSendCodeAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnSendCode;
}
- (void)btnSendCodeAction:(UIButton *)sender {

    if(self.isRegister){
        
        if (![KUSER_DEFAULT boolForKey:@"is_select_key"]) {
            [MessageView showViewTitle:@"" buttonArrayTitle:@[] callBack:^(NSInteger index) {
                if(index == 101){
                    if(self.selectedReadTypeIndex){
                        self.selectedReadTypeIndex(101);
                    }
                }
            }];
            
            [self.txtCode resignFirstResponder];
            [self.txtEmail resignFirstResponder];
            [self.txtPassword resignFirstResponder];
            [self.txtRepassword resignFirstResponder];
            return;
        }
    }

    self.lblTipsCode.text = @"";
    self.lblTipsEmail.text = [EmailValidator isValidEmail:self.txtEmail.text] ? @"" : NSLocalizedString(@"Please enter a valid email address",@"");
    if(![EmailValidator isValidEmail:self.txtEmail.text]){
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"email"] = self.txtEmail.text;
    params[@"scene"] = @[@"reset",@"register"][self.isRegister];// 0忘记密码  1 注册
    //NSLog(@"params--------[%@]------[%d]---------aaa---",params,self.isRegister);
    self.btnSendCode.userInteractionEnabled = NO;
    self.btnSendCode.countdownLabel.textColor = [self colorWithHexString:@"#C0D0E0" alpha:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.btnSendCode.userInteractionEnabled = YES;
        self.btnSendCode.countdownLabel.textColor = Main_COLOR;
        });
    
    //场景（'register'：注册, 'login'：登录, 'reset'：重置密码）
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequestUsers:@"/captcha/send" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
         //NSLog(@"-----[%@]---[%@]---[%d]---code",response.data,response.msg,response.code);
         if (success) {
             [self.btnSendCode startCountDown];
             [MBProgressHUD showLabel:response.msg];
             // 2. 设置点击回调（实际发送验证码的逻辑）
              __weak typeof(self) weakSelf = self;
             self.btnSendCode.countDownBlock = ^{
                [weakSelf sendVerificationCode];
              };
        } else {
            [self.btnSendCode stopCountDown];
            self.lblTipsEmail.text = (response.code == 1001) ? response.msg : @"";
            if(response.code == 1001){
            } else {
                [MBProgressHUD showLabel:response.msg];
            }
        }
        //
    } failure:^(NSError * _Nonnull error) {
    }];
}
// 模拟发送验证码请求
- (void)sendVerificationCode {
    //NSLog(@"发送验证码请求...");
    // 这里替换为实际的网络请求
    // 如果请求失败，可以手动停止倒计时：
    // [_countDownButton stopCountDown];
}
//点击空白回收键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self endEditing:YES];
}
//检测UITextField是否输入点击状态
- (void)textFieldDidBeginEditing:(UITextField *)textField {
//    int tag = (int)textField.tag - 100;
//    for (int i = 0; i < 4; i ++) {
//        //UIView *grayView = (UIView *)[self viewWithTag:50 + i ];
//        if(i == tag){
//            //grayView.layer.borderColor = [UIColor blueColor].CGColor;
//        } else  {
//            //grayView.layer.borderColor = [self colorWithHexString:@"#DADCE5" alpha:1].CGColor;
//        }
//    }
}
- (void)textFieldtxtCodeDidChange:(UITextField *)textField {
    if(self.selectedTypeIndex){
        self.selectedTypeIndex(textField.text.length);
    }
}
- (void)textFieldDidChange:(UITextField *)textField {
    [self checkInputLength:textField.text];
}
-(void)checkInputLength:(NSString *)text{

    if([EmailValidator isValidEmail:text]){
        self.btnSendCode.userInteractionEnabled = YES;
        self.btnSendCode.titleLabel.tintColor = Main_COLOR;
        self.btnSendCode.countdownLabel.textColor = Main_COLOR;
     } else {
         self.btnSendCode.titleLabel.tintColor = [self colorWithHexString:@"#C0D0E0" alpha:1];
         self.btnSendCode.countdownLabel.textColor = [self colorWithHexString:@"#C0D0E0" alpha:1];
         self.btnSendCode.userInteractionEnabled = NO;
     }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
@end
