//
//  YTLearningFlowBootstrap.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

@class YTUnit;
@class YTLastPosition;

NS_ASSUME_NONNULL_BEGIN

/// 学习流启动快照：进入某个 scene + level 后，一次性拿到内容与进度状态
@interface YTLearningFlowBootstrap : NSObject

@property (nonatomic, copy) NSArray<YTUnit *> *units;
@property (nonatomic, strong, nullable) YTLastPosition *lastPosition;
/// 与 `units` 下标对齐：接口每行 `is_unit_completed`/`is_line_completed` 为 1 时的步序号（0-based），同一 `unit_id` 多步不会合并
@property (nonatomic, copy) NSArray<NSNumber *> *completedStepIndices;
/// 兼容：按 `unit_id` 汇总（同 id 多步在 Set 里会合并，仅作展示/旧逻辑，解锁请以 `completedStepIndices` 为准）
@property (nonatomic, copy) NSArray<NSString *> *completedUnitIds;

@end

NS_ASSUME_NONNULL_END
