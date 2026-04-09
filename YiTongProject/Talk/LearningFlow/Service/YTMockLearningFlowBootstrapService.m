//
//  YTMockLearningFlowBootstrapService.m
//  YiTongProject
//

#import "YTMockLearningFlowBootstrapService.h"
#import "YTLearningFlowBootstrap.h"
#import "YTUnitMapper.h"
#import "YTLastPosition.h"
#import "NSDictionary+YTSafe.h"
#import "HeaderConfig.h"

NSString *const YTTalkLearningFlowBootstrapErrorDomain = @"YTTalkLearningFlowBootstrap";

@implementation YTMockLearningFlowBootstrapService

+ (instancetype)shared {
    static YTMockLearningFlowBootstrapService *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[YTMockLearningFlowBootstrapService alloc] init];
    });
    return s;
}

/// `/talk/level` 返回的等级记录 id 与学习流展示枚举不同，这里做一次稳定映射。
- (YTLevelId)yt_displayLevelIdFromRequestLevelId:(NSInteger)levelId {
    if (levelId <= 1) return YTLevelIdBeginner;
    if (levelId == 2) return YTLevelIdIntermediate;
    return YTLevelIdAdvanced;
}

- (void)yt_finishOnMain:(YTLearningFlowBootstrapCompletion)completion
              bootstrap:(YTLearningFlowBootstrap * _Nullable)bootstrap
                  error:(NSError * _Nullable)error {
    if (!completion) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(bootstrap, error);
    });
}

/// 服务端 `is_unit_completed` / `is_line_completed` 任一为 1 即视为该步完成，映射为学习流完成集合。
- (NSArray<NSString *> *)yt_completedUnitIdsFromUnits:(NSArray<YTUnit *> *)units rawData:(NSArray *)data {
    NSMutableArray<NSString *> *completed = [NSMutableArray array];
    NSInteger count = MIN(units.count, data.count);
    for (NSInteger i = 0; i < count; i++) {
        NSDictionary *payload = [data[i] isKindOfClass:[NSDictionary class]] ? (NSDictionary *)data[i] : nil;
        YTUnit *unit = units[i];
        if (!payload || unit.unitId.length == 0) continue;
        BOOL done = ([payload yt_integerForKey:@"is_unit_completed" defaultValue:0] == 1)
            || ([payload yt_integerForKey:@"is_line_completed" defaultValue:0] == 1);
        if (done) {
            [completed addObject:unit.unitId];
        }
    }
    return [completed copy];
}

/// 用接口 `user_position.is_current` 恢复当前续学步；无则 `lastPosition` 为 nil。
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
            NSString *exerciseType = [[YTUnitMapper yt_resolvedContentFromTalkUnitPayload:payload] yt_stringForKey:@"exercise_type"];
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

- (void)fetchBootstrapForSceneId:(NSString *)sceneId
                         levelId:(NSInteger)levelId
                      completion:(YTLearningFlowBootstrapCompletion)completion {
    if (!completion) return;
    if (self.talkSceneNumericId <= 0) {
        NSError *err = [NSError errorWithDomain:YTTalkLearningFlowBootstrapErrorDomain
                                            code:1
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"无效场景，无法加载学习流", @"")}];
        [self yt_finishOnMain:completion bootstrap:nil error:err];
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
            NSError *err = [NSError errorWithDomain:YTTalkLearningFlowBootstrapErrorDomain
                                                code:2
                                            userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"学习流数据异常", @"")}];
            [self yt_finishOnMain:completion bootstrap:nil error:err];
            return;
        }

        NSArray *rawData = (NSArray *)response.data;
        YTLevelId displayLevel = [self yt_displayLevelIdFromRequestLevelId:levelId];
        NSArray<YTUnit *> *units = [YTUnitMapper mapUnitsFromResponse:(NSArray<NSDictionary *> *)rawData sceneId:sceneId levelId:displayLevel];
        NSArray<NSString *> *completedUnitIds = [self yt_completedUnitIdsFromUnits:units rawData:rawData];
        YTLastPosition *apiLastPosition = [self yt_lastPositionFromTalkUnitData:rawData sceneId:sceneId displayLevel:displayLevel];

        YTLearningFlowBootstrap *bootstrap = [[YTLearningFlowBootstrap alloc] init];
        bootstrap.units = units ?: @[];
        bootstrap.lastPosition = apiLastPosition;
        bootstrap.completedUnitIds = completedUnitIds ?: @[];
        [self yt_finishOnMain:completion bootstrap:bootstrap error:nil];
    } failure:^(NSError * _Nonnull error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        [self yt_finishOnMain:completion bootstrap:nil error:error];
    }];
}

@end
