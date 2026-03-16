//
//  PublicTool.h
//  YiTongProject
//
//  Created by Vincent on 2025/8/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PublicTool : NSObject
+ (CGFloat)getStatusBarHeight;//获取状态栏高度
+ (void)setGlobalStatusBarStyle:(UIStatusBarStyle)style;
+ (BOOL)isFirstLaunch; //判断是否首次启动

+ (BOOL)hasRegistered;  //判断是否首次从启动页进入,弹注册页
+ (void)markAsRegistered;//标记以及注册成功,后续跳登录页
+ (void)markAsDeleteUserRegistered;//注销

+ (BOOL)isValidPhone:(NSString *)phone;

+ (BOOL)hasTriggered;
+ (void)resetTriggered;

+ (BOOL)triggerStatus;
+ (BOOL)hasLanguageOrRegionChanged;
+ (NSInteger)versionStringToInteger:(NSString *)versionString;
+ (CGFloat)secondsFromFrameTimeString:(NSString *)timeString frameRate:(CGFloat)fps;
@end

NS_ASSUME_NONNULL_END

