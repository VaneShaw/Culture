//
//  UserinfoViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/16.
//

#import "UserinfoViewController.h"
#import "NicknameViewController.h"
#import "YTAvatarPickerManager.h"
@interface UserinfoViewController ()<UIGestureRecognizerDelegate,UINavigationControllerDelegate,UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *dataArray;
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UIView *footerView;

@property (strong, nonatomic) UIButton *btnAvatar;
@property (strong, nonatomic) UIImageView *imgAvatar;
@property (strong, nonatomic) UILabel *lblNickname;
@end

@implementation UserinfoViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillDisappear:animated];
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
    self.dataArray = @[@"Nickname",@"Email11",@"App Language"];
    [self addGlobalBackButtonColor:[self.view colorWithHexString:@"#F8F8F8" alpha:1] headerTitleDic:@{@"title":@"Edit Profile",@"color":@"#1F1F39"}];
    [self.view addSubview:self.tableView];
    self.tableView.tableHeaderView = self.headerView;
    self.tableView.tableFooterView = self.footerView;
    
}
- (UIView *)headerView {
    if (!_headerView) {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 170)];//410
        _headerView.backgroundColor = [UIColor whiteColor];

        [_headerView addSubview:self.imgAvatar];
        [_headerView addSubview:self.btnAvatar];
        int width = self.imgAvatar.frame.size.width;
        UIImageView *camera = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - width)/2 + 73, _imgAvatar.frame.origin.y + 73, 30, 30)];
        camera.image = [UIImage imageNamed:@"camera_black"];
        camera.userInteractionEnabled = NO;
        [_headerView addSubview:camera];
     
//        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleAvatarTap:)];
//        [self.imgAvatar addGestureRecognizer:tapGesture];
    }
    return _headerView;
}
//- (void)handleAvatarTap:(UITapGestureRecognizer *)gesture {
- (void)btnAvatarAction:(UIButton *)sender {
    [[YTAvatarPickerManager shared]
     pickAvatarFrom:self
     completion:^(UIImage *avatar, BOOL success) {
         if (success) {

             NSMutableArray *array = [NSMutableArray arrayWithArray:@[avatar]];
             NSMutableDictionary *params = [NSMutableDictionary dictionary];
             params = [LanguageHelper currentLanguageParams:params];
             
             //NSLog(@"------11------cc--[%@]--------ddd",params);
             [HttpTools uploadImageWithURL:@"/user/uploadAvatar" images:array params:params imageParamsName:@"avatar" success:^(BaseDataModel * _Nonnull result) {
                 if(result.successs){
                     self.imgAvatar.image = avatar;
                     //NSLog(@"------00------cc--[%@]--------ddd",result.data);
                     NSDictionary *dicUser = [NSDictionary dictionaryWithDictionary:result.data];
                     NSString *avatar = [NSString stringWithFormat:@"%@",dicUser[@"avatar"]];
                     
                     // avatar = "https://testoss.shiyi-yitong.com/user_avatar_7642a9dc1b.jpg";
                     /*
                      uid
                      username
                      avatar
                      email
                      */
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
                     if (self.selectedUserNickname) {
                         self.selectedUserNickname(avatar); // 传回选择的用户昵称
                     }
                 } else {
                     [MBProgressHUD showLabel:result.msg];
                 }
                } failure:^(NSError * _Nonnull error) {
                    //NSLog(@"------33------cc--[%@]--------error",error);
                }] ;

         }
     }];
}
- (UIView *)footerView {//right_black
    if (!_footerView) {
        int height = 52;
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 52 * self.dataArray.count)];//410
        _footerView.backgroundColor = [UIColor whiteColor];
        
        NSDictionary *dicUser = [KUSER_DEFAULT objectForKey:@"user_info_key"];
        NSString *username = [NSString stringWithFormat:@"%@",dicUser[@"username"]];
        NSString *area = @[@"简体中文",@"English"][IS_OVERSEAS_VERSION];
        NSString *strEmail = @[[[UserModel sharedInstance] mobile],[[UserModel sharedInstance] email]][IS_OVERSEAS_VERSION];
        strEmail = [self maskEmail:strEmail];
        
        NSArray *infoArray = @[username,strEmail,area];
  
        for (int i = 0; i < self.dataArray.count; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            NSString *title = NSLocalizedString(self.dataArray[i],@"");
           
            [btn setTitle:title forState:UIControlStateNormal];
            btn.frame = CGRectMake(0, height * i, SCREEN_WIDTH, height);
            [btn setTitleColor:[self.view colorWithHexString:@"#63637D" alpha:1] forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
            btn.titleEdgeInsets = UIEdgeInsetsMake(0,30, 0, 0);//button偏移
            btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            [_footerView addSubview:btn];
            
            UIView *line = [[UIView alloc]initWithFrame:CGRectMake(30, height-1, SCREEN_WIDTH - 60, 1)];
            line.backgroundColor = [self.view colorWithHexString:@"#F8F8F8" alpha:1];
            [btn addSubview:line];
            BOOL isFirst = i == 0 ? YES:NO;
            UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 250 - 30 - 17 * isFirst, 0, 250, height)];
            lblTitle.textAlignment = NSTextAlignmentRight;
            lblTitle.textColor = [self.view colorWithHexString:@"#1F1F39" alpha:1];
            lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
            lblTitle.text = infoArray[i];
          
            [btn addSubview:lblTitle];
            
            if(isFirst){
                self.lblNickname = lblTitle;
                UIImageView *right = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH - 23 - 20, (height - 20)/2, 20, 20)];
                right.image = [UIImage imageNamed:@"right_black"];
                [btn addSubview:right];
                [btn addTarget:self action:@selector(btnNicknameAction:) forControlEvents:UIControlEventTouchUpInside];
            }
        }
    }
    return _footerView;
}
- (void)btnNicknameAction:(UIButton *)sender {
    NicknameViewController *vc = [NicknameViewController new];
    [self.navigationController pushViewController:vc animated:YES];
    vc.selectedUserNickname = ^(NSString *nickname) {
        NSLog(@"用户选择了昵称为: %@ 的用户", nickname);
        // 处理选择的用户昵称
        self.lblNickname.text = nickname;
        if (self.selectedUserNickname) {
            self.selectedUserNickname(nickname); // 传回选择的用户昵称
        }
    };
}
- (UIButton *)btnAvatar {
    if(!_btnAvatar){
        int width = 150;
        _btnAvatar = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnAvatar.frame = CGRectMake((SCREEN_WIDTH - width)/2, 20, width, width);
        [_btnAvatar addTarget:self action:@selector(btnAvatarAction:) forControlEvents:UIControlEventTouchUpInside];
        _btnAvatar.backgroundColor = [UIColor clearColor];
    }
    return _btnAvatar;
}
- (UIImageView *)imgAvatar {
    if(!_imgAvatar){
        int width = 100;
        _imgAvatar = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - width)/2, 40, width, width)];
        _imgAvatar.layer.cornerRadius = width/2;//圆角
        _imgAvatar.layer.masksToBounds = YES;
        _imgAvatar.layer.borderWidth = 2;  //边框
        _imgAvatar.layer.borderColor = [self.view colorWithHexString:@"#F1F9FF" alpha:1].CGColor;
        _imgAvatar.userInteractionEnabled = NO;

        NSDictionary *dicUser = [KUSER_DEFAULT objectForKey:@"user_info_key"];
        NSString *avatar = [NSString stringWithFormat:@"%@",dicUser[@"avatar"]];
        [_imgAvatar sd_setImageWithURL:[NSURL URLWithString:avatar]];
    }
    return _imgAvatar;
}

