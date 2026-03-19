//
//  YTScoringService.m
//  YiTongProject
//

#import "YTScoringService.h"
#import <AVFoundation/AVFoundation.h>

@implementation YTScoreResult
@end

@implementation YTScoringService

/**
 评分服务（MVP）
 
 现状：
 - 当前版本无真实评测引擎/后端接口，因此提供“可解释的假评分”
 - 目标是先把 UI 状态机与链路跑通：录音 -> scoring 中间态 -> 得分/结果
 
 设计约束：
 - `expectedText` 作为未来真实评分的输入参数保留（现在仅回填到结果里）
 - 回调在主线程返回，方便直接驱动 UI
 */
+ (instancetype)shared {
    static YTScoringService *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[YTScoringService alloc] init];
    });
    return s;
}

- (void)scoreRecordingAtURL:(NSURL *)fileURL expectedText:(NSString *)expectedText completion:(YTScoreCallback)completion {
    if (!completion) return;
    if (!fileURL) {
        completion(nil, [NSError errorWithDomain:@"YTScoringService" code:3001 userInfo:@{NSLocalizedDescriptionKey: @"fileURL 为空"}]);
        return;
    }
    if (expectedText.length == 0) {
        completion(nil, [NSError errorWithDomain:@"YTScoringService" code:3002 userInfo:@{NSLocalizedDescriptionKey: @"expectedText 为空"}]);
        return;
    }

    // MVP：用录音时长构造一个“可解释的假评分”（时长越长，分数越高）
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    Float64 seconds = CMTimeGetSeconds(asset.duration);
    if (!isfinite(seconds) || seconds <= 0) seconds = 0.0;

    NSInteger base = (NSInteger)MIN(100, MAX(0, (seconds / 2.5) * 100)); // 2.5s 约等于 100
    NSInteger noise = (NSInteger)(arc4random_uniform(11)) - 5;           // -5~+5
    NSInteger score = MIN(100, MAX(0, base + noise));
    YTScoreVerdict verdict = (score >= 60) ? YTScoreVerdictCorrect : YTScoreVerdictTryAgain;

    // 模拟网络延迟：让 UI 能看到“Scoring...”中间态
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        YTScoreResult *r = [[YTScoreResult alloc] init];
        r.score = score;
        r.verdict = verdict;
        r.expectedText = expectedText;
        completion(r, nil);
    });
}

@end

