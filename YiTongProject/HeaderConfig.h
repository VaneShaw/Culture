//
//  HeaderConfig.h


#ifndef HeaderConfig_h
#define HeaderConfig_h

#import "AppDelegate.h"
#import "AFNetworking.h"//主要用于网络请求方法
#import "UIKit+AFNetworking.h"//里面有异步加载图片的方法  
#import "MJRefresh.h"
#import "UIImageView+WebCache.h"
#import "MJExtension.h"
#import "JSONModel.h"
#import "Singleton.h"
#import "AudioManager.h"
#import "UIView+ColorState.h"
#import <Masonry/Masonry.h> // 使用 Masonry 简化布局
#import <SDWebImage/SDWebImage.h> 
//网络请求
#import "NetWorkTool.h"
#import "HttpTools.h"
#import "UserModel.h"
#import "BaseDataModel.h"
#import "MBProgressHUD+Show.h"
#import "AppKey.h"
#import "PublicTool.h"
#import "NetworkMonitor.h"
#import "ReadyLogOutView.h"

#import "UITableView+Empty.h"
#import "LanguageHelper.h"
#import "IDStorageManager.h"
#import "LoginViewController.h"
#import "PhoneLoginViewController.h"
#import "KeyboardAvoidingManager.h"
#import "UIViewController+BackButton.h"
#import "ColorManager.h"
#import "AgreementConsentView.h"
#import "NSArray+JSON.h"
#import "DataCacheManager.h"
#import "AppConfig.h"
#import "LoginManager.h"
#import "NoNetworkView.h"
#import <FLAnimatedImage/FLAnimatedImage.h>
//==========================================
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <AppsFlyerLib/AppsFlyerLib.h>
#import <UMCommon/UMCommon.h>
#import <UMCommon/MobClick.h>
#import <UMAPM/UMLaunch.h>
#import "UMAnalyticsManager.h"
#import <FirebaseAnalytics/FirebaseAnalytics.h>

//===========================================
#import "UIPlayButton.h"
#import <SDWebImage/SDAnimatedImageView.h>
#import "GradientLabel.h"
#import "CellCoverView.h"
#import "PaymentViewController.h"

#import "MembershipTransferView.h"
#import "GlobalHUDManager.h"
#import "UnlockedView.h"
#import "AccessExpiresView.h"
#import "YTIAPService.h"
#import "SilentReceiptSyncManager.h"
#import "UserStateManager.h"
#import "KeychainUUID.h"
#import "AudioScrollManager.h"
#import "MediaPlayManager.h"

#import "AnalyticsManager.h"
#import "EventTypes.h"
#import "BaseViewController.h"


 #define IPHONE_X \
({BOOL isPhoneX = NO;\
if (@available(iOS 11.0, *)) {\
isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;\
}\
(isPhoneX);})
//iPhoneX系列
#define k_Height_NavContentBar 44.0f
#define k_Height_StatusBar (IPHONE_X ? 44.0 : 20.0)
#define k_Height_NavBar (IPHONE_X ? 88.0 : 64.0)
#define k_Height_TabBar (IPHONE_X ? 83.0 : 49.0)
#define k_Safe_Height (IPHONE_X ? 34 : 0)
#define K_Safe_Top_height k_Height_NavBar+k_Safe_Height
#define K_Safe_Top_TabBar_height k_Height_NavBar+k_Safe_Height+k_Height_TabBar
#define k_popViewHeight 40

#define WS(weakSelf) __weak __typeof(&*self)weakSelf = self;
#define Singleton_h(name) + (instancetype)shared##name;
#define KUSER_DEFAULT [NSUserDefaults standardUserDefaults]

/*Font Family: 【PingFang TC】=====
    Font: 【PingFangTC-Regular】
    Font: 【PingFangTC-Ultralight】
    Font: 【PingFangTC-Thin】=====
    Font: 【PingFangTC-Light】====
    Font: 【PingFangTC-Medium】===
    Font: 【PingFangTC-Semibold】=*/

#define FONT_NAME_HelveticaBold @"Helvetica-Bold"        //@"PingFangSC-Semibold"
#define FONT_NAME_HelveticaMedium @"HelveticaNeue-Medium"//@"Helvetica-Bold"           //@"PingFangSC-Medium"
#define FONT_NAME_Helvetica @"Helvetica-Bold"

#define FONT_NAME_Medium @"PingFangSC-Medium"
#define FONT_NAME_Semibold @"PingFangSC-Semibold"
#define FONT_NAME_Regular @"PingFangSC-Regular"
#define Analytics_Events_Key @"analytics_events_cache"

#define FONT_NAME_Kaiti @"FZKai-Z03S"
#define Story_Scroll_Row @"Story_Scroll_Row"
#define Story_Scroll_Index @"Story_Scroll_Index"
#define Story_Scroll_IsVC @"Story_Scroll_IsVC"

#define From_Key @"from_key"
//#define FONT_NAME_Kaiti @"Kailasa"
//#define FONT_NAME_SC_BOLD @"PingFangSC-Medium"
//#define FONT_NAME_SC_Light @"PingFangSC-Light"

#define LINE_WIDTH 2
#define PAGE_COUNT 10
#define Distance＿X 25
#define Distance＿M 20
#define Countdown_Seconds 3

