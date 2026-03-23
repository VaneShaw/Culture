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
@property (nonatomic, copy) NSArray<NSString *> *completedUnitIds;

@end

NS_ASSUME_NONNULL_END
