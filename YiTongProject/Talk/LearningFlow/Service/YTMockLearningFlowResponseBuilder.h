//
//  YTMockLearningFlowResponseBuilder.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTUnit.h"

NS_ASSUME_NONNULL_BEGIN

/// 仅负责构建 mock 接口响应字典，不做模型映射
@interface YTMockLearningFlowResponseBuilder : NSObject

+ (NSDictionary *)buildResponseForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId;

/// 与工厂插入的「练习前过渡」unit 一致，供 `YTMockUnitFactory` 映射为 `YTUnit`
+ (NSDictionary *)practiceTransitionUnitPayloadForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId;
/// 与工厂追加的「本难度完成」unit 一致
+ (NSDictionary *)levelCompletionUnitPayloadForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId;

@end

NS_ASSUME_NONNULL_END
