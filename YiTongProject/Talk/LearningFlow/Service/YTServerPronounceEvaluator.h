//
//  YTServerPronounceEvaluator.h
//  录音题：POST /talk/complete，上传 read_audio，以返回 success / raw_score 为准
//

#import <Foundation/Foundation.h>
#import "YTPronounceEvaluating.h"

NS_ASSUME_NONNULL_BEGIN

@interface YTServerPronounceEvaluator : NSObject <YTPronounceEvaluating>

/// `progress_percent`（0～100）回调，用于更新学习流顶部进度
- (instancetype)initWithProgressPercentHandler:(void (^ _Nullable)(NSInteger percent))onProgressPercent;

@end

NS_ASSUME_NONNULL_END
