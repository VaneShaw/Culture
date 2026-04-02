//
//  PublicTool.h
//  YiTongProject
//
//  Created by Vincent on 2025/8/11.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

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
/// 与安卓 Idiom 一致：`分:秒:第三段`，第三段整数 ×10 为毫秒（总毫秒 = m*60*1000 + s*1000 + third*10）
+ (NSInteger)millisecondsFromColonTimeStringLikeAndroid:(nullable id)raw;
+ (NSTimeInterval)secondsFromColonTimeStringLikeAndroid:(nullable id)raw;
/// 将秒数转为以毫秒为 timeScale 的 CMTime，seek 时与后台毫秒时间对齐
+ (CMTime)cmTimeFromSecondsMillisecondPrecision:(NSTimeInterval)seconds;
@end

NS_ASSUME_NONNULL_END

