//
//  AppDelegate.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate,UITabBarControllerDelegate>

@property (readonly, strong) NSPersistentCloudKitContainer *persistentContainer;
@property (strong, nonatomic) UITabBarController * tabBarController_startApp;
@property (strong, nonatomic) UIWindow * window;
- (void)setNavieationBarColor:(UINavigationController *)nav;
- (void)setTabBarController;
/// 根据当前选中 Tab 应用底部栏样式（视频 Tab 黑底白字，其它恢复默认）。
- (void)ytb_applyTabBarAppearanceForTabBarController:(UITabBarController *)tbc;
- (void)saveContext;
- (void)setAppViewController;
- (void)setAppLanguageEngin:(BOOL)isEngin;
//- (void)requestATTAndInitSDKSelectAgeGroup:(int)ageGroup;
@end

/*
 跳转到下标
 self.tabBarController.selectedIndex = 2;//切换tabbar
 self.navigationItem.title = @"导航固定标题"
 
 //动画
 [UIView animateWithDuration:0.3 animations:^{
 }];
 
 //主线程
 [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
 
 //倒计时
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
     });
 
 cell.selectionStyle = UITableViewCellSelectionStyleNone;//不能选中
 btn.titleEdgeInsets = UIEdgeInsetsMake(-15,0, 0, 0);//button偏移
 btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;//button文字左右对齐 右对齐
 
 View.clipsToBounds = YES;//子试图不能超出
 //UIKeyboardTypeDecimalPad// 带小数点
                           = UIKeyboardTypeDefault;  默认类型
  _txtAddress.keyboardType = UIKeyboardTypeNumberPad;//键盘类型 纯数字不带小数点  纯数字键盘
                           = UIKeyboardTypeDecimalPad;//带小数点
                           = UIKeyboardTypeNumbersAndPunctuation;// code之类
       = UIKeyboardTypeASCIICapable;//输入密码可以用这种，所有字符都有，不存在中文输入 默认是数字
 self.txtAccount.keyboardType = UIKeyboardTypeAlphabet; 字母键盘： 不包含中文输入 默认是字母
 
 //[self dismissViewControllerAnimated:YES completion:nil];//两种返回
  [self.navigationController popViewControllerAnimated:YES];
 
 _txtAmount.layer.cornerRadius = 2;//圆角
 _txtAmount.layer.masksToBounds = YES;
 [_txtAmount.layer setBorderWidth:0.5];//边框
 _txtAmount.layer.borderColor = MAIN_COLOR.CGColor;
 _tableView.scrollEnabled = NO;//不能滚
 //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;//箭头
 
 [self performSelectorOnMainThread:@selector(updateImage) withObject:nil waitUntilDone:NO];
 主线程
 
 CGSize labelSize = [self.lblContent sizeThatFits:CGSizeMake(SCREEN_WIDTH - 26,MAXFLOAT)];//字体宽度
 
 cell不复用
 MessageNotificationTableViewCell *cell = [[MessageNotificationTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];

 - (void)changeLanguage {
    self.title = kLocalizedTableString(@"about Us", @"HomeLocalizable");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeLanguage) name:ChangeLanguageNotificationName object:nil];
    [self changeLanguage];
 }

  - (void)loadNewMessage {
     NSMutableDictionary *params = [NSMutableDictionary dictionary];
     UserModel *model = [UserModelData sharedUserModelData].currentUserModel;
     params[@"token"] = model.token;
     params[@"lang"] = LANGUAGE_TYPE;
     params[@"app"] = APP_TYPE;
     [HttpTools postRequest:@"" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
         NSLog(@"data------------------------data--[%@]---------code-[%d]------msg=[%@]--------------------------",response.data,(int)response.code,response.message);
          if (success) {
 
         } else {
              [MBProgressHUD showLabel:response.message];
         }
     } failure:^(NSError * _Nonnull error) {
}];
- (void)loadNewMessage {
       NSMutableDictionary *params = [NSMutableDictionary dictionary];
       UserModel *model = [UserModelData sharedUserModelData].currentUserModel;
       params[@"token"] = model.token;
       params[@"lang"] = LANGUAGE_TYPE;
       params[@"app"] = APP_TYPE;
       [HttpTools ge1tRequest:@"" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
           if (success) {
                 NSLog(@"-7-get----data[%@]---7---------ms=[%@]---",response.data,response.message);
           } else {
              [MBProgressHUD showLabel:response.message];
            }
    } failure:^(NSError * _Nonnull error) {
    }];
 }
 
 //左右导航
 UIBarButtonItem *barButReturn = [[UIBarButtonItem alloc]initWithCustomView:btnReturn];
 self.navigationItem.leftBarButtonItem = barButReturn;
 //返回键盘
 self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@""] style:(UIBarButtonItemStylePlain) target:self action:nil];

 */

