//
//  YTLocalAnswerEvaluator.m
//  YiTongProject
//

#import "YTLocalAnswerEvaluator.h"
#import "YTUnit.h"
#import "YTUnitViewProtocol.h"

static NSString *YTLocalAnswerEvaluatorCorrectOptionTextForUnit(YTUnit *unit) {
    if (unit.unitType == YTUnitTypeExerciseChooseWordFillBlank && unit.correctFillTexts.count > 0) {
        return [unit.correctFillTexts componentsJoinedByString:@"，"];
    }
    for (NSDictionary *opt in unit.options) {
        if ([opt[@"id"] isEqual:unit.correctOptionId]) {
            return [opt[@"text"] isKindOfClass:[NSString class]] ? opt[@"text"] : @"";
        }
    }
    return @"";
}

static NSString *YTSelectedOptionTextForUnit(YTUnit *unit, NSString *selectedOptionId) {
    if (selectedOptionId.length == 0) return nil;
    for (NSDictionary *opt in unit.options) {
        if (![opt isKindOfClass:[NSDictionary class]]) continue;
        id oid = opt[@"id"];
        NSString *oidStr = [oid isKindOfClass:[NSString class]] ? (NSString *)oid : [NSString stringWithFormat:@"%@", oid];
        if ([oidStr isEqualToString:selectedOptionId]) {
            return [opt[@"text"] isKindOfClass:[NSString class]] ? opt[@"text"] : nil;
        }
    }
    return nil;
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
        if (unit.unitType == YTUnitTypeExerciseChooseWordFillBlank && unit.correctFillTexts.count > 0) {
            NSArray *fillIds = [answerPayload[YTAnswerPayloadKeySelectedFillOptionIds] isKindOfClass:[NSArray class]] ? answerPayload[YTAnswerPayloadKeySelectedFillOptionIds] : nil;
            if (fillIds.count == unit.correctFillTexts.count) {
                BOOL allOk = YES;
                for (NSInteger i = 0; i < fillIds.count; i++) {
                    id oidObj = fillIds[i];
                    NSString *oid = [oidObj isKindOfClass:[NSString class]] ? (NSString *)oidObj : [NSString stringWithFormat:@"%@", oidObj];
                    NSString *selText = YTSelectedOptionTextForUnit(unit, oid) ?: @"";
                    id wantObj = unit.correctFillTexts[i];
                    NSString *want = [wantObj isKindOfClass:[NSString class]] ? (NSString *)wantObj : @"";
                    want = [want stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSString *selTrim = [selText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (![selTrim isEqualToString:want]) {
                        allOk = NO;
                        break;
                    }
                }
                isCorrect = allOk;
            } else {
                NSString *want = unit.correctFillTexts.firstObject ?: @"";
                NSString *selText = YTSelectedOptionTextForUnit(unit, selectedOptionId) ?: @"";
                isCorrect = (want.length > 0 && [selText isEqualToString:want]);
            }
        } else {
            isCorrect = [selectedOptionId isEqualToString:unit.correctOptionId ?: @""];
        }
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
