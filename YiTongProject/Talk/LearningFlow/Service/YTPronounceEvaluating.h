//
//  YTPronounceEvaluating.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTScoringService.h"

@class YTUnit;

NS_ASSUME_NONNULL_BEGIN

@protocol YTPronounceEvaluating <NSObject>

/// 录音评分：`unit` 用于 `/talk/complete`（scene/level/ref_table 等）；`expectedText` 为展示/兜底文案
- (void)evaluateRecordingAtURL:(NSURL *)fileURL
                          unit:(YTUnit *)unit
                  expectedText:(NSString *)expectedText
                    completion:(YTScoreCallback)completion;

@end

NS_ASSUME_NONNULL_END
