//
//  YTLearningFlowProgressUtils.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

@class YTUnit;

NS_ASSUME_NONNULL_BEGIN

@interface YTLearningFlowProgressUtils : NSObject

/// 与容器页进度一致：已完成且计入进度的 unit 数 / 计入进度的总数
+ (CGFloat)progressRatioForUnits:(NSArray<YTUnit *> *)units completedUnitIdentifiers:(NSSet<NSString *> *)completedIds;

@end

NS_ASSUME_NONNULL_END
