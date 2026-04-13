//
//  AppDelegate.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "AppDelegate.h"
#import "MainViewController.h"

#import "TalkViewController.h"
#import "LoginViewController.h"
#import "LaunchViewController.h"
#import "LoginViewController.h"
#import "ProfileViewController.h"
#import "VideoTabViewController.h"
#import "YTVFeedCoordinator.h"
#import "YTVVideoDeepLinkRouter.h"
#import "UserModel.h"
#import "VideoFullScreenViewController.h"
#import "SplashViewController.h"
#import "YTTabBarController.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>

@import Firebase;

/// 系统 Tab 标题常用 `attributedText` 着色，只改 `textColor` 往往不生效，需同步改属性字颜色。
static void YTBTabBarLabelSetForegroundColor(UILabel *lab, UIColor *color) {
    if (!lab || !color) {
        return;
    }
    if (lab.attributedText.length > 0) {
        NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithAttributedString:lab.attributedText];
        [m addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, m.length)];
        lab.attributedText = m;
    }
    lab.textColor = color;
}

/// 遍历 TabBar 内标题 UILabel，按文案匹配 `tabBarItem.title` 后着色。`unselTitle`：白底未选标题色（黑色）。
static void YTBReconcileTabBarTitleLabels(UITabBarController *tbc, BOOL isVideo, UIColor *unselTitle, UIColor *selMain) {
    if (!tbc) {
        return;
    }
    UITabBar *tabBar = tbc.tabBar;
    NSArray<UITabBarItem *> *items = tabBar.items;
    NSInteger selected = tbc.selectedIndex;
    __block void (^visit)(UIView *);
    visit = ^(UIView *view) {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *lab = (UILabel *)view;
            NSString *text = lab.text;
            if (text.length == 0 && lab.attributedText.length > 0) {
                text = lab.attributedText.string;
            }
            if (text.length == 0) {
                return;
            }
            text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            for (NSInteger i = 0; i < (NSInteger)items.count; i++) {
                NSString *itemTitle = items[i].title;
                NSString *trimTitle = itemTitle.length ? [itemTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : @"";
                if (trimTitle.length > 0 && [text isEqualToString:trimTitle]) {
                    UIColor *c = nil;
                    if (isVideo) {
                        c = [UIColor whiteColor];
                    } else {
                        c = (i == selected) ? selMain : unselTitle;
                    }
                    YTBTabBarLabelSetForegroundColor(lab, c);
                    return;
                }
            }
        }
        for (UIView *c in view.subviews) {
            visit(c);
        }
    };
    visit(tabBar);
}

