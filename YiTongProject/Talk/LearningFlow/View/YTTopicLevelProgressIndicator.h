//
//  YTTopicLevelProgressIndicator.h
//  YiTongProject
//
//  话题难度卡片右侧进度：未开始(箭头) / 进行中(圆环) / 已完成(圆+勾)
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YTDifficultyTheme;

@interface YTTopicLevelProgressIndicator : UIView

/// 本地进度 0~1；`theme` 用于配色。箭头切图名 `talk_topic_level_not_started`，无图时用系统箭头占位。
- (void)configureWithProgressRatio:(CGFloat)progressRatio theme:(YTDifficultyTheme *)theme;

@end

NS_ASSUME_NONNULL_END
