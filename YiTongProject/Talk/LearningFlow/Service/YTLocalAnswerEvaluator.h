//
//  YTLocalAnswerEvaluator.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTAnswerEvaluating.h"

NS_ASSUME_NONNULL_BEGIN

@interface YTLocalAnswerEvaluator : NSObject <YTAnswerEvaluating>

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
