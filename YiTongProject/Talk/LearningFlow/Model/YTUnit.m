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

@end

