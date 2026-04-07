//
//  YTMockLearningFlowBootstrapService.m
//  YiTongProject
//

#import "YTMockLearningFlowBootstrapService.h"
#import "YTLearningFlowBootstrap.h"
#import "YTLearningProgressStoring.h"
#import "YTMockLearningFlowResponseBuilder.h"
#import "YTUnitMapper.h"
#import "YTTalkLearningDataService.h"
#import "YTLastPosition.h"
#import "NSDictionary+YTSafe.h"
#import "HeaderConfig.h"

@interface YTMockLearningFlowBootstrapService ()
@property (nonatomic, strong) id<YTLearningProgressStoring> progressStore;
@end

@implementation YTMockLearningFlowBootstrapService

+ (instancetype)shared {
    static YTMockLearningFlowBootstrapService *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[YTMockLearningFlowBootstrapService alloc] init];
        s.progressStore = [YTTalkLearningDataService shared];
    });
    return s;
}

/// `/talk/level` 返回的等级记录 id 与学习流展示枚举不同，这里做一次稳定映射。
- (YTLevelId)yt_displayLevelIdFromRequestLevelId:(NSInteger)levelId {
    if (levelId <= 1) return YTLevelIdBeginner;
    if (levelId == 2) return YTLevelIdIntermediate;
    return YTLevelIdAdvanced;
}

/// 本地 mock 启动：保留旧能力，便于接口失败或无数值 scene_id 时回退。
- (void)yt_fetchMockBootstrapForSceneId:(NSString *)sceneId
                                levelId:(NSInteger)levelId
                             completion:(YTLearningFlowBootstrapCompletion)completion {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *mockResponse = [YTMockLearningFlowResponseBuilder buildResponseForSceneId:sceneId levelId:(YTLevelId)levelId];
        NSArray<NSDictionary *> *unitsArray = mockResponse[@"units"];
        if (![unitsArray isKindOfClass:[NSArray class]]) unitsArray = @[];
        NSArray<YTUnit *> *units = [YTUnitMapper mapUnitsFromResponse:unitsArray sceneId:sceneId levelId:(YTLevelId)levelId];

        [self.progressStore fetchLearningProgressForSceneId:sceneId levelId:levelId completion:^(YTLastPosition * _Nullable lastPosition, NSArray<NSString *> *completedUnitIds, NSError * _Nullable error) {
            void (^finishOnMain)(YTLearningFlowBootstrap * _Nullable, NSError * _Nullable) = ^(YTLearningFlowBootstrap * _Nullable outBootstrap, NSError * _Nullable outError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(outBootstrap, outError);
                });
            };
            if (error) {
                finishOnMain(nil, error);
                return;
            }
            YTLearningFlowBootstrap *bootstrap = [[YTLearningFlowBootstrap alloc] init];
            bootstrap.units = units ?: @[];
            bootstrap.lastPosition = lastPosition;
            bootstrap.completedUnitIds = completedUnitIds ?: @[];
            finishOnMain(bootstrap, nil);
        }];
    });
}

/// 用接口 `user_position.is_current` 恢复当前续学步；若缺失则交给本地存档兜底。
- (nullable YTLastPosition *)yt_lastPositionFromTalkUnitData:(NSArray *)data
                                                     sceneId:(NSString *)sceneId
                                                displayLevel:(YTLevelId)displayLevel {
    for (NSInteger i = 0; i < data.count; i++) {
        id item = data[i];
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *payload = (NSDictionary *)item;
        NSDictionary *userPosition = [payload yt_dictionaryForKey:@"user_position"];
        if ([userPosition yt_integerForKey:@"is_current" defaultValue:0] != 1) continue;

        YTLastPosition *pos = [[YTLastPosition alloc] init];
        pos.sceneId = sceneId ?: @"";
        pos.levelId = displayLevel;
        pos.unitId = @"";
        pos.stepIndex = MAX(0, [payload yt_integerForKey:@"flat_step" defaultValue:i + 1] - 1);
        NSString *refTable = [payload yt_stringForKey:@"ref_table"];
        if ([refTable isEqualToString:@"cross"]) {
            pos.unitType = (i == data.count - 1) ? YTUnitTypeLevelCompletion : YTUnitTypePracticeTransition;
        } else if ([refTable isEqualToString:@"exercise"]) {
            NSString *exerciseType = [[payload yt_dictionaryForKey:@"content"] yt_stringForKey:@"exercise_type"];
            if ([exerciseType isEqualToString:@"listen_tap"]) pos.unitType = YTUnitTypeExerciseListenChooseImage;
            else if ([exerciseType isEqualToString:@"match_word"]) pos.unitType = YTUnitTypeExerciseLookChooseWord;
            else if ([exerciseType isEqualToString:@"word_fill"]) pos.unitType = YTUnitTypeExerciseChooseWordFillBlank;
            else if ([exerciseType isEqualToString:@"listen_respond"]) pos.unitType = YTUnitTypeExerciseListenChooseResponse;
            else if ([exerciseType isEqualToString:@"sentence_builder"]) pos.unitType = YTUnitTypeExerciseBuildSentence;
            else if ([exerciseType isEqualToString:@"complete_dialogue"]) pos.unitType = YTUnitTypeExerciseCompleteDialogue;
            else pos.unitType = YTUnitTypePronounce;
        } else {
            pos.unitType = YTUnitTypePronounce;
        }
        pos.timestamp = [[NSDate date] timeIntervalSince1970];
        return pos;
    }
    return nil;
}