//- (void)btnLogout {
//    NSMutableDictionary *params = [NSMutableDictionary dictionary];
//    params = [LanguageHelper currentLanguageParams:params];
//    [HttpTools postRequest:@"/auth/logout" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
//        [MBProgressHUD showLabel:response.msg];
//         if (success) {
//        }
//    } failure:^(NSError * _Nonnull error) {
//    }];
//}
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
        _tableView.backgroundColor = [self.view colorWithHexString:@"#F5F9FF" alpha:1];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        //_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;  // 设置分割线颜色
        //[self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 15, 0, 15)];
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
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
   return cell;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 10;
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
- (NSString *)maskEmail:(NSString *)email {
    
    if(IS_OVERSEAS_VERSION){
        if (!email || email.length == 0) {
            return email;
        }
        NSRange atRange = [email rangeOfString:@"@"];
        if (atRange.location == NSNotFound) {
            return email;
        }
        NSString *prefix = [email substringToIndex:atRange.location];
        NSString *suffix = [email substringFromIndex:atRange.location];
        
        // 处理前缀部分
        if (prefix.length <= 4) {
            // 创建指定数量的星号字符串
            NSMutableString *asterisks = [NSMutableString string];
            for (NSInteger i = 0; i < prefix.length; i++) {
                [asterisks appendString:@"*"];
            }
            return [NSString stringWithFormat:@"%@%@", asterisks, suffix];
        } else {
            // 保留前2位和后2位，中间用4个*替换
            NSString *firstPart = [prefix substringToIndex:2];
            NSString *lastPart = [prefix substringFromIndex:prefix.length - 2];
            return [NSString stringWithFormat:@"%@****%@%@", firstPart, lastPart, suffix];
        }
        
    } else {
        
        NSString *phone = email;
        if (!phone || phone.length < 7) {
            return phone; // 长度不够，不处理
        }
        NSString *firstPart = [phone substringToIndex:3];       // 前3位
        NSString *lastPart = [phone substringFromIndex:7];      // 后4位
        return [NSString stringWithFormat:@"%@****%@", firstPart, lastPart];
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
