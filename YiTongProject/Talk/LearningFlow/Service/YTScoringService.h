//
//  YTScoringService.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTScoreVerdict) {
    YTScoreVerdictCorrect = 0,
    YTScoreVerdictTryAgain = 1,
};

@interface YTScoreResult : NSObject
@property (nonatomic, assign) NSInteger score; // 0~100
@property (nonatomic, assign) YTScoreVerdict verdict;
@property (nonatomic, copy) NSString *expectedText;
@property (nonatomic, copy, nullable) NSString *errorCode;
@end

typedef void (^YTScoreCallback)(YTScoreResult * _Nullable result, NSError * _Nullable error);

NS_ASSUME_NONNULL_END