// 在头文件中定义宏
//=========================================================
#define Status_Height ({\
    CGFloat __height = 0;\
    if (@available(iOS 13.0, *)) {\
        UIWindowScene *__scene = (UIWindowScene *)[UIApplication sharedApplication].windows.firstObject.windowScene;\
        if (__scene) {\
            __height = __scene.statusBarManager.statusBarFrame.size.height;\
        } else {\
            __height = [UIApplication sharedApplication].statusBarFrame.size.height;\
        }\
    } else {\
        __height = [UIApplication sharedApplication].statusBarFrame.size.height;\
    }\
    __height;\
})
//=========================================================
#define theAppDelegate ((AppDelegate *)([UIApplication sharedApplication].delegate))
#define SCREEN_HEIGHT ((int)[UIScreen mainScreen].bounds.size.height)
#define SCREEN_WIDTH ((int)[UIScreen mainScreen].bounds.size.width)    //390
#define First_Launch_KEY @"YouthProtectionr_key"
#define IS_Formal_Hanzi [KUSER_DEFAULT boolForKey:@"IS_Formal_Hanzi"]
#define Small_Screen 668
#define IS_Formal_Screen (SCREEN_HEIGHT < Small_Screen ? 0 : 1)  //0小屏幕 1正常屏幕。

//#define Card_Height (SCREEN_HEIGHT < Small_Screen ? 358 : 438)
//#define Card_WIDTH SCREEN_WIDTH - 94
#define Card_WIDTH SCREEN_WIDTH - 78
#define BASE_WIDTH   324       // 基准宽度
#define BASE_HEIGHT  438       // 基准高度
#define MAX_EXTRA    40        // 最大增加高度

#define Card_Height  \
({ \
    CGFloat height = 0; \
    if (IS_Formal_Hanzi == 1) { \
        if (SCREEN_HEIGHT < Small_Screen) { \
            height = 358; \
        } else { \
            CGFloat baseWidth = 324; \
            CGFloat baseHeight = 438; \
            CGFloat maxExtra = 40; \
            CGFloat extra = Card_WIDTH - baseWidth; \
            if (extra < 0) extra = 0; \
            if (extra > maxExtra) extra = maxExtra; \
            height = baseHeight + extra; \
        } \
    } else { \
        height = (SCREEN_HEIGHT < Small_Screen ? 358 : 438); \
    } \
    height; \
})

#define DarkBlue_COLOR [theAppDelegate.window colorWithHexString:@"#05073E" alpha:1]
#define VIP_COLOR [theAppDelegate.window colorWithHexString:@"#040531" alpha:1]
#define Main_COLOR [theAppDelegate.window colorWithHexString:@"#4C9BEF" alpha:1]
#define Gray_COLOR [theAppDelegate.window colorWithHexString:@"#B6BDC3" alpha:1]
#define Language_Type [KUSER_DEFAULT objectForKey:@"Language_type"]
#define Language_key  [KUSER_DEFAULT objectForKey:@"Language_key"]
#define IS_OVERSEAS_VERSION [KUSER_DEFAULT boolForKey:@"Language_area"]
#define IS_UM_SDK ![KUSER_DEFAULT boolForKey:@"Language_area"]

#define Guest_Uuid_Key @"guest_uuid_key_2"
#define IAP_Price_key @"price_key_1"
#define IAP_Product_id @"product_id_key1"
#define IAP_Membership_Notification @"kUserMembershipDidUpdateNotification"

#define Card_Type @"card_type_index"    //@"Listen", @"Speak", @"Write", @"Video"
#define GARY_COLOR_63 [theAppDelegate.window colorWithHexString:@"#63637D" alpha:1]
#define BLACK_COLOR_1F [theAppDelegate.window colorWithHexString:@"#1F1F39" alpha:1]
#define BLACK_COLOR [theAppDelegate.window colorWithHexString:@"#000000" alpha:1]
#define MAIN_COLOR_Background [theAppDelegate.window colorWithHexString:@"#4CA1F6" alpha:1]
#define Main_Cell_Background [theAppDelegate.window colorWithHexString:@"#FFFFFF" alpha:1]
#define IS_Member_key @"IS_Member_key"


#define IS_Member 1 //0 把锁去掉      1 根据接口返回   //暂时无用 用于苹果支付功能，  如果后端开启支付功能 0的话 相当于开放所有功能
#define is_Engin 0  //1英文版          0中文版      //海外版 1（全英文）     国内版0（中文为主）

// Host配置 - 根据构建配置和版本自动选择
// 测试环境
#define HOST_TEST @"https://testapi.shiyi-yitong.com"
// 正式环境 - 海外版
#define HOST_PRODUCTION_OVERSEAS @"https://api.shiyi-yitong.com"
// 正式环境 - 国内版
#define HOST_PRODUCTION_DOMESTIC @"https://apicn.shiyi-yitong.com"

// 获取当前host的辅助函数（运行时根据配置自动选择）
// Debug模式：使用测试环境
// Release模式：根据国内版/国外版选择对应的正式环境host
static inline NSString * _Nonnull GetCurrentHost(void) {
#ifdef DEBUG
    // Debug模式：使用测试环境
    return HOST_TEST;
#else
    // Release模式：根据国内版/国外版选择对应的正式环境host
    if (IS_OVERSEAS_VERSION) {
        // 海外版
        return HOST_PRODUCTION_OVERSEAS;
    } else {
        // 国内版
        return HOST_PRODUCTION_DOMESTIC;
    }
#endif
}

// HOST宏定义 - 为了保持向后兼容，使用函数来动态获取
#define HOST GetCurrentHost()
#endif


