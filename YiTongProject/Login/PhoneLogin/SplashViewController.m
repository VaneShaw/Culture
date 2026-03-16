//
//  SplashViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/16.
//

#import "SplashViewController.h"

@interface SplashViewController ()
@property (nonatomic, strong) UIImageView *imgTitle;
@property (nonatomic, strong) UIImageView *imgLogo;
@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 设置背景色或通用背景图
       self.view.backgroundColor = [UIColor whiteColor];
       UIImageView *bgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
       //bgView.image = [UIImage imageNamed:@"LaunchBackground_Universal"];
       bgView.contentMode = UIViewContentModeScaleAspectFill;
       [self.view addSubview:bgView];
       
       // 获取系统语言
       //NSString *language = [NSLocale preferredLanguages].firstObject;
       //BOOL isChinese = [language hasPrefix:@"zh"];
       
       UIImage *image0 = [UIImage imageNamed:@[@"LaunchTitle_cn",@"LaunchTitle_en"][IS_OVERSEAS_VERSION]];
       self.imgTitle = [[UIImageView alloc] init];
       self.imgTitle.translatesAutoresizingMaskIntoConstraints = NO;
       self.imgTitle.contentMode = UIViewContentModeScaleAspectFit;
       self.imgTitle.alpha = 0; // 动画初始透明
       self.imgTitle.image = image0;
       [self.view addSubview:self.imgTitle];
       self.imgTitle.frame = CGRectMake((SCREEN_WIDTH-image0.size.width)/2, (SCREEN_HEIGHT-image0.size.height)/2 - image0.size.height/3  - 10, image0.size.width, image0.size.height);
       
       // Slogan
       UIImage *image1 = [UIImage imageNamed:@[@"LaunchLogo_cn",@"LaunchLogo_en"][IS_OVERSEAS_VERSION]];
       self.imgLogo = [[UIImageView alloc] init];
       self.imgLogo.translatesAutoresizingMaskIntoConstraints = NO;
       self.imgLogo.contentMode = UIViewContentModeScaleAspectFit;
       self.imgLogo.alpha = 0; // 动画初始透明
       self.imgLogo.image = image1;
       [self.view addSubview:self.imgLogo];
        CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height;
       self.imgLogo.frame = CGRectMake((SCREEN_WIDTH-image1.size.width)/2, SCREEN_HEIGHT - image1.size.height - tabBarHeight - 30, image1.size.width, image1.size.height);
       // Auto Layout 
       
       // 淡入动画
       [UIView animateWithDuration:0.5 animations:^{
           self.imgTitle.alpha = 1;
           self.imgLogo.alpha = 1;
       }];
       
       // 延时跳转主页面
       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
           [self goToMainPage];
       });
}

- (void)goToMainPage {
    // 切换到主页面
    // 例如使用Storyboard ID
    //UIViewController *mainVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MainViewController"];
    //self.view.window.rootViewController = mainVC;
    [theAppDelegate setAppViewController];
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
