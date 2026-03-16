//
//  UMAnalyticsManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UMAnalyticsManager : NSObject
+ (instancetype)sharedManager;

// 基础事件
- (void)trackEvent:(NSString *)eventId;
- (void)trackEvent:(NSString *)eventId label:(NSString *)label;
- (void)trackEvent:(NSString *)eventId attributes:(NSDictionary *)attributes;

// 页面统计
- (void)trackPageBegin:(NSString *)pageName;
- (void)trackPageEnd:(NSString *)pageName;

// 业务事件
- (void)trackShareActionWithPlatform:(NSString *)platform shareCount:(NSInteger)count;

// 用户生命周期事件
- (void)trackFirstLaunchWithChannel:(NSString *)channel;
- (void)trackUserRegister:(NSString *)userId;
- (void)trackUserLogout:(NSString *)userId;
- (void)trackAppStart;
- (void)trackAppExit;
- (void)trackAppUseDuration:(NSTimeInterval)duration;
@end

NS_ASSUME_NONNULL_END
