//
//  YTLearningFlowBootstrapService.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

@class YTLearningFlowBootstrap;

NS_ASSUME_NONNULL_BEGIN

typedef void (^YTLearningFlowBootstrapCompletion)(YTLearningFlowBootstrap * _Nullable bootstrap,
                                                  NSError * _Nullable error);

/// 学习流启动服务：进入某个 scene + level 后，一次性返回内容与进度快照
@protocol YTLearningFlowBootstrapService <NSObject>

- (void)fetchBootstrapForSceneId:(NSString *)sceneId
                         levelId:(NSInteger)levelId
                      completion:(YTLearningFlowBootstrapCompletion)completion;

@end

NS_ASSUME_NONNULL_END
