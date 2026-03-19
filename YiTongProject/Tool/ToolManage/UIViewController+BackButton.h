//
//  UIViewController+BackButton.h
//  YiTongProject
//
//  Created by Vincent on 2025/8/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 全局返回按钮容器的 tag，用于与进度条等控件 Y 轴中心对齐
extern NSInteger const kGlobalBackButtonContainerTag;

@interface UIViewController (BackButton)
// 添加返回按钮方法
- (void)addGlobalBackButton;
- (void)addGlobalBackButtonColor:(UIColor *)color headerTitleDic:(NSDictionary *)dic;
// 全局返回方法
- (void)globalBackAction;
@end

NS_ASSUME_NONNULL_END
