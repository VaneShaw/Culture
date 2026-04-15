//
//  YTDifficultyTheme.h
//  YiTongProject
//

#import <UIKit/UIKit.h>
#import "YTUnit.h"

NS_ASSUME_NONNULL_BEGIN

@interface YTDifficultyTheme : NSObject

/**
 难度主题 Token（MVP）
 
 设计意图：
 - 三种难度不同主色/背景色，但 UI 组件的“意义色”一致（正确/错误）
 - 题型 Presenter 不直接写死颜色，只消费 theme token
 */
@property (nonatomic, assign) YTLevelId levelId;

@property (nonatomic, strong) UIColor *backgroundColor;
/// 主操作色（底栏主按钮、正确反馈弹窗主按钮等，见 `YTDepthPrimaryButton`）
@property (nonatomic, strong) UIColor *primaryColor;
@property (nonatomic, strong) UIColor *progressTintColor;

/// 聊天气泡：左侧/题干（听音回应、完成对话问题侧等），全难度统一 #F2F2F2
@property (nonatomic, strong) UIColor *chatPromptBubbleBackgroundColor;
/// 聊天气泡：右侧作答浅底（完成对话答案侧等，随难度区分于中等蓝 / 困难紫）
@property (nonatomic, strong) UIColor *chatAnswerBubbleBackgroundColor;

/// 对/错反馈色：跨难度保持一致，增强学习反馈的稳定性
@property (nonatomic, strong) UIColor *correctColor;
@property (nonatomic, strong) UIColor *wrongColor;

/// 根据难度返回对应主题（可在此集中调整三难度配色）
+ (instancetype)themeForLevel:(YTLevelId)levelId;

@end

NS_ASSUME_NONNULL_END

