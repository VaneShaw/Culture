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

@end

