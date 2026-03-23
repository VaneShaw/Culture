//
//  YTPronounceEvaluating.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTScoringService.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YTPronounceEvaluating <NSObject>

- (void)evaluateRecordingAtURL:(NSURL *)fileURL
                  expectedText:(NSString *)expectedText
                    completion:(YTScoreCallback)completion;

@end

NS_ASSUME_NONNULL_END
