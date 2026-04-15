//
//  YTMockLearningFlowBootstrapService.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTLearningFlowBootstrapService.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const YTTalkLearningFlowBootstrapErrorDomain;

/// 学习流启动：仅请求 `POST /talk/unit`，无本地题目数据兜底。
@interface YTMockLearningFlowBootstrapService : NSObject <YTLearningFlowBootstrapService>

+ (instancetype)shared;

/// 与 `/talk/scene` 列表项 `id` 一致；<=0 时 `fetchBootstrap` 失败（不加载本地 Mock）。
@property (nonatomic, assign) NSInteger talkSceneNumericId;

@end

NS_ASSUME_NONNULL_END
