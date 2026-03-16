//
//  NicknameViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/16.
//

#import "NicknameViewController.h"

@interface NicknameViewController ()<UIGestureRecognizerDelegate,UINavigationControllerDelegate,UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *dataArray;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UIView *footerView;
@property (strong, nonatomic) UILabel *lblNumber;
@property (strong, nonatomic) UITextField *txtField;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *tempname;
@end

@implementation NicknameViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.delegate = self;
    [self.view addSubview:self.tableView];
    
    [self addGlobalBackButtonColor:[self.view colorWithHexString:@"#F8F8F8" alpha:1] headerTitleDic:@{@"title":@"Change Nickname",@"color":@"#1F1F39"}];
    
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
    NSDictionary *dicUser = [KUSER_DEFAULT objectForKey:@"user_info_key"];
    self.username = [NSString stringWithFormat:@"%@",dicUser[@"username"]];
    self.tempname = [NSString stringWithFormat:@"%@",dicUser[@"username"]];
    UIButton *btnDone = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnDone.frame = CGRectMake(SCREEN_WIDTH - 108, statusBarH, 83, navigationBarHeight);
    btnDone.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [btnDone setTitle:NSLocalizedString(@"Done",@"") forState:UIControlStateNormal];
    btnDone.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
    [btnDone setTitleColor:[self.view colorWithHexString:@"#4C9BEF" alpha:1] forState:UIControlStateNormal];
    [btnDone addTarget:self action:@selector(btnDoneAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnDone];
    

    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = self.footerView;
}

- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 150)];//410
        _headerView.backgroundColor = [UIColor whiteColor];
 
        UITextField *txtField = [[UITextField alloc]init];
        txtField.translatesAutoresizingMaskIntoConstraints = NO;
        txtField.font = [UIFont fontWithName:FONT_NAME_Medium size:15];
        txtField.backgroundColor = [self.view colorWithHexString:@"#F8F8F8" alpha:1];
        txtField.layer.cornerRadius = 12;//圆角
        txtField.layer.masksToBounds = YES;
        txtField.delegate = self;
        txtField.textColor = BLACK_COLOR_1F;
        //txtField.keyboardType = UIKeyboardTypeNumberPad;
        txtField.leftView = [[UIView alloc]initWithFrame:CGRectMake(0,0,12,0)];
        txtField.leftViewMode= UITextFieldViewModeAlways;
        [_headerView addSubview:txtField];
        //nickname_delete
        self.txtField = txtField;
        txtField.text = self.username;
  
        UIColor *color = [self.view colorWithHexString:@"#BFBFBF" alpha:1];
        txtField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Please enter a nickname",@"")  attributes:@{NSForegroundColorAttributeName: color}];
        [txtField addTarget:self
                         action:@selector(textFieldTextDidChange:)
               forControlEvents:UIControlEventEditingChanged];

        //===============================================
        UIView *rightContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 35, 30)];
        // 30(btn) + 5(右边距)
        UIButton *clearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [clearBtn setImage:[UIImage imageNamed:@"nickname_delete"]
                  forState:UIControlStateNormal];
        clearBtn.frame = CGRectMake(0, 0, 30, 30);
        [clearBtn addTarget:self
                     action:@selector(clearNickname)
           forControlEvents:UIControlEventTouchUpInside];
        [rightContainer addSubview:clearBtn];
        self.txtField.rightView = rightContainer;
        self.txtField.rightViewMode = UITextFieldViewModeWhileEditing;
        self.txtField.rightViewMode = UITextFieldViewModeAlways; // 将 WhileEditing 改为 Always

        //self.txtField.rightView.hidden = YES;
        //================================================
  
        UILabel *lblTitle = [[UILabel alloc]init];
        lblTitle.text = NSLocalizedString(@"3-24 characters. Letters and numbers only.",@"") ;
        lblTitle.textAlignment = NSTextAlignmentLeft;
        lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
        lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        lblTitle.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
        [_headerView addSubview:lblTitle];

      
        
        UILabel *lblNumber = [[UILabel alloc]init];
        //lblNumber.text = [NSString stringWithFormat:@"0/%d",maxLength];
        lblNumber.textAlignment = NSTextAlignmentRight;
        lblNumber.translatesAutoresizingMaskIntoConstraints = NO;
        lblNumber.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        lblNumber.textColor = [self.view colorWithHexString:@"#BFBFBF" alpha:1];
        [_headerView addSubview:lblNumber];
        self.lblNumber = lblNumber;
        
        int maxLength = 24;
        if(!IS_OVERSEAS_VERSION){
            maxLength = 15;
        }
        self.lblNumber.text = [NSString stringWithFormat:@"%lu/%ld",
                               (unsigned long)txtField.text.length,
                               (long)maxLength];

        // 设置 Auto Layout 约束
        [NSLayoutConstraint activateConstraints:@[
            [txtField.topAnchor constraintEqualToAnchor:_headerView.safeAreaLayoutGuide.topAnchor constant:44],
            [txtField.leadingAnchor constraintEqualToAnchor:_headerView.leadingAnchor constant:20],
            [txtField.trailingAnchor constraintEqualToAnchor:_headerView.trailingAnchor constant:-20],
            [txtField.heightAnchor constraintEqualToConstant:52],
            
            // 字数统计标签约束
            [lblTitle.topAnchor constraintEqualToAnchor:txtField.bottomAnchor constant:12],
            [lblTitle.leadingAnchor constraintEqualToAnchor:_headerView.leadingAnchor constant:25],
            [lblTitle.heightAnchor constraintEqualToConstant:18],
            
            // 字数统计标签约束
            [lblNumber.topAnchor constraintEqualToAnchor:txtField.bottomAnchor constant:12],
            [lblNumber.trailingAnchor constraintEqualToAnchor:_headerView.trailingAnchor constant:-25],
            [lblNumber.heightAnchor constraintEqualToConstant:18]
        ]];
    }
    return _headerView;
}
- (UIView *)footerView {
    if (!_footerView) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 150)];
        _footerView.backgroundColor = [UIColor whiteColor];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self
                                              action:@selector(dismissKeyboard)];
        tapGesture.cancelsTouchesInView = NO; // 重要：不影响其他触摸事件
        [_footerView addGestureRecognizer:tapGesture];
    }
    return _footerView;
}
- (void)dismissKeyboard {
    [self.txtField resignFirstResponder];
}

