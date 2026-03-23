//
//  YTInternalUnitViewSupport.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YTUnitViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface YTBaseUnitView : NSObject <YTUnitViewProtocol>
@property (nonatomic, strong) UIView *rootView;
@property (nonatomic, strong) YTUnit *unit;
@property (nonatomic, strong) YTDifficultyTheme *theme;
@property (nonatomic, strong) YTAudioMuxService *audio;
@property (nonatomic, strong) YTRecordingService *recording;
@property (nonatomic, strong) id<YTPronounceEvaluating> pronounceEvaluator;
@property (nonatomic, strong) id<YTAnswerEvaluating> answerEvaluator;
@property (nonatomic, copy) YTUnitPrimaryStateChanged onPrimaryStateChanged;
@property (nonatomic, strong) YTUnitPrimaryState *primaryState;
@property (nonatomic, assign) BOOL completeSignalSatisfied;

- (void)emitPrimaryState;
- (void)evaluateAnswerPayload:(NSDictionary *)answerPayload
                   completion:(void (^)(YTUnitSubmitResult * _Nullable result,
                                        NSError * _Nullable error))completion;
@end

FOUNDATION_EXPORT NSDictionary * _Nullable YTAnswerPayloadForSelectedOptionId(NSString * _Nullable selectedOptionId);
FOUNDATION_EXPORT NSDictionary * _Nullable YTAnswerPayloadForOrderedTokenTexts(NSArray<NSString *> * _Nullable orderedTokenTexts);
FOUNDATION_EXPORT NSString * _Nullable YTSelectedOptionIdFromPayload(NSDictionary * _Nullable payload);
FOUNDATION_EXPORT NSArray<NSString *> * _Nullable YTOrderedTokenTextsFromPayload(NSDictionary * _Nullable payload);

/// 第一阶段拆分：先把发音题 Presenter 的公开类名独立出去，内部实现仍复用旧代码。
@interface YTPronounceUnitViewLegacyInternal : YTBaseUnitView
@end

/// 第二阶段拆分：选择题 Presenter 的公开类名独立出去，内部实现迁出工厂文件。
@interface YTChoiceExerciseUnitViewLegacyInternal : YTBaseUnitView
@end

@interface YTFillBlankUnitViewLegacyInternal : YTBaseUnitView
@end

@interface YTListenResponseUnitViewLegacyInternal : YTBaseUnitView
@end

NS_ASSUME_NONNULL_END
