//
//  MBProgressHUD+UMEYE.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "MBProgressHUD.h"

@interface MBProgressHUD (Show)
+ (void)showSuccess:(NSString *)success;
+ (void)showSuccess:(NSString *)success toView:(UIView *)view;
+ (void)showError:(NSString *)error;
+ (void)showError:(NSString *)error toView:(UIView *)view;
+ (void)showError:(NSString *)error afterDelay:(NSTimeInterval)delay;
+ (void)showSuccess:(NSString *)success afterDelay:(NSTimeInterval)delay;
+ (void)showMessage:(NSString *)message;
+ (void)showLabel:(NSString *)text;
+ (void)showMessage:(NSString *)message toView:(UIView *)view;
+ (void)hideHUD;
+ (void)hideHUDForView:(UIView *)view;
@end

//提示语message
/*//活动指示器转转
[MBProgressHUD showSuccess:@"成功"];
[MBProgressHUD showError:@"错误"];
[MBProgressHUD showLabel:msg];
[MBProgressHUD showMessage:@"正在提交"];
[MBProgressHUD hideHUD];*/