/// 服务端 `is_unit_completed=1` 已是 step 维度，可直接映射为当前学习流的完成集合。
- (NSArray<NSString *> *)yt_completedUnitIdsFromUnits:(NSArray<YTUnit *> *)units rawData:(NSArray *)data {
    NSMutableArray<NSString *> *completed = [NSMutableArray array];
    NSInteger count = MIN(units.count, data.count);
    for (NSInteger i = 0; i < count; i++) {
        NSDictionary *payload = [data[i] isKindOfClass:[NSDictionary class]] ? (NSDictionary *)data[i] : nil;
        YTUnit *unit = units[i];
        if (!payload || unit.unitId.length == 0) continue;
        if ([payload yt_integerForKey:@"is_unit_completed" defaultValue:0] == 1) {
            [completed addObject:unit.unitId];
        }
    }
    return [completed copy];
}

- (void)fetchBootstrapForSceneId:(NSString *)sceneId
                         levelId:(NSInteger)levelId
                      completion:(YTLearningFlowBootstrapCompletion)completion {
    if (!completion) return;
    if (self.talkSceneNumericId <= 0) {
        [self yt_fetchMockBootstrapForSceneId:sceneId levelId:levelId completion:completion];
        return;
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    params[@"scene_id"] = @(self.talkSceneNumericId);
    params[@"level_id"] = @(levelId);

    __weak typeof(self) weakSelf = self;
    [HttpTools postRequest:@"/talk/unit" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (!success || ![response.data isKindOfClass:[NSArray class]]) {
            [self yt_fetchMockBootstrapForSceneId:sceneId levelId:[self yt_displayLevelIdFromRequestLevelId:levelId] completion:completion];
            return;
        }

        NSArray *rawData = (NSArray *)response.data;
        YTLevelId displayLevel = [self yt_displayLevelIdFromRequestLevelId:levelId];
        NSArray<YTUnit *> *units = [YTUnitMapper mapUnitsFromResponse:(NSArray<NSDictionary *> *)rawData sceneId:sceneId levelId:displayLevel];
        NSArray<NSString *> *completedUnitIds = [self yt_completedUnitIdsFromUnits:units rawData:rawData];
        YTLastPosition *apiLastPosition = [self yt_lastPositionFromTalkUnitData:rawData sceneId:sceneId displayLevel:displayLevel];

        [self.progressStore fetchLearningProgressForSceneId:sceneId levelId:displayLevel completion:^(YTLastPosition * _Nullable localLastPosition, NSArray<NSString *> *localCompletedUnitIds, NSError * _Nullable error) {
            void (^finishOnMain)(YTLearningFlowBootstrap * _Nullable, NSError * _Nullable) = ^(YTLearningFlowBootstrap * _Nullable outBootstrap, NSError * _Nullable outError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(outBootstrap, outError);
                });
            };
            if (error) {
                finishOnMain(nil, error);
                return;
            }

            NSMutableOrderedSet<NSString *> *mergedCompleted = [NSMutableOrderedSet orderedSet];
            [mergedCompleted addObjectsFromArray:localCompletedUnitIds ?: @[]];
            [mergedCompleted addObjectsFromArray:completedUnitIds ?: @[]];

            YTLearningFlowBootstrap *bootstrap = [[YTLearningFlowBootstrap alloc] init];
            bootstrap.units = units ?: @[];
            bootstrap.lastPosition = apiLastPosition ?: localLastPosition;
            bootstrap.completedUnitIds = mergedCompleted.array ?: @[];
            finishOnMain(bootstrap, nil);
        }];
    } failure:^(__unused NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self yt_fetchMockBootstrapForSceneId:sceneId levelId:[self yt_displayLevelIdFromRequestLevelId:levelId] completion:completion];
    }];
}

@end
