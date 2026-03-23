//
//  YTMockLearningFlowBootstrapService.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTLearningFlowBootstrapService.h"

NS_ASSUME_NONNULL_BEGIN

/// Mock 启动服务：当前阶段用本地 mock 内容 + 本地进度拼装 bootstrap
@interface YTMockLearningFlowBootstrapService : NSObject <YTLearningFlowBootstrapService>

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
