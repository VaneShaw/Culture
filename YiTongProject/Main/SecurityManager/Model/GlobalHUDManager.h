//
//  GlobalHUDManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/19.
//

#import <Foundation/Foundation.h>
@class MBProgressHUD;

@interface GlobalHUDManager : NSObject

+ (instancetype)shared;

/// 显示 HUD（支付 / 网络）
- (void)show;

/// 仅转圈，不展示任何文案（不等同于 `showOrUpdateMessage:nil`，后者会显示「处理中…」）
- (void)showSpinnerOnly;

/// 主动隐藏（成功 / 失败）
- (void)hide;

/// 强制兜底隐藏（异常 / 重置）
- (void)forceHideAll;

//- (void)showWithMessage:(NSString *)message;

- (void)showOrUpdateMessage:(NSString *)message;
@end


