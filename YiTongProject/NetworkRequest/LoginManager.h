//
//  LoginManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/8/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface LoginManager : NSObject
@property (nonatomic, assign) BOOL isHandlingLogin;           // 是否正在处理登录
@property (nonatomic, weak) UIViewController *currentLoginVC; // 当前登录页引用

+ (instancetype)sharedManager;
// 处理登录过期（301）
- (void)handleLoginExpired;
/// 判断是否登录，如果没有登录就跳转到登录页
+ (BOOL)checkLoginAndPresentIfNeededFrom:(UIViewController *)vc;
- (void)handleLoginExpiredWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