/// 选中视频 Tab 时用黑底专用切图；否则恢复默认 Tab 图（与 `setTabBarController` 一致）。
static void YTBApplyTabBarItemImagesForVideoContext(UITabBarController *tbc, BOOL videoTabSelected) {
    if (!tbc || tbc.tabBar.items.count < 4) {
        return;
    }
    NSArray<UITabBarItem *> *items = tbc.tabBar.items;
    UIImage *(^orig)(NSString *) = ^UIImage *(NSString *name) {
        UIImage *img = [UIImage imageNamed:name];
        if (!img) {
            return nil;
        }
        return [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    };
    if (videoTabSelected) {
        UIImage *h = orig(@"Home_dark_unSel");
        if (h) {
            items[0].image = h;
            items[0].selectedImage = h;
        }
        UIImage *t = orig(@"Talk_dark_unSel");
        if (t) {
            items[1].image = t;
            items[1].selectedImage = t;
        }
        UIImage *v = orig(@"Video_dark_sel");
        if (v) {
            items[2].image = v;
            items[2].selectedImage = v;
        }
        UIImage *m = orig(@"Me_dark_unSel");
        if (m) {
            items[3].image = m;
            items[3].selectedImage = m;
        }
    } else {
        UIImage *h0 = orig(@"Home_Not");
        UIImage *h1 = orig(@"Home_selected");
        if (h0) {
            items[0].image = h0;
        }
        if (h1) {
            items[0].selectedImage = h1;
        }
        UIImage *t0 = orig(@"talk_Not");
        UIImage *t1 = orig(@"talk_Selected");
        if (t0) {
            items[1].image = t0;
        }
        if (t1) {
            items[1].selectedImage = t1;
        }
        UIImage *v0 = orig(@"quiz_Not");
        UIImage *v1 = orig(@"quiz_Selected");
        if (v0) {
            items[2].image = v0;
        }
        if (v1) {
            items[2].selectedImage = v1;
        }
        UIImage *m0 = orig(@"Me_Not");
        UIImage *m1 = orig(@"Me_Selected");
        if (m0) {
            items[3].image = m0;
        }
        if (m1) {
            items[3].selectedImage = m1;
        }
    }
}

@interface AppDelegate ()<AppsFlyerLibDelegate>
@property (strong, nonatomic) UIApplication *gApplication;
@property (strong, nonatomic) NSDictionary *gLaunchOptions;
@property (nonatomic, strong) NSDate *appStartTime;

@property (nonatomic, assign) long long foregroundStartTimeMs;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [NSThread sleepForTimeInterval:2];
    self.gApplication = application;
    self.gLaunchOptions = launchOptions;
    
    //pod install --repo-update
    //[LanguageHelper setLanguage:[LanguageHelper currentLanguage]];
    //[[UserModel sharedInstance] logout];
    // 注册全局未捕获异常处理
    //NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

    [PublicTool resetTriggered];
    [self determineTheSystem];
    [self setAudioSession];

    if(![KUSER_DEFAULT boolForKey:@"app_activated_key"]){
        [KUSER_DEFAULT setBool:YES forKey:@"app_activated_key"];
        [[AnalyticsManager shared] trackEvent:EventTypeAppActivate event_name:@"app首次激活" params:nil];
    }
    NSMutableDictionary *event_params = [NSMutableDictionary dictionary];
    event_params[@"cold_start"] = @"1";// 1冷启动 0热启动
    [[AnalyticsManager shared] trackEvent:EventTypeAppLaunch event_name:@"app启动" params:event_params];

    return YES;
}
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    // 初始化 IAP 服务（内部会 add observer）
    [SilentReceiptSyncManager sharedManager];
}
- (void)determineTheSystem {
    
    BOOL isEngin = is_Engin;
    [self setAppLanguageEngin:isEngin];
    [self setTabBarController];
    if(isEngin){
        [self requestATTAndInitSDK];
    } else {
        [self requestATTPermissionIfNeeded];
    }
    
}

//=================================================
//=================================================================================
//=================================================
//[[UMAnalyt       //[MobClick
- (void)requestATTAndInitSDK { //三分SDK
    
    
        if (@available(iOS 14, *)) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {//允许3 不允许 2
                    [[AppsFlyerLib shared] start];
                    [self setAppSDK];
                }];
            });
        } else {
            [self setAppSDK];
        }
    
    
}
//--------------------------------------------
- (void)requestATTPermissionIfNeeded{ //友盟
    // 只有iOS14+需要显式请求ATT权限
        if (@available(iOS 14, *)) {
            // 延迟请求，避免影响启动体验
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                    //[self handleATTAuthorizationResult:status];
                    [self setupUMAnalytics];
                    if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
                                        NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
                                        NSLog(@"✅ 授权成功，设备 IDFA：------[%@]14以上------", idfa);
                        //[self requestUmengActivation];
                        }
                }];
            });
        } else {
            [self setupUMAnalytics];
            if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
                       NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
                       NSLog(@"设备 IDFA：[%@]------14以下----------", idfa);
                //[self requestUmengActivation];
                }
        }
        //iOS13- 不需要处理，友盟会自动处理IDFA
}

