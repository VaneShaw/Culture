//
//  PublicTool.m
//  YiTongProject
//
//  Created by Vincent on 2025/8/11.
//

#import "PublicTool.h"
//公共类，各种公共数据 请求 判断
@implementation PublicTool
+ (CGFloat)getStatusBarHeight {
    CGFloat statusBarHeight = 0;
    if (@available(iOS 13.0, *)) {
        UIStatusBarManager *statusBarManager = [UIApplication sharedApplication].windows.firstObject.windowScene.statusBarManager;
        statusBarHeight = statusBarManager.statusBarFrame.size.height;
    } else {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    return statusBarHeight;
}

+ (void)setGlobalStatusBarStyle:(UIStatusBarStyle)style {
    if (@available(iOS 13.0, *)) {
        // iOS 13+：强制修改 window 的 userInterfaceStyle
        //UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
        keyWindow.overrideUserInterfaceStyle = (style == UIStatusBarStyleLightContent) ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
    } else {
        // iOS 12 及以下：直接设置 statusBarStyle
        [[UIApplication sharedApplication] setStatusBarStyle:style];
    }
}
// 判断是否首次启动
+ (BOOL)isFirstLaunch {
    static BOOL isFirst = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 检查标志位
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasLaunchedBefore"]) {
            isFirst = YES;
            // 设置标志位
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasLaunchedBefore"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    });
    return isFirst;
}
// 新增注册状态判断
+ (BOOL)hasRegistered {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"hasRegistered"];
}
// 标记已注册
+ (void)markAsRegistered {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRegistered"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
+ (void)markAsDeleteUserRegistered {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hasRegistered"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}
//验证手机号
+ (BOOL)isValidPhone:(NSString *)phone {
    
    if (phone == nil || phone.length == 0) return NO;
      phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
      // 长度判断
      if (phone.length != 11) return NO;
      // 正则匹配中国大陆手机号
      NSString *regex = @"^1[3-9]\\d{9}$";
      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
      return [predicate evaluateWithObject:phone];
}

+ (BOOL)hasTriggered {
    NSString *key = @"PublicTool_hasTriggered";
    BOOL triggered = [KUSER_DEFAULT boolForKey:key];
    if (!triggered) {
        // 第一次调用，返回 NO，并标记已触发
        [KUSER_DEFAULT setBool:YES forKey:key];
        [KUSER_DEFAULT synchronize];
        return NO;
    }
    // 第二次及以后，返回 YES
    return YES;
}
+ (void)resetTriggered {
    // 登录成功时调用，重置为 NO
    [KUSER_DEFAULT removeObjectForKey:@"PublicTool_hasTriggered"];
    [KUSER_DEFAULT synchronize];

}
//首次安装返回no，之后都是yes
+ (BOOL)triggerStatus {
    static BOOL triggeredThisLaunch = NO; // 本次启动是否已触发
    @synchronized(self) {
        if (triggeredThisLaunch) {
            // 本次启动已经触发过，直接返回 YES
            return YES;
        } else {
            triggeredThisLaunch = YES;
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults boolForKey:@"HasLaunchedBefore"]) {
                // 不是首次安装启动
                return YES;
            } else {
                // 首次安装启动
                [defaults setBool:YES forKey:@"HasLaunchedBefore"];
                [defaults synchronize];
                return NO;
            }
        }
    }
}
+ (BOOL)hasLanguageOrRegionChanged {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 当前系统语言和地区
    NSString *currentLanguage = [[NSLocale preferredLanguages] firstObject];
    NSString *currentRegion = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    // 上一次记录的语言和地区
    NSString *lastLanguage = [defaults stringForKey:@"LastLanguage"];
    NSString *lastRegion = [defaults stringForKey:@"LastRegion"];
    BOOL changed = NO;
    
    // 判断是否变化
    if (![currentLanguage isEqualToString:lastLanguage] || ![currentRegion isEqualToString:lastRegion]) {
        changed = YES;
        
        // 保存最新值
        [defaults setObject:currentLanguage forKey:@"LastLanguage"];
        [defaults setObject:currentRegion forKey:@"LastRegion"];
        [defaults synchronize];
    }
    
    return changed;
}

+ (NSInteger)versionStringToInteger:(NSString *)versionString {
    if (!versionString || versionString.length == 0) return 0;
    
    NSArray *components = [versionString componentsSeparatedByString:@"."];
    NSInteger versionInt = 0;
    
    // 支持 1.0.1 或 1.0 或 1 等格式
    if (components.count >= 3) {
        versionInt = [components[0] integerValue] * 100 +
                     [components[1] integerValue] * 10 +
                     [components[2] integerValue];
    } else if (components.count == 2) {
        versionInt = [components[0] integerValue] * 10 +
                     [components[1] integerValue];
    } else if (components.count == 1) {
        versionInt = [components[0] integerValue];
    }
    
    return versionInt;
}
+ (CGFloat)secondsFromFrameTimeString:(NSString *)timeString frameRate:(CGFloat)fps {
    if (![timeString isKindOfClass:[NSString class]] || timeString.length == 0) return 0;

    NSArray<NSString *> *components = [timeString componentsSeparatedByString:@":"];
    if (components.count != 3) return 0;

    NSInteger minutes = [components[0] integerValue];
    NSInteger seconds = [components[1] integerValue];
    NSInteger frames  = [components[2] integerValue];

    // 总秒数 = 分*60 + 秒 + 帧/fps
    CGFloat totalSeconds = minutes * 60 + seconds + (frames / fps);
    return totalSeconds;
}
@end
