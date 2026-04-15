//
//  YTDepthPrimaryButton.h
//  YiTongProject
//
//  场景对话：带底部「厚度」的主操作按钮（主题色面片 + 下移的深色胶囊）。
//  学习流底栏、对/错结果弹窗等共用；新难度只需换 faceColor（或换 darkeningFactor / 自定义 depthColor）。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTDepthPrimaryButton : UIView

/// 承接标题、图片、点击，背景透明
@property (nonatomic, strong, readonly) UIButton *actionButton;

/// 主题面颜色（如 `YTDifficultyTheme.primaryColor`）；设置后会刷新底层（见 depthColor / depthDarkeningFactor）
@property (nonatomic, strong) UIColor *faceColor;

/// 非 nil 时固定底层色；nil 时由 `faceColor` + `depthDarkeningFactor` 自动计算
@property (nonatomic, strong, nullable) UIColor *depthColor;

/// 自动底层色 = face 的 RGB 乘以该系数（默认 0.78）；新难度一般只调主色即可，必要时再微调此值
@property (nonatomic, assign) CGFloat depthDarkeningFactor;

@property (nonatomic, assign, readonly) CGFloat faceHeight;
@property (nonatomic, assign, readonly) CGFloat depthOffset;
@property (nonatomic, readonly) CGFloat totalHeight;

+ (UIColor *)autoDepthColorForFaceColor:(UIColor *)faceColor darkeningFactor:(CGFloat)factor;

/// 学习流底栏：面片 54pt、下移 5pt（与左右箭头高度对齐）
+ (instancetype)learningFlowPrimaryButton;

/// 答题结果弹窗：面片 52pt、下移 5pt（接近原弹窗主按钮视觉高度）
+ (instancetype)answerResultSheetPrimaryButton;

- (instancetype)initWithFaceHeight:(CGFloat)faceHeight depthOffset:(CGFloat)depthOffset NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
