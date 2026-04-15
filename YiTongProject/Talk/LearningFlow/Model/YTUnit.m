//
//  YTUnit.m
//  YiTongProject
//

#import "YTUnit.h"

@implementation YTUnit

- (instancetype)init {
    self = [super init];
    if (self) {
        _stepIndex = 0;
        _levelId = YTLevelIdBeginner;
        _unitType = YTUnitTypePronounce;
        _answeredCorrectFromServer = NO;
    }
    return self;
}

- (BOOL)countsTowardProgress {
    if (self.unitType == YTUnitTypePracticeTransition || self.unitType == YTUnitTypeLevelCompletion) return NO;
    return YES;
}

- (NSString *)yt_resolvedTitleDisplayText {
    if (self.titleCN.length) return self.titleCN;
    if (self.titleEN.length) return self.titleEN;
    return self.titlePinyin ?: @"";
}

- (NSString *)yt_resolvedStemInstructionText {
    if (self.stemText.length == 0) return nil;
    NSString *t = [self.stemText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return t.length > 0 ? t : nil;
}

+ (BOOL)yt_isExerciseQuestionType:(YTUnitType)t {
    switch (t) {
        case YTUnitTypeExerciseListenChooseImage:
        case YTUnitTypeExerciseLookChooseWord:
        case YTUnitTypeExerciseChooseWordFillBlank:
        case YTUnitTypeExerciseListenChooseResponse:
        case YTUnitTypeExerciseBuildSentence:
        case YTUnitTypeExerciseCompleteDialogue:
            return YES;
        default:
            return NO;
    }
}

+ (BOOL)yt_isSelectedOptionExerciseType:(YTUnitType)t {
    switch (t) {
        case YTUnitTypeExerciseListenChooseImage:
        case YTUnitTypeExerciseLookChooseWord:
        case YTUnitTypeExerciseChooseWordFillBlank:
        case YTUnitTypeExerciseListenChooseResponse:
        case YTUnitTypeExerciseCompleteDialogue:
            return YES;
        default:
            return NO;
    }
}

- (BOOL)yt_isListeningExercise {
    YTUnitType t = self.unitType;
    return t == YTUnitTypeExerciseListenChooseImage || t == YTUnitTypeExerciseListenChooseResponse;
}

- (NSString *)yt_displayCorrectAnswerText {
    if (self.unitType == YTUnitTypeExerciseChooseWordFillBlank) {
        if (self.correctFillTexts.count > 0) {
            return [self.correctFillTexts componentsJoinedByString:@"，"];
        }
    }
    if (self.unitType == YTUnitTypeExerciseBuildSentence) {
        if (self.correctSentenceText.length > 0) {
            return self.correctSentenceText;
        }
    }
    if ([[self class] yt_isSelectedOptionExerciseType:self.unitType] && self.correctOptionId.length > 0) {
        for (NSDictionary *opt in self.options) {
            if (![opt isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            id oid = opt[@"id"];
            NSString *os = [oid isKindOfClass:[NSString class]] ? (NSString *)oid : [NSString stringWithFormat:@"%@", oid];
            if (![os isEqualToString:self.correctOptionId]) {
                continue;
            }
            id t = opt[@"text"];
            if ([t isKindOfClass:[NSString class]] && [(NSString *)t length] > 0) {
                return (NSString *)t;
            }
        }
    }
    return @"";
}

@end

