//
//  YTUnitViewProtocol.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YTUnit.h"
#import "YTDifficultyTheme.h"
#import "YTAudioMuxService.h"
#import "YTRecordingService.h"
#import "YTScoringService.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTUnitPrimaryKind) {
    YTUnitPrimaryKindSubmit = 0,
    YTUnitPrimaryKindContinue = 1,
    YTUnitPrimaryKindGotIt = 2,
    YTUnitPrimaryKindRecord = 3,
};

@interface YTUnitPrimaryState : NSObject
@property (nonatomic, assign) YTUnitPrimaryKind kind;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL enabled;
@end

@interface YTUnitSubmitResult : NSObject
@property (nonatomic, assign) BOOL isCorrect;
@property (nonatomic, copy, nullable) NSString *correctAnswerText;
/// 仅答对时填充：用于续学「继续」时恢复选项/句子（本地持久化或对接后台同结构）
@property (nonatomic, copy, nullable) NSDictionary *restorableAnswerPayload;
@end

typedef void (^YTUnitPrimaryStateChanged)(YTUnitPrimaryState *state);

/// Unit View 统一协议：容器只通过此协议驱动 UI 与主按钮
///
/// 设计目标：
/// - 让容器“完全不懂题型细节”，只负责装载 view、转发主按钮点击、展示 toast/进度
/// - 题型 Presenter 内部维护自己的状态机，并通过 `onPrimaryStateChanged` 告诉容器主按钮应该怎么显示
@protocol YTUnitViewProtocol <NSObject>

@property (nonatomic, strong, readonly) UIView *rootView;
@property (nonatomic, copy, nullable) YTUnitPrimaryStateChanged onPrimaryStateChanged;

- (void)configureWithUnit:(YTUnit *)unit
                    theme:(YTDifficultyTheme *)theme
                    audio:(YTAudioMuxService *)audio
                recording:(YTRecordingService *)recording
                  scoring:(YTScoringService *)scoring;

/// 续学「继续」或后台下发：恢复已答对题目的 UI（payload 与 `restorableAnswerPayload` 同结构）
- (void)applyRestoredAnswerSnapshot:(NSDictionary *)snapshot;

/// 容器点击底部主按钮时调用；不同 kind 会走不同逻辑
///
/// 约定（MVP）：
/// - 选择题：返回 `submitResult`（含对错与正确答案文本）
/// - 其它题型：一般返回 nil（容器依据 `isUnitCompleteSignalSatisfied` 决定是否计入完成）
- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable submitResult,
                                                   NSError * _Nullable error))completion;

/// 当前 unit 是否已“达成完成条件”（仅对计入进度的 unit 有意义）
- (BOOL)isUnitCompleteSignalSatisfied;

@optional
/// 可选：当用户在“答错弹窗”点击按钮（Got it）后，题面是否需要重置以便重做
/// - 仅对部分题型有意义（如句子组装需要把已选词块退回）
- (void)resetAfterWrongAnswerIfNeeded;

@end

NS_ASSUME_NONNULL_END

