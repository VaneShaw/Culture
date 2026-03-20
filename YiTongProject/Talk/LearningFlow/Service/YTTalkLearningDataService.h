//
//  YTTalkLearningDataService.h
//  YiTongProject
//
//  模拟学习数据接口：获取内容时返回 units + lastPosition + completedUnitIds
//  进入新步骤时调用保存接口更新当前页面；实际实现仍用本地 NSUserDefaults
//

#import <Foundation/Foundation.h>

@class YTUnit;
@class YTLastPosition;

NS_ASSUME_NONNULL_BEGIN

/// 获取学习数据回调：units、lastPosition（可为 nil）、completedUnitIds
typedef void (^YTTalkLearningDataCompletion)(NSArray<YTUnit *> *units,
                                             YTLastPosition * _Nullable lastPosition,
                                             NSArray<NSString *> *completedUnitIds,
                                             NSError * _Nullable error);

@interface YTTalkLearningDataService : NSObject

+ (instancetype)shared;

/// 模拟接口：点击难度获取内容，返回 units + 上次学习位置 + 已完成列表
- (void)fetchLearningDataForSceneId:(NSString *)sceneId
                            levelId:(NSInteger)levelId
                         completion:(YTTalkLearningDataCompletion)completion;

/// 模拟接口：进入新步骤时调用，更新当前用户所在页面
- (void)saveCurrentPositionForSceneId:(NSString *)sceneId
                              levelId:(NSInteger)levelId
                              unitId:(NSString *)unitId
                            stepIndex:(NSInteger)stepIndex
                            unitType:(NSInteger)unitType
                           completion:(void (^)(NSError * _Nullable error))completion;

/// 保存「本题答对」时的可恢复答案（续学「继续」时预填）；对接后台后结构可与接口字段对齐
- (void)saveCorrectAnswerSnapshotForUnitId:(NSString *)unitId
                                    sceneId:(NSString *)sceneId
                                    levelId:(NSInteger)levelId
                                    payload:(NSDictionary *)payload;

- (nullable NSDictionary *)answerSnapshotPayloadForUnitId:(NSString *)unitId
                                                 sceneId:(NSString *)sceneId
                                                 levelId:(NSInteger)levelId;

/// 从头开始时清空本关已存答案快照
- (void)clearAnswerSnapshotsForSceneId:(NSString *)sceneId levelId:(NSInteger)levelId;

/// 从头开始时清空续学锚点，避免下次进入仍弹出「继续上次」
- (void)clearLastPositionForSceneId:(NSString *)sceneId levelId:(NSInteger)levelId;

@end

NS_ASSUME_NONNULL_END