- (void)requestUmengActivation {
    
    NSString *appId = @"6754002048";
    NSString *idfa = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSString *baseURL = @"https://api.umeng.com";
    NSString *path = @"activeReport";//激活上报      @"clickReport"//点击上报
    NSString *urlString = [NSString stringWithFormat:@"%@/%@?appId=%@&idfa=%@", baseURL, path, appId, idfa];
    NSURL *url = [NSURL URLWithString:urlString];
    // 发起GET请求
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                             completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"排重激活请求失败：[%@]", error.localizedDescription);
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSLog(@"排重激活返回：[%@]", json);
            
            if ([json[@"code"] integerValue] == 200) {
                NSLog(@"✅ 排重激活成功-------");
            } else {
                NSLog(@"❌ 排重激活失败：[%@]", json[@"msg"]);
            }
        } else {
            NSLog(@"HTTP状态码异常：[%ld]", (long)httpResponse.statusCode);
        }
    }];
    [task resume];
    
}
//-----------------------友盟sdk-------------------------------------------
- (void)setupUMAnalytics {
    // 开发阶段设置日志
#ifdef DEBUG
    [UMConfigure setLogEnabled:YES];
    [UMConfigure setEncryptEnabled:NO]; // 调试时可关闭加密
#else
    [UMConfigure setLogEnabled:NO];
    [UMConfigure setEncryptEnabled:YES]; // 生产环境开启加密
#endif
    // 初始化SDK
    [UMConfigure initWithAppkey:@"68edb7ab8560e34872c916ee" channel:@"App Store"];
    [MobClick setAutoPageEnabled:YES];      //自动采集页面信息
    [UMConfigure setAnalyticsEnabled:YES];  //开启归因
    //[UMLinkService setupWithLaunchOptions:self.gLaunchOptions];
    
    // 设置版本号，便于区分不同版本数据
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSInteger versionInt = [PublicTool versionStringToInteger:versionString];
    [MobClick setVersion:versionInt];
    //NSLog(@"友盟SDK初始化完成，Build:----------------[%ld]---------", versionInt);

    [[UMAnalyticsManager sharedManager] trackFirstLaunchWithChannel:@"App Store"];
    //[UMAutoTrack startAutoTrack]; // ✅ 开启自动埋点
    //[UMAutoTrack startButtonTrack];
    // ✅ 崩溃监控（注册异常捕获）
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    //[[UMAnalyticsManager sharedManager] trackEvent:@"click_register_button"];// 手动埋点
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.appStartTime = [NSDate date];
    [[UMAnalyticsManager sharedManager] trackAppStart];
    
    [FBSDKAppEvents.shared activateApp];
    [[AppsFlyerLib shared] start];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.appStartTime];
    [[UMAnalyticsManager sharedManager] trackAppUseDuration:duration];
}
// ✅ 应用终止（可统计退出或即将卸载）
- (void)applicationWillTerminate:(UIApplication *)application {
    // 停止网络监测
    [[NetworkMonitor sharedMonitor] stopMonitoring];
    if (IS_UM_SDK) {
        [[UMAnalyticsManager sharedManager] trackAppExit];
        [[UMAnalyticsManager sharedManager] trackEvent:@"app_terminate"];
    }
    [[AnalyticsManager shared] flushEvents];
}

// ✅ 应用进入前台（统计活跃用户）
- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (IS_UM_SDK) {
        [[UMAnalyticsManager sharedManager] trackEvent:@"app_foreground"];
    }
    NSMutableDictionary *event_params = [NSMutableDictionary dictionary];
    event_params[@"cold_start"] = @"0";// 1冷启动 0热启动
    [[AnalyticsManager shared] trackEvent:EventTypeAppLaunch event_name:@"app启动" params:event_params];
    
    NSMutableDictionary *event_params2 = [NSMutableDictionary dictionary];
    event_params2[@"session_id"] = [KeychainUUID getUUID];
    //event_params2[@"source"] = @"icon | push | deeplink";//暂无用
    [[AnalyticsManager shared] trackEvent:EventTypeAppForeground event_name:@"app进入前台" params:event_params2];
    self.foregroundStartTimeMs = [AnalyticsManager currentTimeMillis];
    [[AnalyticsManager shared] startHeartbeat];
}

// ✅ 应用进入后台（统计使用时长、退出次数）
- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (IS_UM_SDK) {
        [[UMAnalyticsManager sharedManager] trackEvent:@"app_background"];
    }
    [[AudioManager sharedManager] stopRecording];
    [[AudioManager sharedManager] stopPlayback];
    
    [KUSER_DEFAULT setBool:NO forKey:@"Quiz_key_1"];
    [PublicTool resetTriggered];
    
    //======================================================================
    long long nowMs = [AnalyticsManager currentTimeMillis];
    long long durationSec = 0;
    if (self.foregroundStartTimeMs > 0) {
        durationSec = (nowMs - self.foregroundStartTimeMs) / 1000;
    }
    NSMutableDictionary *event_params = [NSMutableDictionary dictionary];
    event_params[@"session_id"] = [KeychainUUID getUUID];
    event_params[@"duration"] = @(durationSec);//停留时长
    [[AnalyticsManager shared] trackEvent:EventTypeAppBackground event_name:@"app进入后台" params:event_params];
    [[AnalyticsManager shared] stopHeartbeat];
    //======================================================================
}

