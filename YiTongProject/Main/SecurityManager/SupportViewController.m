//
//  SupportViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/11/30.
//

#import "SupportViewController.h"
#import "EmailValidator.h"
#import "UITextView+Placeholder.h"

@interface SupportViewController ()<UITextFieldDelegate,UITextViewDelegate,UINavigationControllerDelegate,UIGestureRecognizerDelegate>
@property (strong, nonatomic) UIButton *btnSubmit;
@property (strong, nonatomic) UILabel *lblNumber;
@property (strong, nonatomic) UITextField *txtField;
@property (strong, nonatomic) UITextView *txtView;
@property (strong, nonatomic) UIView *footerView;
@end
//客服帮助
@implementation SupportViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
}
- (void)btnSubmitAction:(UIButton *)sender {
    sender.enabled = NO;      // 禁用按钮
    sender.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:0.9];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                      dispatch_get_main_queue(), ^{
        sender.enabled = YES; // 0.8 秒后恢复点击
        sender.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
       });
    
    NSString *str = self.txtField.text;
    if(IS_OVERSEAS_VERSION){
        if(![EmailValidator isValidEmail:str]){
            [MBProgressHUD showLabel:NSLocalizedString(@"Enter your purchase email.",@"")];
            return;
        }
    } else {
        if(![PublicTool isValidPhone:str]){
            [MBProgressHUD showLabel:NSLocalizedString(@"Enter your purchase number",@"")];
            return;
        }
    }
    if(self.txtView.text.length == 0){
        [MBProgressHUD showLabel:NSLocalizedString(@"Describe the issue (up to 500 characters).",@"")];
        return;
    }
    [self addServiceSupport];
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return self.navigationController.viewControllers.count > 1;
}
- (void)addServiceSupport {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    //params[@"user_id"] = [[UserModel sharedInstance] userId];//
    params[@"region"] = @[@"domestic",@"overseas"][IS_OVERSEAS_VERSION];
    params = [LanguageHelper currentLanguageParams:params];
    if(IS_OVERSEAS_VERSION){
        params[@"email"] = self.txtField.text;
    } else {
        params[@"phone"] = self.txtField.text;
    }
    params[@"feedback"] = self.txtView.text;
    [HttpTools postRequest:@"/user/addServiceSupport" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        NSLog(@"【创建订单】-------------[%@]-[%@]---[%d]---------===",response.data,response.msg,(int)response.code);
        if (success) {
            //NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
            NSArray *titleArray = @[@"Submitted",@"Your request has been received. Our support team will get back to you as soon as possible.",@"",@"ok"];
            [ReadyLogOutView showViewTitle:@"11" buttonArrayTitle:titleArray callBack:^(NSInteger index) {
            }];
            
        } else {
            NSArray *titleArray = @[@"Submission Failed",@"Something went wrong. Please try again in a moment.",@"",@"Retry"];
            [ReadyLogOutView showViewTitle:@"" buttonArrayTitle:titleArray callBack:^(NSInteger index) {
                if(index==1001){
                    [self addServiceSupport];
                }
            }];
            
            //[MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"Customer Support";
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
  
    [self addGlobalBackButtonColor:[self.view colorWithHexString:@"#F1F1F1" alpha:1]   headerTitleDic:@{@"title":@"Customer Support",@"color":@"#1F1F39"}];
    
    CGRect rectNav = self.navigationController.navigationBar.frame;
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    int y = rectNav.size.height + statusBarH;
    UILabel *lblTitle2 = [[UILabel alloc]init];
    //lblTitle2.frame = CGRectMake(20, y + 36, SCREEN_WIDTH - 40, 44);
    NSString *strTitle2 = @"Having trouble? Tell us what's going on — we're here to help.";
    lblTitle2.text = NSLocalizedString(strTitle2,@"");
    lblTitle2.numberOfLines = 0;
    lblTitle2.translatesAutoresizingMaskIntoConstraints = NO;
    lblTitle2.font = [UIFont fontWithName:FONT_NAME_Medium size:16];
    lblTitle2.textColor = [self.view colorWithHexString:@"#1F1F39" alpha:1];
    [self.view addSubview:lblTitle2];
  
    NSString *account_Channel = @[@"Enter your purchase number",@"Email Used for Purchase (for locating your order)"][IS_OVERSEAS_VERSION];
    NSString *txt_Channel = @[@"Purchase Phone Number",@"Enter your purchase email."][IS_OVERSEAS_VERSION];
    for (int i = 0 ; i < 2; i++) {
        UILabel *lblTitle = [[UILabel alloc]init];
        //lblTitle.frame = CGRectMake(20, y + 100 + 100 * i, SCREEN_WIDTH - 40, 20);
        lblTitle.tag = 100 + i;
        NSString *strTitle = @[account_Channel,@"Issue Description"][i];
        lblTitle.text = NSLocalizedString(strTitle,@"");
        lblTitle.font = [UIFont fontWithName:FONT_NAME_Medium size:14];
        lblTitle.textColor = [self.view colorWithHexString:@"#1F1F39" alpha:1];
        lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:lblTitle];
    }
    UILabel *lblTitle0 = (UILabel *)[self.view viewWithTag:100];
    UILabel *lblTitle1 = (UILabel *)[self.view viewWithTag:101];
    
    UILabel *lblNumber = [[UILabel alloc]init];
    lblNumber.text = @"0/500";
    lblNumber.textAlignment = NSTextAlignmentRight;
    lblNumber.translatesAutoresizingMaskIntoConstraints = NO;
    lblNumber.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    lblNumber.textColor = [self.view colorWithHexString:@"#BFBFBF" alpha:1];
    [self.view addSubview:lblNumber];
    self.lblNumber = lblNumber;
    
    UITextField *txtField = [[UITextField alloc]init];
    txtField.translatesAutoresizingMaskIntoConstraints = NO;
    txtField.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    txtField.backgroundColor = [self.view colorWithHexString:@"#F8F8F8" alpha:1];
    txtField.layer.cornerRadius = 12;//圆角
    txtField.layer.masksToBounds = YES;
    txtField.delegate = self;
    txtField.textColor = BLACK_COLOR_1F;
    txtField.keyboardType = UIKeyboardTypeNumberPad;
    if(IS_OVERSEAS_VERSION){
        txtField.keyboardType = UIKeyboardTypeEmailAddress;
    } else {
        txtField.keyboardType = UIKeyboardTypeNumberPad;
    }
    txtField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0,0,12,0)];
    txtField.leftViewMode= UITextFieldViewModeAlways;
    [self.view addSubview:txtField];
    
    
    // 添加文本变化监听
   [txtField addTarget:self
                          action:@selector(textFieldDidChange:)
                forControlEvents:UIControlEventEditingChanged];
    
    self.txtField = txtField;
    
    UIColor *color = [self.view colorWithHexString:@"#BFBFBF" alpha:1];
    txtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(txt_Channel,@"")  attributes:@{NSForegroundColorAttributeName: color}];
    
    UITextView *txtView = [[UITextView alloc]init];
    txtView.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    txtView.translatesAutoresizingMaskIntoConstraints = NO;
    txtView.backgroundColor = [self.view colorWithHexString:@"#F8F8F8" alpha:1];
    txtView.textColor = BLACK_COLOR_1F;
    txtView.layer.cornerRadius = 12;//圆角
    txtView.layer.masksToBounds = YES;
    txtView.delegate = self;
    //txtView.scrollEnabled = NO;
    txtView.textContainerInset = UIEdgeInsetsMake(10, 8, 10, 8);
    [self.view addSubview:txtView];
    txtView.placeholder = NSLocalizedString(@"Describe the issue (up to 500 characters).",@"");
    self.txtView = txtView;
    [self.view addSubview:self.btnSubmit];

    // 设置 Auto Layout 约束
    [NSLayoutConstraint activateConstraints:@[
        // lblTitle2 约束
        [lblTitle2.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:y + 20],
        [lblTitle2.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [lblTitle2.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        // lblTitle0 约束 (在 lblTitle2 下面 20)
        [lblTitle0.topAnchor constraintEqualToAnchor:lblTitle2.bottomAnchor constant:20],
        [lblTitle0.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [lblTitle0.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        // txtField 约束 (在 lblTitle0 下面 12，固定高度 48)
        [txtField.topAnchor constraintEqualToAnchor:lblTitle0.bottomAnchor constant:12],
        [txtField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [txtField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [txtField.heightAnchor constraintEqualToConstant:48],
        
        // lblTitle1 约束 (在 txtField 下面 20)
        [lblTitle1.topAnchor constraintEqualToAnchor:txtField.bottomAnchor constant:20],
        [lblTitle1.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [lblTitle1.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        // 字数统计标签约束
        [lblNumber.topAnchor constraintEqualToAnchor:txtField.bottomAnchor constant:20],
        [lblNumber.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [lblNumber.widthAnchor constraintEqualToConstant:60],
        
        // txtView 约束 (在 lblTitle1 下面 12，固定高度 141)
        [txtView.topAnchor constraintEqualToAnchor:lblTitle1.bottomAnchor constant:12],
        [txtView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [txtView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [txtView.heightAnchor constraintEqualToConstant:141],
        // 替代 txtView 的高度约束 - 自适应高度（最小高度 141）
        //[txtView.heightAnchor constraintGreaterThanOrEqualToConstant:141], // 最小高度
        
        [self.btnSubmit.topAnchor constraintEqualToAnchor:txtView.bottomAnchor constant:40],
        [self.btnSubmit.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.btnSubmit.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        // 固定高度 56
        [self.btnSubmit.heightAnchor constraintEqualToConstant:56]
    ]];
    [self.view addSubview:self.footerView];
}
//点击空白回收键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
- (UIButton *)btnSubmit {
    if(!_btnSubmit){
        _btnSubmit = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnSubmit.translatesAutoresizingMaskIntoConstraints = NO;
        //_btnSubmit.frame = CGRectMake(Distance＿M, 426 + 44 + 30, SCREEN_WIDTH - 2 * Distance＿M, 56);
        _btnSubmit.layer.cornerRadius = 28;//圆角
        _btnSubmit.layer.masksToBounds = YES;
        _btnSubmit.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
  
        [_btnSubmit setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_btnSubmit addTarget:self action:@selector(btnSubmitAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnSubmit setTitle:NSLocalizedString(@"Submit", @"") forState:UIControlStateNormal];
        _btnSubmit.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
        
        _btnSubmit.userInteractionEnabled = NO;
        _btnSubmit.titleLabel.textColor = [UIColor whiteColor];
    }
    return _btnSubmit;
}

- (void)textViewDidChange:(UITextView *)textView {
    int max_count = 500;
    // 限制字数
    if (textView.text.length > max_count) {
        textView.text = [textView.text substringToIndex:max_count];
    }

    // 更新计数
    self.lblNumber.text = [NSString stringWithFormat:@"%lu/%d",
                      (unsigned long)textView.text.length,
                      max_count];
    
    if(self.txtField.text.length > 0 && self.txtView.text.length > 0 ){
        self.btnSubmit.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1];
        self.btnSubmit.userInteractionEnabled = YES;
    } else {
        self.btnSubmit.userInteractionEnabled = NO;
        self.btnSubmit.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
    }
}
- (void)textFieldDidChange:(UITextField *)textField {
    if(self.txtField.text.length > 0 && self.txtView.text.length > 0 ){
        self.btnSubmit.backgroundColor = [self.view colorWithHexString:@"#3A89D8" alpha:1];
        self.btnSubmit.userInteractionEnabled = YES;
    } else {
        self.btnSubmit.userInteractionEnabled = NO;
        self.btnSubmit.backgroundColor = [self.view colorWithHexString:@"#7EBBFF" alpha:1];
    }
}

- (BOOL)textView:(UITextView *)textView
    shouldChangeTextInRange:(NSRange)range
    replacementText:(NSString *)text {
    int max_count = 500;
    // 即将输入后的内容
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    return newText.length <= max_count;
}

- (UIView *)footerView {
    if (!_footerView) {
        _footerView = [[UIView alloc] init];
        _footerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:_footerView];
        UILabel *lblTitle2 = [[UILabel alloc]init];
        //lblTitle.frame = CGRectMake(20, y + 100 + 100 * i, SCREEN_WIDTH - 40, 20);
        lblTitle2.text = NSLocalizedString(@"Email Support (Backup Channel)",@"");
        lblTitle2.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        lblTitle2.textColor = BLACK_COLOR_1F;
        lblTitle2.translatesAutoresizingMaskIntoConstraints = NO;
        [_footerView addSubview:lblTitle2];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        btn.backgroundColor = [self.view colorWithHexString:@"#F8F8F8" alpha:1];
        btn.layer.cornerRadius = 12;//圆角
        btn.layer.masksToBounds = YES;
        [_footerView addSubview:btn];
        [btn addTarget:self action:@selector(handleEmailBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
            
        UIImageView *imgEmail = [[UIImageView alloc]initWithFrame:CGRectMake(9, (btn.frame.size.height - 36)/2, 36, 36)];
        imgEmail.translatesAutoresizingMaskIntoConstraints = NO;
        imgEmail.image = [UIImage imageNamed:@"email_blue"];
        [btn addSubview:imgEmail];
        
        UIImageView *imgCopy = [[UIImageView alloc]initWithFrame:CGRectMake(btn.frame.size.width - 20 - 20, 12, 20, 20)];
        imgCopy.translatesAutoresizingMaskIntoConstraints = NO;
        imgCopy.image = [UIImage imageNamed:@"copy_gray"];
        [btn addSubview:imgCopy];
    
        NSString *email = self.service_support;
        UIView *tempView = _footerView;
        for (int i = 0 ; i < 2; i++) {
            UILabel *lblTitle = [[UILabel alloc]init];
            //lblTitle.frame = CGRectMake(55, 12 + 24 * i, btn.frame.size.width - 95, 22);
            lblTitle.tag = 200 + i;
            lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
            NSString *strTitle = @[email,@"Contact us via email"][i];
            lblTitle.text = NSLocalizedString(strTitle,@"");
            lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16 - i*2];
            lblTitle.textColor = [self.view colorWithHexString:@[@"#000000",@"#BFBFBF"][i] alpha:1];
            lblTitle.numberOfLines = 0;
            [btn addSubview:lblTitle];
        }
        UILabel *lblTitle0 = (UILabel *)[self.view viewWithTag:200];
        UILabel *lblTitle1 = (UILabel *)[self.view viewWithTag:201];

        // 设置 Auto Layout 约束
        [NSLayoutConstraint activateConstraints:@[
                    // footerView 在父视图的位置（你原来希望的位置）
                    [tempView.topAnchor constraintEqualToAnchor:self.btnSubmit.bottomAnchor constant:20],
                    [tempView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
                    [tempView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
                    // lblTitle2 在 footerView 内
                    [lblTitle2.topAnchor constraintEqualToAnchor:tempView.topAnchor constant:20],
                    [lblTitle2.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:20],
                    [lblTitle2.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-20],
                    // btn 在 lblTitle2 下面
                    [btn.topAnchor constraintEqualToAnchor:lblTitle2.bottomAnchor constant:12],
                    [btn.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:20],
                    [btn.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-20],
                    // btn 的 bottom 约束决定 footerView 的底部，从而自动撑高
                    [btn.bottomAnchor constraintEqualToAnchor:tempView.bottomAnchor constant:-20],
                    // 内部元素约束：imgEmail 左侧，固定大小，垂直居中
                    [imgEmail.leadingAnchor constraintEqualToAnchor:btn.leadingAnchor constant:12],
                    [imgEmail.centerYAnchor constraintEqualToAnchor:btn.centerYAnchor],
                    [imgEmail.widthAnchor constraintEqualToConstant:36],
                    [imgEmail.heightAnchor constraintEqualToConstant:36],
                    // 右侧 copy 图标
                    [imgCopy.trailingAnchor constraintEqualToAnchor:btn.trailingAnchor constant:-12],
                    [imgCopy.centerYAnchor constraintEqualToAnchor:btn.centerYAnchor],
                    [imgCopy.widthAnchor constraintEqualToConstant:20],
                    [imgCopy.heightAnchor constraintEqualToConstant:20],
                    // lblTitle0: 在 imgEmail 右侧，靠近顶部
                    [lblTitle0.topAnchor constraintEqualToAnchor:btn.topAnchor constant:12],
                    [lblTitle0.leadingAnchor constraintEqualToAnchor:imgEmail.trailingAnchor constant:12],
                    [lblTitle0.trailingAnchor constraintLessThanOrEqualToAnchor:imgCopy.leadingAnchor constant:-12],
                    // lblTitle1: 在 lblTitle0 下面
                    [lblTitle1.topAnchor constraintEqualToAnchor:lblTitle0.bottomAnchor constant:4],
                    [lblTitle1.leadingAnchor constraintEqualToAnchor:lblTitle0.leadingAnchor],
                    [lblTitle1.trailingAnchor constraintLessThanOrEqualToAnchor:imgCopy.leadingAnchor constant:-12],
                    // 确保 btn 底部被子视图约束撑起（lblTitle1 与 imgEmail 的底部距离）
                    [lblTitle1.bottomAnchor constraintLessThanOrEqualToAnchor:btn.bottomAnchor constant:-12],
                    // 给 btn 一个最小高度（可选，保证触控目标）
                    [btn.heightAnchor constraintGreaterThanOrEqualToConstant:56]
                ]];
    }
    return _footerView;
}
- (void)handleEmailBtnTapped:(UIButton *)sender {
    // 复制到剪贴板
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    UILabel *lblTitle0 = (UILabel *)[self.view viewWithTag:200];
    pb.string = lblTitle0.text;

    NSString *str = NSLocalizedString(@"Copy successful",@"");
    [MBProgressHUD showLabel:str];
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
