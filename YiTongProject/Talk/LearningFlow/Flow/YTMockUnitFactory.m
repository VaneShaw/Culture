//
//  YTMockUnitFactory.m
//  YiTongProject
//

#import "YTMockUnitFactory.h"
#import "YTMockLearningFlowResponseBuilder.h"
#import "YTUnitMapper.h"

static NSArray<YTUnit *> *YTInsertPracticeTransitionUnitIfNeeded(NSArray<YTUnit *> *units, NSString *sceneId, YTLevelId levelId) {
    if (units.count == 0) return units;
    for (YTUnit *u in units) {
        if (u.unitType == YTUnitTypePracticeTransition) return units;
    }
    NSInteger firstExerciseIndex = NSNotFound;
    for (NSInteger i = 0; i < units.count; i++) {
        if (units[i].unitType != YTUnitTypePronounce) {
            firstExerciseIndex = i;
            break;
        }
    }
    if (firstExerciseIndex == NSNotFound || firstExerciseIndex == 0) return units;

    YTUnit *t = [[YTUnit alloc] init];
    t.sceneId = sceneId;
    t.levelId = levelId;
    t.unitType = YTUnitTypePracticeTransition;
    t.unitId = [NSString stringWithFormat:@"%@_%ld_practice_transition", sceneId ?: @"scene", (long)levelId];

    NSMutableArray<YTUnit *> *m = [units mutableCopy];
    [m insertObject:t atIndex:firstExerciseIndex];
    for (NSInteger i = 0; i < m.count; i++) {
        m[i].stepIndex = i;
    }
    return [m copy];
}

static NSArray<YTUnit *> *YTAppendLevelCompletionUnitIfNeeded(NSArray<YTUnit *> *units, NSString *sceneId, YTLevelId levelId) {
    if (units.count == 0) return units;
    for (YTUnit *u in units) {
        if (u.unitType == YTUnitTypeLevelCompletion) return units;
    }
    YTUnit *c = [[YTUnit alloc] init];
    c.sceneId = sceneId;
    c.levelId = levelId;
    c.unitType = YTUnitTypeLevelCompletion;
    c.unitId = [NSString stringWithFormat:@"%@_%ld_level_complete", sceneId ?: @"scene", (long)levelId];
    NSMutableArray<YTUnit *> *m = [units mutableCopy];
    [m addObject:c];
    for (NSInteger i = 0; i < m.count; i++) {
        m[i].stepIndex = i;
    }
    return [m copy];
}

@implementation YTMockUnitFactory

+ (void)fetchUnitsForSceneId:(NSString *)sceneId
                      levelId:(YTLevelId)levelId
                    completion:(void (^)(NSArray<YTUnit *> * _Nonnull units))completion {
    // MVP：用固定延迟模拟接口耗时（后续接真实网络只需替换这里）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSDictionary *response = [self buildMockAPIResponseForSceneId:sceneId levelId:levelId];
        NSArray<NSDictionary *> *unitsArray = response[@"units"];
        if (![unitsArray isKindOfClass:[NSArray class]]) unitsArray = @[];
        NSArray<YTUnit *> *units = [self buildUnitsFromAPIResponse:unitsArray sceneId:sceneId levelId:levelId];
        if (completion) completion(units);
    });
}

+ (NSArray<YTUnit *> *)buildUnitsForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    NSDictionary *response = [self buildMockAPIResponseForSceneId:sceneId levelId:levelId];
    NSArray<NSDictionary *> *unitsArray = response[@"units"];
    if (![unitsArray isKindOfClass:[NSArray class]]) unitsArray = @[];
    return [self buildUnitsFromAPIResponse:unitsArray sceneId:sceneId levelId:levelId];
}

+ (NSDictionary *)buildMockAPIResponseForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    return [YTMockLearningFlowResponseBuilder buildResponseForSceneId:sceneId levelId:levelId];
}

+ (NSArray<YTUnit *> *)buildUnitsFromAPIResponse:(NSArray<NSDictionary *> *)response
                                           sceneId:(NSString *)sceneId
                                           levelId:(YTLevelId)levelId {
    return [YTUnitMapper mapUnitsFromResponse:response sceneId:sceneId levelId:levelId];
}

+ (NSArray<YTUnit *> *)learningFlowUnitsFromRawUnits:(NSArray<YTUnit *> *)rawUnits
                                             sceneId:(NSString *)sceneId
                                             levelId:(YTLevelId)levelId {
    NSArray<YTUnit *> *raw = rawUnits ?: @[];
    NSArray<YTUnit *> *withTransition = YTInsertPracticeTransitionUnitIfNeeded(raw, sceneId, levelId);
    return YTAppendLevelCompletionUnitIfNeeded(withTransition, sceneId, levelId);
}

+ (NSArray<YTUnit *> *)learningFlowUnitsForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    NSArray<YTUnit *> *raw = [self buildUnitsForSceneId:sceneId levelId:levelId];
    return [self learningFlowUnitsFromRawUnits:raw sceneId:sceneId levelId:levelId];
}

+ (CGFloat)progressRatioForUnits:(NSArray<YTUnit *> *)units completedUnitIdentifiers:(NSSet<NSString *> *)completedIds {
    NSInteger total = 0;
    NSInteger done = 0;
    NSSet<NSString *> *doneSet = completedIds ?: [NSSet set];
    for (YTUnit *u in units) {
        if (![u countsTowardProgress]) continue;
        total += 1;
        NSString *uid = u.unitId;
        if (uid.length > 0 && [doneSet containsObject:uid]) {
            done += 1;
        }
    }
    if (total <= 0) return 0;
    return (CGFloat)done / (CGFloat)total;
}

@end