#pragma mark - 崩溃捕获
void uncaughtExceptionHandler(NSException *exception) {
    if (IS_UM_SDK) {
        NSDictionary *info = @{
            @"reason": exception.reason ?: @"unknown",
            @"name": exception.name ?: @"",
        };
        [[UMAnalyticsManager sharedManager] trackEvent:@"app_crash" attributes:info];
    }
}
//-----------------------友盟sdk------end-------------------------------------
- (void)setAppSDK { //埋点
    //Facebook
    [[FBSDKApplicationDelegate sharedInstance] application:self.gApplication
                                 didFinishLaunchingWithOptions:self.gLaunchOptions];
    [FBSDKAppEvents.shared activateApp];
    [FIRApp configure]; //Firebase
    // ⚡ AppsFlyer 基本配置
    [AppsFlyerLib shared].appsFlyerDevKey = @"BBxQP9cF4EkjK3DHFVM735";
    [AppsFlyerLib shared].appleAppID = @"6753883494";
    [AppsFlyerLib shared].delegate = self;
    [[AppsFlyerLib shared] waitForATTUserAuthorizationWithTimeoutInterval:60];
    [[AppsFlyerLib shared] start];
}
// 安装/首次打开的归因数据
- (void)onConversionDataSuccess:(NSDictionary *)conversionInfo {
    //NSLog(@"[AppsFlyer] Conversion Data: %@", conversionInfo);
    [MobClick event:@"install_attribution" attributes:conversionInfo];

}
 // ✅ Facebook 登录/分享回调（如果未来需要的话）
 - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
     if ([YTVVideoDeepLinkRouter ytv_isVideoDeepLinkURL:url]) {
         [[YTVFeedCoordinator sharedCoordinator] routeVideoDeepLinkFromURL:url];
         return YES;
     }
     return [[FBSDKApplicationDelegate sharedInstance] application:app
                                                           openURL:url
                                                           options:options];
 }

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *url = userActivity.webpageURL;
        if ([YTVVideoDeepLinkRouter ytv_isVideoDeepLinkURL:url]) {
            [[YTVFeedCoordinator sharedCoordinator] routeVideoDeepLinkFromURL:url];
            return YES;
        }
    }
    return NO;
}
//=================================================================================
- (void)setAppLanguageEngin:(BOOL)isEngin {
    [[AppConfig sharedConfig] setLanguage:@[@"cn",@"en"][isEngin]];
    //NSString *newHost = [AppConfig sharedConfig].host;

    [KUSER_DEFAULT setBool:isEngin forKey:@"Language_area"];     //是否是英文区    1是
    [KUSER_DEFAULT setObject:@[@"cn",@"en"][isEngin] forKey:@"Language_type"];  //接口传参数
    [LanguageHelper setLanguage:@[@"zh-Hans",@"en"][isEngin]];                 //系统语言
    [MJRefreshConfig defaultConfig].languageCode = @[@"zh-Hans",@"en"][isEngin];//下拉刷新 语言
    NSDictionary *defaults = @{@"Language_key" : @[@"Cn",@"En"][isEngin]};  //故事页 默认语言
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}
- (void)setAppViewController {
    if([[UserModel sharedInstance] isLogin]){
        [self setTabBarController];
    } else {
        LoginViewController *loginVC = [[LoginViewController alloc] init];
        UINavigationController *loginNC = [[UINavigationController alloc]initWithRootViewController:loginVC];
        self.window.rootViewController = loginNC;
    }
}
- (void)setAudioSession {
    //[KUSER_DEFAULT removeObjectForKey:@"HasRetried401"];
    //[KUSER_DEFAULT synchronize];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [session setCategory:AVAudioSessionCategoryPlayback
                    mode:AVAudioSessionModeDefault
                 options:AVAudioSessionCategoryOptionMixWithOthers
                   error:&error];
    if (error) {
        NSLog(@"设置 category 出错: %@", error);
    }
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"激活出错: %@", error);
    }
    //[[NetworkMonitor sharedMonitor] startMonitoring];
    // 监听语言切换通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageDidChange)
                                                 name:LanguageDidChangeNotification
                                               object:nil];
}
- (void)languageDidChange {
    // 切换语言后刷新根控制器
    [self setTabBarController];
}
- (void)setTabBarController {
    MainViewController *mainVC = [MainViewController new];
    TalkViewController *talkVC = [TalkViewController new];
    VideoTabViewController *videoVC = [VideoTabViewController new];
    ProfileViewController *profileVC = [ProfileViewController new];
    
    UINavigationController *mainNC = [[UINavigationController alloc]initWithRootViewController:mainVC];
    UINavigationController *talkNC = [[UINavigationController alloc]initWithRootViewController:talkVC];
    UINavigationController *videoNC = [[UINavigationController alloc]initWithRootViewController:videoVC];
    UINavigationController *profileNC = [[UINavigationController alloc]initWithRootViewController:profileVC];
   
    mainNC.title = NSLocalizedString(@"Home",@"");
    talkNC.title = NSLocalizedString(@"Talk",@"");
    videoNC.title = NSLocalizedString(@"Video",@"");
    profileNC.title = NSLocalizedString(@"Profile",@"");
    
    mainNC.tabBarItem.selectedImage = [[UIImage imageNamed:@"Home_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    videoNC.tabBarItem.selectedImage = [[UIImage imageNamed:@"quiz_Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    profileNC.tabBarItem.selectedImage = [[UIImage imageNamed:@"Me_Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    //================================
    mainNC.tabBarItem.image = [[UIImage imageNamed:@"Home_Not"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    videoNC.tabBarItem.image = [[UIImage imageNamed:@"quiz_Not"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    profileNC.tabBarItem.image = [[UIImage imageNamed:@"Me_Not"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    talkNC.tabBarItem.selectedImage = [[UIImage imageNamed:@"talk_Selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    talkNC.tabBarItem.image = [[UIImage imageNamed:@"talk_Not"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    [self setNavieationBarColor:mainNC];
    [self setNavieationBarColor:talkNC];
    [self setNavieationBarColor:videoNC];
    [self setNavieationBarColor:profileNC];
  
    YTTabBarController *tabBar = [YTTabBarController new];
    [UITabBar appearance].translucent = NO;
    theAppDelegate.tabBarController_startApp = tabBar;
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:FONT_NAME_Semibold size:11.0f]} forState:UIControlStateNormal];

    //tabBar.tabBar.backgroundImage = [UIImage new];   //底部一条黑线
    //tabBar.tabBar.shadowImage = [UIImage new];
    [self removeTabBarTopLine:tabBar];
    
    //tabBar.viewControllers = [NSArray arrayWithObjects:mainNC,quizNC,profileNC, nil];
    tabBar.viewControllers = [NSArray arrayWithObjects:mainNC,talkNC,videoNC,profileNC, nil];
    NSMutableDictionary *attr3 = [NSMutableDictionary dictionary];
    attr3[NSFontAttributeName] = [UIFont systemFontOfSize:12];
    [[UITabBarItem appearance]setTitleTextAttributes:attr3 forState:UIControlStateNormal];
    UITabBar.appearance.backgroundColor = [UIColor whiteColor];
   
    //tabbar 底部背景颜色
    //tabbartitle颜色选中跟未选中
    tabBar.tabBar.unselectedItemTintColor = [self.window colorWithHexString:@"#000000" alpha:1];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:Main_COLOR} forState:UIControlStateSelected];
    //[[UITabBar appearance]setTintColor:[self.window colorWithHexString:@"#4C9BEF" alpha:1]];
    //状态栏字体颜色
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    //[PublicTool setGlobalStatusBarStyle:UIStatusBarStyleLightContent];
    
    //选中 & 未选中
    //x[[UITabBar appearance]setTintColor:MAIN_COLOR];
    //tabBar.tabBar.unselectedItemTintColor = [UIColor orangeColor];
    self.window.rootViewController = theAppDelegate.tabBarController_startApp;
    [self ytb_applyTabBarAppearanceForTabBarController:tabBar];
}

/// 选中视频 Tab：黑底、全部标题白色；其它 Tab：白底、未选标题黑色、选中标题主色蓝。
- (void)ytb_applyTabBarAppearanceForTabBarController:(UITabBarController *)tbc {
    if (!tbc) {
        return;
    }
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self ytb_applyTabBarAppearanceForTabBarController:tbc];
        });
        return;
    }
    UITabBar *tabBar = tbc.tabBar;
    BOOL isVideo = (tbc.selectedIndex == kYTVVideoTabBarIndex);
    UIColor *bg = isVideo ? [UIColor blackColor] : [UIColor whiteColor];
    UIWindow *colorWindow = self.window ?: UIApplication.sharedApplication.keyWindow;
    if (!colorWindow && UIApplication.sharedApplication.windows.count > 0) {
        colorWindow = UIApplication.sharedApplication.windows.firstObject;
    }
    /// 白底时未选 Tab 标题为黑色；图标在 iOS 15+ 仍可用浅蓝着色（与 PNG 资源搭配）。
    UIColor *unselBlue = colorWindow ? [colorWindow colorWithHexString:@"#ADCEF3" alpha:1] : [UIColor colorWithRed:0.678f green:0.808f blue:0.953f alpha:1.0f];
    UIColor *titleUnselLightBg = colorWindow ? [colorWindow colorWithHexString:@"#000000" alpha:1] : [UIColor blackColor];
    UIColor *selMain = colorWindow ? [colorWindow colorWithHexString:@"#4C9BEF" alpha:1] : [UIColor colorWithRed:0.298f green:0.608f blue:0.937f alpha:1.0f];
    UIColor *titleNormal = isVideo ? [UIColor whiteColor] : titleUnselLightBg;
    UIColor *titleSelected = isVideo ? [UIColor whiteColor] : selMain;
    UIFont *fontNormal = [UIFont systemFontOfSize:12];
    UIFont *fontSelected = [UIFont fontWithName:FONT_NAME_Semibold size:11.0f];
    if (!fontSelected) {
        fontSelected = [UIFont boldSystemFontOfSize:11];
    }
    NSDictionary *normAttr = @{ NSForegroundColorAttributeName: titleNormal, NSFontAttributeName: fontNormal };
    NSDictionary *selAttr = @{ NSForegroundColorAttributeName: titleSelected, NSFontAttributeName: fontSelected };

    tabBar.translucent = NO;
    tabBar.backgroundColor = bg;
    tabBar.barTintColor = bg;

    YTBApplyTabBarItemImagesForVideoContext(tbc, isVideo);

    for (UITabBarItem *item in tabBar.items) {
        [item setTitleTextAttributes:normAttr forState:UIControlStateNormal];
        [item setTitleTextAttributes:selAttr forState:UIControlStateSelected];
        [item setTitleTextAttributes:normAttr forState:UIControlStateHighlighted];
        [item setTitleTextAttributes:selAttr forState:UIControlStateSelected | UIControlStateHighlighted];
    }

    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = bg;
        appearance.shadowImage = [UIImage new];
        appearance.shadowColor = [UIColor clearColor];
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normAttr;
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selAttr;
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = normAttr;
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = selAttr;
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = normAttr;
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = selAttr;
        appearance.stackedLayoutAppearance.disabled.titleTextAttributes = normAttr;
        appearance.stackedLayoutAppearance.focused.titleTextAttributes = normAttr;
        if (@available(iOS 15.0, *)) {
            appearance.stackedLayoutAppearance.normal.iconColor = isVideo ? [UIColor whiteColor] : unselBlue;
            appearance.stackedLayoutAppearance.selected.iconColor = isVideo ? [UIColor whiteColor] : selMain;
            appearance.inlineLayoutAppearance.normal.iconColor = isVideo ? [UIColor whiteColor] : unselBlue;
            appearance.inlineLayoutAppearance.selected.iconColor = isVideo ? [UIColor whiteColor] : selMain;
            appearance.compactInlineLayoutAppearance.normal.iconColor = isVideo ? [UIColor whiteColor] : unselBlue;
            appearance.compactInlineLayoutAppearance.selected.iconColor = isVideo ? [UIColor whiteColor] : selMain;
        }
        tabBar.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            tabBar.scrollEdgeAppearance = appearance;
        }
    }
    tabBar.tintColor = titleSelected;
    tabBar.unselectedItemTintColor = titleNormal;

    [tabBar setNeedsLayout];
    [tabBar layoutIfNeeded];
    YTBReconcileTabBarTitleLabels(tbc, isVideo, titleUnselLightBg, selMain);
    if (isVideo) {
        NSTimeInterval delays[] = { 0.05, 0.15, 0.35 };
        for (unsigned k = 0; k < sizeof(delays) / sizeof(delays[0]); k++) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delays[k] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (tbc.selectedIndex != kYTVVideoTabBarIndex) {
                    return;
                }
                YTBReconcileTabBarTitleLabels(tbc, YES, titleUnselLightBg, selMain);
            });
        }
    }
}

