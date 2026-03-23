//
//  YTTalkLearningDataService.m
//  YiTongProject
//

#import "YTTalkLearningDataService.h"
#import "YTLastPosition.h"
#import "HeaderConfig.h"

static NSString *const kLastPositionKeyPrefix = @"talk_last_position";
static NSString *const kCompletedUnitsKeyPrefix = @"talk_completed_units";
static NSString *const kAnswerSnapshotsKeyPrefix = @"talk_answer_snapshots";

@implementation YTTalkLearningDataService

+ (instancetype)shared {
    static YTTalkLearningDataService *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[YTTalkLearningDataService alloc] init];
    });
    return s;
}

- (NSString *)lastPositionKeyForSceneId:(NSString *)sceneId levelId:(NSInteger)levelId {
    return [NSString stringWithFormat:@"%@_%@_%ld", kLastPositionKeyPrefix, sceneId ?: @"", (long)levelId];
}

- (NSString *)completedUnitsKeyForSceneId:(NSString *)sceneId levelId:(NSInteger)levelId {
    return [NSString stringWithFormat:@"%@_%@_%ld", kCompletedUnitsKeyPrefix, sceneId ?: @"", (long)levelId];
}

- (NSString *)answerSnapshotsKeyForSceneId:(NSString *)sceneId levelId:(NSInteger)levelId {
    return [NSString stringWithFormat:@"%@_%@_%ld", kAnswerSnapshotsKeyPrefix, sceneId ?: @"", (long)levelId];
}

- (void)saveCorrectAnswerSnapshotForUnitId:(NSString *)unitId
                                    sceneId:(NSString *)sceneId
                                    levelId:(NSInteger)levelId
                                    payload:(NSDictionary *)payload {
    if (!unitId.length || payload.count == 0) return;
    NSString *key = [self answerSnapshotsKeyForSceneId:sceneId levelId:levelId];
    NSMutableDictionary *all = [NSMutableDictionary dictionary];
    id raw = [KUSER_DEFAULT objectForKey:key];
    if ([raw isKindOfClass:[NSDictionary class]]) {
        [all addEntriesFromDictionary:(NSDictionary *)raw];
    }
    all[unitId] = payload;
    [KUSER_DEFAULT setObject:all forKey:key];
}

- (NSDictionary *)answerSnapshotPayloadForUnitId:(NSString *)unitId sceneId:(NSString *)sceneId levelId:(NSInteger)levelId {
    if (!unitId.length) return nil;
    NSString *key = [self answerSnapshotsKeyForSceneId:sceneId levelId:levelId];
    id raw = [KUSER_DEFAULT objectForKey:key];
    if (![raw isKindOfClass:[NSDictionary class]]) return nil;
    id one = ((NSDictionary *)raw)[unitId];
    return [one isKindOfClass:[NSDictionary class]] ? one : nil;
}

- (void)clearAnswerSnapshotsForSceneId:(NSString *)sceneId levelId:(NSInteger)levelId {
    NSString *key = [self answerSnapshotsKeyForSceneId:sceneId levelId:levelId];
    [KUSER_DEFAULT removeObjectForKey:key];
}

- (void)clearLastPositionForSceneId:(NSString *)sceneId levelId:(NSInteger)levelId {
    NSString *key = [self lastPositionKeyForSceneId:sceneId levelId:levelId];
    [KUSER_DEFAULT removeObjectForKey:key];
}

- (void)fetchLearningProgressForSceneId:(NSString *)sceneId
                                levelId:(NSInteger)levelId
                             completion:(YTLearningProgressCompletion)completion {
    if (!completion) return;
    NSString *lastPositionKey = [self lastPositionKeyForSceneId:sceneId levelId:levelId];
    id lastPositionRaw = [KUSER_DEFAULT objectForKey:lastPositionKey];
    if ([lastPositionRaw isKindOfClass:[NSNull class]]) lastPositionRaw = nil;
    YTLastPosition *lastPosition = [YTLastPosition fromDictionary:lastPositionRaw];

    NSArray *arr = [KUSER_DEFAULT objectForKey:[self completedUnitsKeyForSceneId:sceneId levelId:levelId]];
    NSMutableArray<NSString *> *completed = [NSMutableArray array];
    if ([arr isKindOfClass:[NSArray class]]) {
        for (id v in arr) {
            if ([v isKindOfClass:[NSString class]]) [completed addObject:v];
        }
    }
    completion(lastPosition, [completed copy], nil);
}

- (void)saveCurrentPositionForSceneId:(NSString *)sceneId
                              levelId:(NSInteger)levelId
                              unitId:(NSString *)unitId
                            stepIndex:(NSInteger)stepIndex
                            unitType:(NSInteger)unitType
                           completion:(void (^)(NSError * _Nullable))completion {
    if (!unitId.length) {
        if (completion) completion(nil);
        return;
    }
    YTLastPosition *pos = [[YTLastPosition alloc] init];
    pos.sceneId = sceneId;
    pos.levelId = (YTLevelId)levelId;
    pos.unitId = unitId;
    pos.stepIndex = stepIndex;
    pos.unitType = (YTUnitType)unitType;
    pos.timestamp = [NSDate date].timeIntervalSince1970;
    NSString *key = [self lastPositionKeyForSceneId:sceneId levelId:levelId];
    [KUSER_DEFAULT setObject:[pos toDictionary] forKey:key];
    // 模拟接口延迟 0.3s
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (completion) completion(nil);
    });
}

@end
