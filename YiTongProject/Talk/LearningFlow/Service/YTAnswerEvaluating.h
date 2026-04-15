//
//  YTAnswerEvaluating.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTUnitViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YTAnswerEvaluating <NSObject>

- (void)evaluateUnit:(YTUnit *)unit
       answerPayload:(NSDictionary *)answerPayload
          completion:(void (^)(YTUnitSubmitResult * _Nullable result,
                               NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
