//
//  YTAnswerResultBottomSheet.h
//  YiTongProject
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTAnswerResultBottomSheetStyle) {
    YTAnswerResultBottomSheetStyleCorrect = 0,
    YTAnswerResultBottomSheetStyleWrong = 1,
};

@interface YTAnswerResultBottomSheet : UIView

/// 统一的底部结果弹窗（对/错）
/// - Parameters:
///   - view: 挂载到的父视图（通常是 VC.view）
///   - style: Correct / Wrong
///   - title: 标题（建议传 NSLocalizedString(...) 的结果）
///   - message: 次级文案（可为空）
///   - highlight: 重点文案（可为空，如“图书馆（tú shū guǎn）”）
///   - buttonTitle: 按钮文案（建议传 NSLocalizedString(...) 的结果）
///   - onPrimary: 点击主按钮回调
+ (instancetype)showInView:(UIView *)view
                     style:(YTAnswerResultBottomSheetStyle)style
                     title:(NSString *)title
                   message:(nullable NSString *)message
                 highlight:(nullable NSAttributedString *)highlight
               buttonTitle:(NSString *)buttonTitle
                 onPrimary:(dispatch_block_t)onPrimary;

/// Correct 样式支持传入主题色（用于不同难度的主色适配）
/// - Wrong 样式仍使用统一红色规范
+ (instancetype)showInView:(UIView *)view
                     style:(YTAnswerResultBottomSheetStyle)style
                accentColor:(nullable UIColor *)accentColor
                     title:(NSString *)title
                   message:(nullable NSString *)message
                 highlight:(nullable NSAttributedString *)highlight
               buttonTitle:(NSString *)buttonTitle
                 onPrimary:(dispatch_block_t)onPrimary;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END

