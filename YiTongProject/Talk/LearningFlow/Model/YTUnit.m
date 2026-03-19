//
//  YTUnit.m
//  YiTongProject
//

#import "YTUnit.h"

@implementation YTUnit

- (instancetype)init {
    self = [super init];
    if (self) {
        _exerciseType = YTExerciseTypeListenChooseImage;
        _stepIndex = 0;
        _levelId = YTLevelIdBeginner;
        _unitType = YTUnitTypeVocab;
    }
    return self;
}

- (BOOL)countsTowardProgress {
    /**
     是否计入进度（MVP 规则）
     
     原则：
     - “解释/总览”类页面不计进度（避免用户被迫在说明页停留）
     - “学习/练习”类页面计进度（词汇、逐句对话、练习题）
     
     可调整点：如后续接入更多“总览类”页，可在这里追加规则
     */
    if (self.unitType == YTUnitTypeGrammar) return NO;
    return YES;
}

@end