/*
 终端使用命令$ chmod 644 文件名 就会变回正常的了
 终端使用命令$ chmod 700 文件名 就会变回exec格式

原生字体
PingFangSC-Medium
PingFangSC-Semibold
PingFangSC-Light
PingFangSC-Ultralight
PingFangSC-Regular
PingFangSC-Thin
*/

/*
 //不同字体颜色
 self.lblTitle.textColor = MAIN_COLOR;
 NSString *str1 = @"";
 NSString *str2 = @"";
 NSString *content = [NSString stringWithFormat:@"%@ %@",str1,str2];
 
 NSMutableAttributedString *noteStr = [[NSMutableAttributedString alloc] initWithString:content];
 [noteStr  addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0,2)];
 [noteStr  addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:30]  range:NSMakeRange(0,str1.length)];

 self.lblTitle.attributedText = noteStr;
 // 使用三元运算符来决定是否可以访问
 BOOL canAccess = (age > 18) ? YES : NO;
 */


/*
 MyNewsViewController *myNewsVC = [MyNewsViewController new];
 myNewsVC.hidesBottomBarWhenPushed = YES;
 [self.navigationController pushViewController:myNewsVC animated:YES];
 //[self dismissViewControllerAnimated:YES completion:nil];//两种返回
 //[self.navigationController popViewControllerAnimated:YES];
 */

//系统自动字体打印
/*NSArray *familyNames = [UIFont familyNames];
 for (NSString *familyName in familyNames) {
     NSLog(@"Font Family: 【%@】=============111-----------", familyName);
     NSArray *fontNames = [UIFont fontNamesForFamilyName:familyName];
     for (NSString *fontName in fontNames) {
         NSLog(@"\tFont: 【%@】=============22---------", fontName);
     }
 }*/


/*
 // 创建一个通知
 //[[NSNotificationCenter defaultCenter] postNotificationName:@"MyNotification" object:@{@"tongzhi":@"1"}];
 // 移除观察者
 //[[NSNotificationCenter defaultCenter] removeObserver:self];
 //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"MyNotification" object:nil];
 //-----------------------------------------------------------------------
 // 订阅通知
 [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(handleMyNotification:)
                                              name:@"MyNotification"
                                            object:nil];
- (void)handleMyNotification:(NSNotification *)notification {// 6
    NSDictionary *dic = (NSDictionary *)[notification object];
    NSString *tongzhi = dic[@"tongzhi"];//1 0
 //活动指示器转转
 [MBProgressHUD showSuccess:@"成功"];
 [MBProgressHUD showError:@"错误"];
 [MBProgressHUD showLabel:msg];
 [MBProgressHUD showMessage:@"正在提交"];
 [MBProgressHUD hideHUD];
 */


/*
 //活动指示器转转
 [MBProgressHUD showSuccess:@"成功"];
 [MBProgressHUD showError:@"错误"];
 [MBProgressHUD showLabel:msg];
 [MBProgressHUD showMessage:@"正在提交"];
 [MBProgressHUD hideHUD];
 
 //----------------------------------------------------------
 //----------------------------------------------------------

 
 */
