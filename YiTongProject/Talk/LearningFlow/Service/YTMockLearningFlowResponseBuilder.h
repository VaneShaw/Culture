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

@end

NS_ASSUME_NONNULL_END
