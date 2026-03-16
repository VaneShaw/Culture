//
//  MBProgressHUD+UMEYE.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "MBProgressHUD+Show.h"

@implementation MBProgressHUD (Show)
/**
*  显示信息
*
*  @param message 信息内容
*  @param icon 图标
*  @param view 显示的视图
*/
+ (void)show:(NSString *)message icon:(NSString *)icon view:(UIView *)view
{
    // 快速显示一个提示信息
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:(view==nil)?keyWindow:view animated:YES];
        hud.minSize=CGSizeMake(100, 100);
    
        hud.contentColor = [UIColor whiteColor];
        hud.bezelView.backgroundColor = [UIColor blackColor];
        hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        hud.bezelView.color  = [hud colorWithHexString:@"#242C32" alpha:1];
        
        // 设置图片
        UIImageView *imageView= [[UIImageView alloc] initWithImage:[UIImage imageNamed:icon]];
        imageView.frame=CGRectMake(0, 0, 37, 37);
        hud.customView =imageView;
        hud.detailsLabel.text = message;
        hud.detailsLabel.font = [UIFont systemFontOfSize:14.f];
        // 再设置模式
        hud.mode = MBProgressHUDModeCustomView;
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = YES;
        // 0.7秒之后再消失
        [hud hideAnimated:YES afterDelay:1.4];
    });
}

/**
 *  显示成功信息
 *
 *  @param success 信息内容
 */
+ (void)showSuccess:(NSString *)success
{
    [self showSuccess:success toView:nil];
}

/**
 *  显示成功信息
 *
 *  @param success 信息内容
 *  @param view    显示信息的视图
 */
+ (void)showSuccess:(NSString *)success toView:(UIView *)view
{
    [self show:success icon:@"MBProgressHUD.bundle/success@2x.png" view:view];
}

/**
 *  显示错误信息
 *
 */
+ (void)showError:(NSString *)error
{
    [self showError:error toView:nil];
}

/**
 *  显示错误信息
 *
 *  @param error 错误信息内容
 *  @param view  需要显示信息的视图
 */
+ (void)showError:(NSString *)error toView:(UIView *)view{
    [self show:error icon:@"MBProgressHUD.bundle/error@2x.png" view:view];
}
+ (void)showSuccess:(NSString *)success afterDelay:(NSTimeInterval)delay{
    // 快速显示一个提示信息
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:keyWindow animated:YES];
        hud.minSize=CGSizeMake(100, 100);
        hud.contentColor = [UIColor whiteColor];
        hud.bezelView.backgroundColor = [UIColor blackColor];
        hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        hud.bezelView.color  = [hud colorWithHexString:@"#242C32" alpha:1];
       
        // 设置图片
        UIImageView *imageView= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MBProgressHUD.bundle/success@2x.png"]];
        imageView.frame=CGRectMake(0, 0, 37, 37);
        hud.customView =imageView;
        hud.detailsLabel.text = success;
        hud.detailsLabel.font=[UIFont systemFontOfSize:14.f];
        // 再设置模式
        hud.mode = MBProgressHUDModeCustomView;
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = YES;
        // 0.7秒之后再消失
        [hud hideAnimated:YES afterDelay:delay];
    });
}
+ (void)showError:(NSString *)error afterDelay:(NSTimeInterval)delay{
    // 快速显示一个提示信息
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:keyWindow animated:YES];
        hud.minSize=CGSizeMake(100, 100);
        
        hud.contentColor = [UIColor whiteColor];
        hud.bezelView.backgroundColor = [UIColor blackColor];
        hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        hud.bezelView.color  = [hud colorWithHexString:@"#242C32" alpha:1];
        
        // 设置图片
        UIImageView *imageView= [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MBProgressHUD.bundle/error@2x.png"]];
        imageView.frame=CGRectMake(0, 0, 37, 37);
        hud.customView =imageView;
        hud.detailsLabel.text = error;
        
        hud.detailsLabel.font=[UIFont systemFontOfSize:14.f];
        // 再设置模式
        hud.mode = MBProgressHUDModeCustomView;
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = YES;
        // 0.7秒之后再消失
        [hud hideAnimated:YES afterDelay:delay];
    });
}
/**
 *  显示错误信息
 *
 *  @param message 信息内容
 */
+ (void)showMessage:(NSString *)message
{
    [self showMessage:message toView:nil];
}

/**
 *  显示一些信息
 *
 *  @param message 信息内容
 *  @param view    需要显示信息的视图
 
 */
+ (void)showMessage:(NSString *)message toView:(UIView *)view {
    // 快速显示一个提示信息
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:(view==nil)?keyWindow:view animated:YES];
        hud.contentColor = [UIColor whiteColor];
        hud.bezelView.backgroundColor = [UIColor blackColor];
        hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        hud.bezelView.color  = [hud colorWithHexString:@"#242C32" alpha:1];
        hud.detailsLabel.text = message;
        hud.detailsLabel.font=[UIFont systemFontOfSize:14.f];
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = YES;
    });
}
+ (void)showLabel:(NSString *)text{
    [self showLabel:text toView:nil];
}
+ (void)showLabel:(NSString *)text toView:(UIView *)view {
    // 快速显示一个提示信息
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:(view==nil)?keyWindow:view animated:YES];
        hud.contentColor = [UIColor whiteColor];

        //hud.bezelView.style = MBProgressHUDBackgroundStyleBlur;
        hud.bezelView.backgroundColor = [UIColor blackColor];
        hud.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        hud.bezelView.color = [hud colorWithHexString:@"#242C32" alpha:1];
        hud.detailsLabel.text = text;
        hud.mode=MBProgressHUDModeText;
        hud.detailsLabel.font=[UIFont systemFontOfSize:14.f];
        // 隐藏时候从父控件中移除
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES afterDelay:3.0];
    });
}
/**
 *  手动关闭MBProgressHUD
 */
+ (void)hideHUD
{
    [MBProgressHUD hideHUDForView:nil];
}
/**
 *  手动关闭MBProgressHUD
 *
 *  @param view    显示MBProgressHUD的视图
 */
+ (void)hideHUDForView:(UIView *)view
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
        [self hideHUDForView:(view==nil)?keyWindow:view animated:YES];
    });
}
@end
