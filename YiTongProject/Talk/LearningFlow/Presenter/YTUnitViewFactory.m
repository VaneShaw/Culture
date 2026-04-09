//
//  YTUnitViewFactory.m
//  YiTongProject
//

#import "YTUnitViewFactory.h"
#import "YTInternalUnitViewSupport.h"
#import "YTChoiceExerciseUnitView.h"
#import "YTFillBlankUnitView.h"
#import "YTListenResponseUnitView.h"
#import "YTPronounceUnitView.h"
#import "YTBuildSentenceUnitView.h"
#import "YTCompleteDialogueUnitView.h"
#import "YTPracticeTransitionUnitView.h"
#import "YTLevelCompletionUnitView.h"

@implementation YTUnitPrimaryState
@end

NSString * const YTAnswerPayloadKeySelectedOptionId = @"selectedOptionId";
NSString * const YTAnswerPayloadKeyOrderedTokenTexts = @"orderedTokenTexts";
NSString * const YTAnswerPayloadKeySelectedFillOptionIds = @"selectedFillOptionIds";

@implementation YTUnitSubmitResult

- (void)setAnswerPayload:(NSDictionary *)answerPayload {
    _answerPayload = [answerPayload copy];
    _restorableAnswerPayload = [_answerPayload copy];
}

- (void)setRestorableAnswerPayload:(NSDictionary *)restorableAnswerPayload {
    _restorableAnswerPayload = [restorableAnswerPayload copy];
    _answerPayload = [_restorableAnswerPayload copy];
}
@end

#pragma mark - Factory

@implementation YTUnitViewFactory

+ (id<YTUnitViewProtocol>)buildViewForUnit:(YTUnit *)unit {
    /**
     映射规则（MVP）：
     - pronounce：统一“跟读/录音评分”交互，复用 `YTPronounceUnitView`
     - exercise_*：按 unitType 分发到不同 Presenter
     *
     扩展方式：
     - 新增题型时：新增 Presenter 类，并在此处补一条分支
     */
    if (unit.unitType == YTUnitTypePracticeTransition) {
        return [[YTPracticeTransitionUnitView alloc] init];
    }
    if (unit.unitType == YTUnitTypeLevelCompletion) {
        return [[YTLevelCompletionUnitView alloc] init];
    }
    if (unit.unitType == YTUnitTypePronounce) {
        return [[YTPronounceUnitView alloc] init];
    }
    if (unit.unitType == YTUnitTypeExerciseListenChooseImage ||
        unit.unitType == YTUnitTypeExerciseLookChooseWord) {
        return [[YTChoiceExerciseUnitView alloc] init];
    }
    if (unit.unitType == YTUnitTypeExerciseChooseWordFillBlank) {
        return [[YTFillBlankUnitView alloc] init];
    }
    if (unit.unitType == YTUnitTypeExerciseListenChooseResponse) {
        return [[YTListenResponseUnitView alloc] init];
    }
    if (unit.unitType == YTUnitTypeExerciseBuildSentence) {
        return [[YTBuildSentenceUnitView alloc] init];
    }
    if (unit.unitType == YTUnitTypeExerciseCompleteDialogue) {
        return [[YTCompleteDialogueUnitView alloc] init];
    }
    return [[YTBaseUnitView alloc] init];
}

@end
