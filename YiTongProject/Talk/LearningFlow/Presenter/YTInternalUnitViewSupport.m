//
//  YTInternalUnitViewSupport.m
//  YiTongProject
//

#import "YTInternalUnitViewSupport.h"
#import "YTAnswerEvaluating.h"

NSDictionary *YTAnswerPayloadForSelectedOptionId(NSString *selectedOptionId) {
    if (selectedOptionId.length == 0) return nil;
    return @{YTAnswerPayloadKeySelectedOptionId: selectedOptionId};
}

NSDictionary *YTAnswerPayloadForOrderedTokenTexts(NSArray<NSString *> *orderedTokenTexts) {
    if (orderedTokenTexts.count == 0) return nil;
    return @{YTAnswerPayloadKeyOrderedTokenTexts: orderedTokenTexts};
}

NSString *YTSelectedOptionIdFromPayload(NSDictionary *payload) {
    NSString *selectedOptionId = [payload[YTAnswerPayloadKeySelectedOptionId] isKindOfClass:[NSString class]] ? payload[YTAnswerPayloadKeySelectedOptionId] : nil;
    return selectedOptionId;
}

NSArray<NSString *> *YTOrderedTokenTextsFromPayload(NSDictionary *payload) {
    NSArray *texts = [payload[YTAnswerPayloadKeyOrderedTokenTexts] isKindOfClass:[NSArray class]] ? payload[YTAnswerPayloadKeyOrderedTokenTexts] : nil;
    return texts;
}

@implementation YTBaseUnitView

- (instancetype)init {
    self = [super init];
    if (self) {
        _rootView = [[UIView alloc] init];
        _rootView.backgroundColor = [UIColor clearColor];
        _primaryState = [[YTUnitPrimaryState alloc] init];
        _primaryState.kind = YTUnitPrimaryKindContinue;
        _primaryState.title = @"Talk_Continue";
        _primaryState.enabled = YES;
    }
    return self;
}

- (void)configureWithUnit:(YTUnit *)unit
                    theme:(YTDifficultyTheme *)theme
                    audio:(YTAudioMuxService *)audio
                recording:(YTRecordingService *)recording
       pronounceEvaluator:(id<YTPronounceEvaluating>)pronounceEvaluator
          answerEvaluator:(id<YTAnswerEvaluating>)answerEvaluator
{
    self.unit = unit;
    self.theme = theme;
    self.audio = audio;
    self.recording = recording;
    self.pronounceEvaluator = pronounceEvaluator;
    self.answerEvaluator = answerEvaluator;
    self.completeSignalSatisfied = NO;
}

- (void)emitPrimaryState {
    if (self.onPrimaryStateChanged) {
        self.onPrimaryStateChanged(self.primaryState);
    }
}

- (BOOL)isUnitCompleteSignalSatisfied {
    return self.completeSignalSatisfied;
}

- (void)handlePrimaryActionWithCompletion:(void (^)(YTUnitSubmitResult * _Nullable, NSError * _Nullable))completion {
    if (completion) completion(nil, nil);
}

- (void)applyRestoredAnswerSnapshot:(NSDictionary *)snapshot {
    (void)snapshot;
}

- (void)evaluateAnswerPayload:(NSDictionary *)answerPayload
                   completion:(void (^)(YTUnitSubmitResult * _Nullable result, NSError * _Nullable error))completion
{
    id<YTAnswerEvaluating> evaluator = self.answerEvaluator;
    if (!evaluator) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"YTBaseUnitView"
                                                code:5001
                                            userInfo:@{NSLocalizedDescriptionKey: @"Missing answer evaluator"}]);
        }
        return;
    }
    [evaluator evaluateUnit:self.unit answerPayload:answerPayload completion:completion];
}

@end
