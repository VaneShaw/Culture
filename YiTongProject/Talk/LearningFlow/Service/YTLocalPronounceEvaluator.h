//
//  YTLocalPronounceEvaluator.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTPronounceEvaluating.h"

NS_ASSUME_NONNULL_BEGIN

@interface YTLocalPronounceEvaluator : NSObject <YTPronounceEvaluating>

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
