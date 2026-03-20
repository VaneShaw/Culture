//
//  YTMockUnitFactory.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTUnit.h"

NS_ASSUME_NONNULL_BEGIN

@interface YTMockUnitFactory : NSObject

/**
 构建学习流 Mock 数据（无接口阶段）
 
 设计意图：
 - 让 UI/交互/埋点/续学链路在无后端时也可以端到端跑通
 - 不同难度返回不同结构的 units，覆盖 PRD 第一版提及题型
 
 约定：
 - `stepIndex` 从 0 开始递增，用于进度展示与续学定位（尽量保持稳定）
 - `unitId` 在同一 scene+level 下唯一
 */
+ (NSArray<YTUnit *> *)buildUnitsForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId;

/**
 * 模拟“接口请求拉取 units”的异步场景（mock 阶段用异步延迟模拟网络耗时）
 */
+ (void)fetchUnitsForSceneId:(NSString *)sceneId
                      levelId:(YTLevelId)levelId
                    completion:(void (^)(NSArray<YTUnit *> * _Nonnull units))completion;

/// 构建完整 mock 接口响应：@{ @"units": [...], @"lastPosition": {...} }，lastPosition 模拟阶段从本地取
+ (NSDictionary *)buildMockAPIResponseForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId;

/// 将接口返回的 units 数组映射为 YTUnit
+ (NSArray<YTUnit *> *)buildUnitsFromAPIResponse:(NSArray<NSDictionary *> *)response
                                        sceneId:(NSString *)sceneId
                                        levelId:(YTLevelId)levelId;

@end

NS_ASSUME_NONNULL_END

