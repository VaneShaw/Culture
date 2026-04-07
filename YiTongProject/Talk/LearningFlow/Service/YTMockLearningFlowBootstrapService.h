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

/// 列表页进入学习流时可注入真实场景数值 id；<=0 时自动回退本地 mock。
@property (nonatomic, assign) NSInteger talkSceneNumericId;

@end

NS_ASSUME_NONNULL_END
