//
//  YTTalkLearningDataService.h
//  YiTongProject
//
//  学习流本地进度/续学存储服务
//  当前仅负责：续学位置、已完成列表、答对后的可恢复答案
//

#import <Foundation/Foundation.h>
#import "YTLearningProgressStoring.h"

@class YTLastPosition;

NS_ASSUME_NONNULL_BEGIN

@interface YTTalkLearningDataService : NSObject <YTLearningProgressStoring>

+ (instancetype)shared;

/// 同步读取本地已完成单元（仅本地缓存场景使用，避免 UI 依赖异步回调时序）
- (NSArray<NSString *> *)completedUnitIdsForSceneId:(NSString *)sceneId levelId:(NSInteger)levelId;

@end

NS_ASSUME_NONNULL_END
