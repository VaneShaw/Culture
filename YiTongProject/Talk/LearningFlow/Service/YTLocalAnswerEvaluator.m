//
//  YTLocalAnswerEvaluator.m
//  YiTongProject
//

#import "YTLocalAnswerEvaluator.h"

static NSString *YTLocalAnswerEvaluatorCorrectOptionTextForUnit(YTUnit *unit) {
    for (NSDictionary *opt in unit.options) {
        if ([opt[@"id"] isEqual:unit.correctOptionId]) {
            return [opt[@"text"] isKindOfClass:[NSString class]] ? opt[@"text"] : @"";
        }
    }
    return @"";
}

@implementation YTLocalAnswerEvaluator

+ (instancetype)shared {
    static YTLocalAnswerEvaluator *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[YTLocalAnswerEvaluator alloc] init];
    });
    return service;
}

- (void)evaluateUnit:(YTUnit *)unit
       answerPayload:(NSDictionary *)answerPayload
          completion:(void (^)(YTUnitSubmitResult * _Nullable result,
                               NSError * _Nullable error))completion
{
    if (!unit) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"YTLocalAnswerEvaluator"
                                                code:4000
                                            userInfo:@{NSLocalizedDescriptionKey: @"Missing unit"}]);
        }
        return;
    }

    YTUnitSubmitResult *result = [[YTUnitSubmitResult alloc] init];
    BOOL isCorrect = NO;

    if ([YTUnit yt_isSelectedOptionExerciseType:unit.unitType]) {
        NSString *selectedOptionId = [answerPayload[YTAnswerPayloadKeySelectedOptionId] isKindOfClass:[NSString class]] ? answerPayload[YTAnswerPayloadKeySelectedOptionId] : @"";
        isCorrect = [selectedOptionId isEqualToString:unit.correctOptionId ?: @""];
        result.isCorrect = isCorrect;
        if (isCorrect) {
            result.answerPayload = answerPayload;
        } else {
            result.correctAnswerText = YTLocalAnswerEvaluatorCorrectOptionTextForUnit(unit);
        }
    } else if (unit.unitType == YTUnitTypeExerciseBuildSentence) {
        NSArray *orderedTokenTexts = [answerPayload[YTAnswerPayloadKeyOrderedTokenTexts] isKindOfClass:[NSArray class]] ? answerPayload[YTAnswerPayloadKeyOrderedTokenTexts] : nil;
        NSMutableArray<NSString *> *parts = [NSMutableArray array];
        for (id obj in orderedTokenTexts) {
            if ([obj isKindOfClass:[NSString class]]) {
                [parts addObject:obj];
            }
        }
        NSString *answer = [parts componentsJoinedByString:@""];
        NSString *correct = unit.correctSentenceText ?: @"";
        isCorrect = (correct.length > 0) ? [answer isEqualToString:correct] : YES;
        result.isCorrect = isCorrect;
        if (isCorrect) {
            result.answerPayload = answerPayload;
        } else {
            result.correctAnswerText = correct;
        }
    } else {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"YTLocalAnswerEvaluator"
                                                code:4002
                                            userInfo:@{NSLocalizedDescriptionKey: @"Unsupported unit type"}]);
        }
        return;
    }

    if (completion) completion(result, nil);
}

@end