- (void)clearNickname {
    self.txtField.text = @"";
    
    int maxLength = 24;
    if(!IS_OVERSEAS_VERSION){
        maxLength = 15;
    }
    self.lblNumber.text = [NSString stringWithFormat:@"0/%d",maxLength];
    self.txtField.rightView.hidden = YES;
}
- (void)btnDoneAction:(UIButton *)sender{

    if(self.txtField.text.length == 0){
        NSString *message = NSLocalizedString(@"Please enter a nickname",@"");
        [MBProgressHUD showLabel:message];
        return;
    }
    if(self.txtField.text.length < (2 + IS_OVERSEAS_VERSION)){
        NSString *message = NSLocalizedString(@"At least 3 characters required",@"");
        [MBProgressHUD showLabel:message];
        return;
    }
    if([self.txtField.text isEqualToString:self.tempname]){
        NSString *message = NSLocalizedString(@"This name is already taken",@"");
        [MBProgressHUD showLabel:message];
        return;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    params[@"username"] =self.txtField.text;
    [HttpTools postRequest:@"/user/updateUserInfo" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {

         if (success) {
             NSDictionary *dicUser = [NSDictionary dictionaryWithDictionary:response.data];
             NSLog(@"------dic------cc--[%@]--------ddd",dicUser);
             NSString *username = [NSString stringWithFormat:@"%@",dicUser[@"username"]];
             self.username = username;
             
             
             
             //======================================
             NSDictionary *dicTemp = [KUSER_DEFAULT objectForKey:@"user_info_key"];
             NSMutableDictionary *mutableDicUser = [dicUser mutableCopy];// 将 dicUser 转换为可变字典，以便修改
             // 检查 dicTemp 中的每个键，如果 dicUser 中没有该键，则从 dicTemp 中复制过来
             [dicTemp enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                 if (![mutableDicUser objectForKey:key]) {
                     [mutableDicUser setObject:obj forKey:key];
                 }
             }];
             [KUSER_DEFAULT setObject:mutableDicUser forKey:@"user_info_key"];
             //======================================
             /*
              uid
              username
              avatar
              email
              */
             //self.username = self.txtField.text;
             if (self.selectedUserNickname) {
                 self.selectedUserNickname(self.username); // 传回选择的用户昵称
             }
             
             [self.navigationController popViewControllerAnimated:YES];
         } else {
             [MBProgressHUD showLabel:response.msg];
         }
    } failure:^(NSError * _Nonnull error) {
    }];
}
//点击空白回收键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.footerView endEditing:YES];
}
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder]; // 回收键盘
    return YES;
}
- (UITableView *)tableView {
    if (!_tableView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGFloat navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
        CGRect frame =  CGRectMake(0, statusBarH + navigationBarHeight , SCREEN_WIDTH, SCREEN_HEIGHT - statusBarH - navigationBarHeight);
        _tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.sectionFooterHeight = CGFLOAT_MIN;
        _tableView.sectionHeaderHeight = CGFLOAT_MIN;
        _tableView.userInteractionEnabled = YES;
        _tableView.scrollEnabled = NO;
        self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        //_tableView.backgroundColor = [self.view colorWithHexString:@"#F5F9FF" alpha:1];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
   if (cell == nil){
       cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
   }

   return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 76;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
  
}

- (void)textFieldTextDidChange:(UITextField *)textField {

    // 中文拼音联想阶段，不截断
    if (textField.markedTextRange) return;

    NSInteger maxLength = IS_OVERSEAS_VERSION ? 24 : 15;

    NSString *text = textField.text ?: @"";

    // 超长则截断（不会破坏拼音输入）
    if (text.length > maxLength) {
        text = [text substringToIndex:maxLength];
        textField.text = text;
    }

    // 更新 UI
    self.lblNumber.text = [NSString stringWithFormat:@"%lu/%ld",
                           (unsigned long)text.length,
                           (long)maxLength];

    textField.rightView.hidden = (text.length == 0);
}
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {

    // 🔑 中文输入法联想阶段，必须放行
    if (textField.markedTextRange) {
        return YES;
    }

    // 根据区域判断最大长度

    NSInteger maxLength = 24;
    if(!IS_OVERSEAS_VERSION){
        maxLength = 15;
    }
    
    NSString *newText =
    [textField.text stringByReplacingCharactersInRange:range
                                             withString:string];

    // 超出长度则禁止
    return newText.length <= maxLength;
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
