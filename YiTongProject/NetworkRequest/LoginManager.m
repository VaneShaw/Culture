//
//  LoginManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/27.
//

#import "LoginManager.h"
#import "UserModel.h"
#import "PhoneLoginViewController.h"

@implementation LoginManager
+ (instancetype)sharedManager {
    static LoginManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[LoginManager alloc] init];
    });
    return manager;
}
- (void)handleLoginExpiredWithCompletion:(void (^)(void))completion {

    UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
    UIViewController *rootVC = keyWindow.rootViewController;
    // 判断是否已经是登录页
    UIViewController *presentedVC = rootVC.presentedViewController;
    if ([presentedVC isKindOfClass:[LoginViewController class]]) {
        return; // 已经在登录页，不需要再次跳转
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        //self.currentLoginVC.tabBarController.selectedIndex = 0;
        __weak typeof(self) weakSelf = self;
    
        if(IS_OVERSEAS_VERSION){
            LoginViewController *loginVC = [[LoginViewController alloc] init];
            loginVC.isCurrent = YES;
            self.currentLoginVC = loginVC;
            // 登录完成回调
            loginVC.loginCompletion = ^{
                weakSelf.isHandlingLogin = NO;
                weakSelf.currentLoginVC = nil;
                if (completion) {
                        completion();
                    }
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
            nav.modalPresentationStyle = 0;
            [rootVC presentViewController:nav animated:YES completion:nil];
            
        } else {
            
            PhoneLoginViewController *loginVC = [[PhoneLoginViewController alloc] init];
            loginVC.isCurrent = YES;
            self.currentLoginVC = loginVC;
            // 登录完成回调
            loginVC.loginCompletion = ^{
                if (completion) {
                        completion();
                    }
                //weakSelf.isHandlingLogin = NO;
                //weakSelf.currentLoginVC = nil;
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
            nav.modalPresentationStyle = 0;
            [rootVC presentViewController:nav animated:YES completion:nil];
        }
    });
    
}
- (void)handleLoginExpired {
    //if (self.isHandlingLogin) {
        //return; // 已经在处理，不重复触发
    //}
    // 获取根控制器
    //UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
    UIViewController *rootVC = keyWindow.rootViewController;

    // 判断是否已经是登录页
    UIViewController *presentedVC = rootVC.presentedViewController;
    if ([presentedVC isKindOfClass:[LoginViewController class]]) {
        return; // 已经在登录页，不需要再次跳转
    }

    // 标记正在处理
    self.isHandlingLogin = YES;
    [[UserModel sharedInstance] logout];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentLoginVC.tabBarController.selectedIndex = 0;
        __weak typeof(self) weakSelf = self;
        //PhoneLoginViewController *phoneVc = [[PhoneLoginViewController alloc] init];
        if(IS_OVERSEAS_VERSION){
            LoginViewController *loginVC = [[LoginViewController alloc] init];
            self.currentLoginVC = loginVC;
            // 登录完成回调
            loginVC.loginCompletion = ^{
                weakSelf.isHandlingLogin = NO;
                weakSelf.currentLoginVC = nil;
            };
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
            nav.modalPresentationStyle = 0;
            [rootVC presentViewController:nav animated:YES completion:nil];
            
        } else {
            
            PhoneLoginViewController *loginVC = [[PhoneLoginViewController alloc] init];
            self.currentLoginVC = loginVC;
            // 登录完成回调
            //loginVC.loginCompletion = ^{
                //weakSelf.isHandlingLogin = NO;
                //weakSelf.currentLoginVC = nil;
            //};
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
            nav.modalPresentationStyle = 0;
            [rootVC presentViewController:nav animated:YES completion:nil];
        }
    });
}
+ (BOOL)checkLoginAndPresentIfNeededFrom:(UIViewController *)vc {
    if ([[UserModel sharedInstance] isLogin]) {
        return YES;
    }
    // 已在登录流程中则不再叠一层（含 Nav 包一层的情况）
    UIViewController *p = vc.presentedViewController;
    while (p) {
        if ([p isKindOfClass:[UINavigationController class]]) {
            UIViewController *root = [(UINavigationController *)p viewControllers].firstObject;
            if ([root isKindOfClass:[LoginViewController class]] || [root isKindOfClass:[PhoneLoginViewController class]]) {
                return NO;
            }
        }
        p = p.presentedViewController;
    }
    UINavigationController *nav = nil;
    if (IS_OVERSEAS_VERSION) {
        LoginViewController *loginVC = [[LoginViewController alloc] init];
        nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    } else {
        PhoneLoginViewController *loginVC = [[PhoneLoginViewController alloc] init];
        nav = [[UINavigationController alloc] initWithRootViewController:loginVC];
    }
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [vc presentViewController:nav animated:YES completion:nil];
    return NO;
}

@end
