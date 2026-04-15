//
//  YTResumeLearningAlertView.h
//  YiTongProject
//
//  续学提示：与 YTTipAlertView 同风格的卡片 + 圆环进度 + 继续/重新开始
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTResumeLearningAlertView : UIView

/// `progressRatio` 建议 0~1，超出会被裁剪；`title` 传 nil 时用本地化「提示」
+ (instancetype)showInView:(UIView *)parentView
               progressRatio:(CGFloat)progressRatio
                       title:(nullable NSString *)title
                  onContinue:(dispatch_block_t)onContinue
                   onRestart:(dispatch_block_t)onRestart;

- (void)dismissAnimated:(BOOL)animated completion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
