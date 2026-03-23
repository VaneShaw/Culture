//
//  YTTipAlertView.h
//  YiTongProject
//
//  通用居中提示弹窗（标题 + 正文 + 关闭 + 主按钮）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTTipAlertView : UIView

/// 在指定父视图上展示；`title` / `buttonTitle` 传 nil 时使用本地化默认「提示」「知道了」
+ (instancetype)showInView:(UIView *)parentView
                     title:(nullable NSString *)title
                   message:(NSString *)message
               buttonTitle:(nullable NSString *)buttonTitle
                   onClose:(nullable dispatch_block_t)onClose
                 onConfirm:(nullable dispatch_block_t)onConfirm;

/// 仅传正文时的快捷方法
+ (instancetype)showInView:(UIView *)parentView message:(NSString *)message;

- (void)dismissAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