- (void)setNavieationBarColor:(UINavigationController *)nav {
    nav.navigationBar.tintColor = BLACK_COLOR;//左右图标
    nav.navigationBar.barTintColor = [UIColor whiteColor];//MAIN_COLOR_Background;//导航栏背景色
    //标题颜色
    UIColor *titltColor = BLACK_COLOR;
    NSDictionary *dict = [NSDictionary dictionaryWithObject:titltColor forKey:NSForegroundColorAttributeName];
    nav.navigationBar.titleTextAttributes = dict;
}

- (void)removeTabBarTopLine:(UITabBarController *)tabBarController {
    UITabBar *tabBar = tabBarController.tabBar;
    
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = [UIColor clearColor]; // 或者自定义颜色
        // 去掉底部黑线
        appearance.shadowImage = [UIImage new];
        appearance.shadowColor = [UIColor clearColor];
        
        tabBar.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            tabBar.scrollEdgeAppearance = appearance;
        }
    } else {
        // iOS 12 及以下用旧方式
        tabBar.backgroundImage = [UIImage new];
        tabBar.shadowImage = [UIImage new];
    }
}
#pragma mark - UISceneSession lifecycle

/*dex1
- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}
 
- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}
*/

// 定义异常处理函数
//void uncaughtExceptionHandler(NSException *exception) {
    //NSLog(@"========= Uncaught Exception =========");
    //NSLog(@"Name: %@", exception.name);
    //NSLog(@"Reason: %@", exception.reason);
    //NSLog(@"UserInfo: %@", exception.userInfo);
    //NSLog(@"CallStackSymbols: %@", [exception callStackSymbols]);
    //NSLog(@"=====================================");
    // 这里可以写入文件或者上传服务器
