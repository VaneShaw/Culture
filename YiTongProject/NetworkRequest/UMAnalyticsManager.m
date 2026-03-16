//
//  UMAnalyticsManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/14.
//

#import "UMAnalyticsManager.h"

@implementation UMAnalyticsManager
+ (instancetype)sharedManager {
    static UMAnalyticsManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UMAnalyticsManager alloc] init];
    });
    return instance;
}

#pragma mark - 基础事件

- (void)trackEvent:(NSString *)eventId {
    if (!eventId.length) return;
    if (IS_UM_SDK) {
        [MobClick event:eventId];
    }
}

- (void)trackEvent:(NSString *)eventId label:(NSString *)label {
    if (!eventId.length) return;
    if (IS_UM_SDK) {
        [MobClick event:eventId label:label];
    }
}

- (void)trackEvent:(NSString *)eventId attributes:(NSDictionary *)attributes {
    if (!eventId.length) return;
    if (IS_UM_SDK) {
        [MobClick event:eventId attributes:attributes];
    }
}

#pragma mark - 页面统计

- (void)trackPageBegin:(NSString *)pageName {
    if (!pageName.length) return;
    if (IS_UM_SDK) {
        [MobClick beginLogPageView:pageName];
    }
}

- (void)trackPageEnd:(NSString *)pageName {
    if (!pageName.length) return;
    if (IS_UM_SDK) {
        [MobClick endLogPageView:pageName];
    }
}

#pragma mark - 业务事件

- (void)trackShareActionWithPlatform:(NSString *)platform shareCount:(NSInteger)count {
    if (!platform.length) platform = @"unknown";
    if (IS_UM_SDK) {
        NSDictionary *attributes = @{@"platform": platform, @"count": @(count)};
        [MobClick event:@"share_action" attributes:attributes];
    }
}

#pragma mark - 用户生命周期事件

// 首次启动：仅记录一次 v
- (void)trackFirstLaunchWithChannel:(NSString *)channel {
    if (IS_UM_SDK) {
        BOOL launched = [[NSUserDefaults standardUserDefaults] boolForKey:@"UM_First_Launch"];
        if (!launched) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UM_First_Launch"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [MobClick event:@"first_launch" attributes:@{@"channel": channel ?: @"unknown"}];
        }
    }
}

// 注册
- (void)trackUserRegister:(NSString *)userId {
    if (IS_UM_SDK) {
        [MobClick event:@"user_register" attributes:@{@"user_id": userId ?: @"unknown"}];
    }
}

// 登出
- (void)trackUserLogout:(NSString *)userId {
    if (IS_UM_SDK) {
        [MobClick event:@"user_logout" attributes:@{@"user_id": userId ?: @"unknown"}];
    }
}

// App 启动 v
- (void)trackAppStart {
    if (IS_UM_SDK) {
        [MobClick event:@"app_start"];
    }
}

// App 退出 v
- (void)trackAppExit {
    if (IS_UM_SDK) {
        [MobClick event:@"app_exit"];
    }
}

// App 使用时长 v
- (void)trackAppUseDuration:(NSTimeInterval)duration {
    if (IS_UM_SDK) {
        [MobClick event:@"app_use_duration" attributes:@{@"duration": @(duration)}];
    }
}


@end
/*
 4.1 页面统计示例

 objc
 // 在UIViewController中使用
 - (void)viewWillAppear:(BOOL)animated {
     [super viewWillAppear:animated];
     [[UMAnalyticsManager sharedManager] trackPageView:NSStringFromClass([self class])];
 }

 - (void)viewWillDisappear:(BOOL)animated {
     [super viewWillDisappear:animated];
     [[UMAnalyticsManager sharedManager] trackPageEnd:NSStringFromClass([self class])];
 }
 4.2 事件统计示例

 objc
 // 按钮点击事件
 - (IBAction)buyButtonClicked:(id)sender {
     // 业务逻辑...
     
     // 统计事件
     [[UMAnalyticsManager sharedManager] trackPurchaseWithProduct:@"12345" price:99.99];
 }

 // 用户行为统计
 - (void)userDidSearch:(NSString *)keyword {
     // 搜索逻辑...
     
     // 统计搜索事件
     NSDictionary *attributes = @{@"keyword": keyword ?: @""};
     [[UMAnalyticsManager sharedManager] trackEvent:@"search" attributes:attributes];
 }
 */
