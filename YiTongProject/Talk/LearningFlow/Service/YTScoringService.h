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

/// 评分服务：MVP 先做本地“假评分”，后续可替换为后端/第三方评测
///
/// 返回约定：
/// - score: 0~100
/// - verdict: Correct / TryAgain（用于 UI 文案与状态机）
/// - expectedText: 透传回填，便于调试与未来对接真实评测
@interface YTScoringService : NSObject

+ (instancetype)shared;

- (void)scoreRecordingAtURL:(NSURL *)fileURL expectedText:(NSString *)expectedText completion:(YTScoreCallback)completion;

@end

NS_ASSUME_NONNULL_END

