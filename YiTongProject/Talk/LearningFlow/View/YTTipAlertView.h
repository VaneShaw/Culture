//
//  YTTipAlertView.h
//  YiTongProject
//
//  通用居中提示弹窗：顶部标题、中间正文、底部按钮文案均在初始化时由外部传入（内部不写死默认文案）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTTipAlertView : UIView

/// `secondaryButtonTitle` 非空时为双按钮模式（无关闭叉）；否则为单按钮模式（有关闭叉）。
/// - `topTitle`：顶部提示；nil 或空字符串时默认展示本地化「提示」（`Talk_Alert_DefaultTopTitle`）。
/// - `contentText`：中间正文（必传非空）。
/// - `primaryButtonTitle`：单按钮时为主按钮文案；双按钮时为左侧按钮文案（可为 @""，由业务决定）。
/// - `secondaryButtonTitle`：仅双按钮模式使用，为右侧按钮文案。
/// - 回调：单按钮点主按钮 → `onConfirm`，点叉 → `onClose`；双按钮点左 → `onConfirm`，点右 → `onCancel`。
+ (instancetype)showInView:(UIView *)parentView
                  topTitle:(nullable NSString *)topTitle
               contentText:(NSString *)contentText
        primaryButtonTitle:(nullable NSString *)primaryButtonTitle
       secondaryButtonTitle:(nullable NSString *)secondaryButtonTitle
                    onClose:(nullable dispatch_block_t)onClose
                 onConfirm:(nullable dispatch_block_t)onConfirm
                  onCancel:(nullable dispatch_block_t)onCancel;

/// 兼容旧调用：等价于单按钮模式，`title` → `topTitle`，`message` → `contentText`，`buttonTitle` → `primaryButtonTitle`
+ (instancetype)showInView:(UIView *)parentView
                     title:(nullable NSString *)title
                   message:(NSString *)message
               buttonTitle:(nullable NSString *)buttonTitle
                   onClose:(nullable dispatch_block_t)onClose
                 onConfirm:(nullable dispatch_block_t)onConfirm;

- (void)dismissAnimated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
