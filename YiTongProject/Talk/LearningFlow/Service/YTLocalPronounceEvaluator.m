//
//  YTLocalPronounceEvaluator.m
//  YiTongProject
//

#import "YTLocalPronounceEvaluator.h"
#import "YTUnit.h"
#import <AVFoundation/AVFoundation.h>

@implementation YTLocalPronounceEvaluator

+ (instancetype)shared {
    static YTLocalPronounceEvaluator *service;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[YTLocalPronounceEvaluator alloc] init];
    });
    return service;
}

- (void)evaluateRecordingAtURL:(NSURL *)fileURL
                          unit:(YTUnit *)unit
                  expectedText:(NSString *)expectedText
                    completion:(YTScoreCallback)completion
{
    (void)unit;
    if (!completion) return;
    if (!fileURL) {
        completion(nil, [NSError errorWithDomain:@"YTLocalPronounceEvaluator"
                                            code:3001
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Talk_Pronounce_Error_FileURLEmpty", @"")}]);
        return;
    }
    if (expectedText.length == 0) {
        completion(nil, [NSError errorWithDomain:@"YTLocalPronounceEvaluator"
                                            code:3002
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Talk_Pronounce_Error_ExpectedTextEmpty", @"")}]);
        return;
    }

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    Float64 seconds = CMTimeGetSeconds(asset.duration);
    if (!isfinite(seconds) || seconds <= 0) seconds = 0.0;

    NSInteger base = (NSInteger)MIN(100, MAX(0, (seconds / 1.5) * 100));
    NSInteger noise = (NSInteger)(arc4random_uniform(11)) - 2;
    NSInteger score = MIN(100, MAX(0, base + noise + 14));
    YTScoreVerdict verdict = (score >= 48) ? YTScoreVerdictCorrect : YTScoreVerdictTryAgain;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        YTScoreResult *result = [[YTScoreResult alloc] init];
        result.score = score;
        result.verdict = verdict;
        result.expectedText = expectedText;
        completion(result, nil);
    });
}

@end
