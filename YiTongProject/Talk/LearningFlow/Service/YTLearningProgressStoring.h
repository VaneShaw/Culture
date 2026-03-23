//
//  YTLearningProgressStoring.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

@class YTLastPosition;

NS_ASSUME_NONNULL_BEGIN

typedef void (^YTLearningProgressCompletion)(YTLastPosition * _Nullable lastPosition,
                                             NSArray<NSString *> *completedUnitIds,
                                             NSError * _Nullable error);

@protocol YTLearningProgressStoring <NSObject>

- (void)fetchLearningProgressForSceneId:(NSString *)sceneId
                                levelId:(NSInteger)levelId
                             completion:(YTLearningProgressCompletion)completion;

- (void)saveCurrentPositionForSceneId:(NSString *)sceneId
                              levelId:(NSInteger)levelId
                               unitId:(NSString *)unitId
                            stepIndex:(NSInteger)stepIndex
                             unitType:(NSInteger)unitType
                           completion:(void (^)(NSError * _Nullable error))completion;

- (void)saveCorrectAnswerSnapshotForUnitId:(NSString *)unitId
                                   sceneId:(NSString *)sceneId
                                   levelId:(NSInteger)levelId
                                   payload:(NSDictionary *)payload;

- (nullable NSDictionary *)answerSnapshotPayloadForUnitId:(NSString *)unitId
                                                  sceneId:(NSString *)sceneId
                                                  levelId:(NSInteger)levelId;

- (void)clearAnswerSnapshotsForSceneId:(NSString *)sceneId levelId:(NSInteger)levelId;
- (void)clearLastPositionForSceneId:(NSString *)sceneId levelId:(NSInteger)levelId;

@end

NS_ASSUME_NONNULL_END