//}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if ([self.window.rootViewController.presentedViewController isKindOfClass:[VideoFullScreenViewController class]]) {
        return UIInterfaceOrientationMaskAllButUpsideDown; // 允许视频横屏
    }
    return UIInterfaceOrientationMaskPortrait; // 其他页面竖屏
}
#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentCloudKitContainer *)persistentContainer {
    // The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it.
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentCloudKitContainer alloc] initWithName:@"YiTongProject"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                    */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}       //应用进入后台（这里一定要保存关键状态）




// iOS 13+ 使用 SceneDelegate 时，需要在 sceneDidBecomeActive 里调用
// - (void)sceneDidBecomeActive:(UIScene *)scene {
//     [[AppsFlyerLib shared] start];
// }

#pragma mark - AppsFlyerLibDelegate 回调


/*
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [self handleUMengDeeplink:url];
    return YES;
}
- (void)handleUMengDeeplink:(NSURL *)url {
    // 解析URL中的归因参数
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
    NSMutableDictionary *attributionParams = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in components.queryItems) {
        if (item.value) {
            [attributionParams setObject:item.value forKey:item.name];
        }
    }
    
    // 上报归因事件
    if (attributionParams.count > 0) {
        [MobClick event:@"umeng_deeplink_attribution" attributes:attributionParams];
    }
}*/
- (void)onConversionDataFail:(NSError *)error {
    //NSLog(@"[AppsFlyer] Conversion Data Error: %@", error.localizedDescription);
}

/// 通过 deeplink 唤起的归因数据
- (void)onAppOpenAttribution:(NSDictionary *)attributionData {
    //NSLog(@"[AppsFlyer] App Open Attribution: %@", attributionData);
}

- (void)onAppOpenAttributionFailure:(NSError *)error {
    //NSLog(@"[AppsFlyer] App Open Attribution Error: %@", error.localizedDescription);
}

@end
