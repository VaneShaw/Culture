//
//  YTServerPronounceEvaluator.m
//

#import "YTServerPronounceEvaluator.h"
#import "YTTalkCompleteSubmit.h"
#import "YTUnit.h"
#import "YTScoringService.h"

@interface YTServerPronounceEvaluator ()
@property (nonatomic, copy, nullable) void (^onProgressPercent)(NSInteger percent);
@end

@implementation YTServerPronounceEvaluator

- (instancetype)initWithProgressPercentHandler:(void (^)(NSInteger))onProgressPercent {
    self = [super init];
    if (self) {
        _onProgressPercent = [onProgressPercent copy];
    }
    return self;
}

- (void)evaluateRecordingAtURL:(NSURL *)fileURL
                          unit:(YTUnit *)unit
                  expectedText:(NSString *)expectedText
                    completion:(YTScoreCallback)completion {
    if (!completion) return;
    if (!fileURL) {
        completion(nil, [NSError errorWithDomain:@"YTServerPronounceEvaluator"
                                            code:3001
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Talk_Pronounce_Error_FileURLEmpty", @"")}]);
        return;
    }
    if (!unit) {
        completion(nil, [NSError errorWithDomain:@"YTServerPronounceEvaluator"
                                            code:3003
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Talk_Pronounce_Error_UnitEmpty", @"")}]);
        return;
    }
    if (unit.refTable.length == 0 || unit.unitId.length == 0) {
        completion(nil, [NSError errorWithDomain:@"YTServerPronounceEvaluator"
                                            code:3004
                                        userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Missing ref_table or unit_id for pronunciation scoring", @"")}]);
        return;
    }

    NSString *sceneId = unit.sceneId ?: @"";
    NSInteger apiLevelId = (NSInteger)unit.levelId + 1;
    __weak typeof(self) weakSelf = self;
    [YTTalkCompleteSubmit submitWithSceneId:sceneId
                                    levelId:apiLevelId
                                       unit:unit
                           answerJSONString:@"{}"
                           readAudioFileURL:fileURL
                                 completion:^(BOOL httpSuccess, BOOL serverCorrect, NSInteger progressPercent, NSInteger rawScore, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!httpSuccess || error) {
            completion(nil, error ?: [NSError errorWithDomain:@"YTServerPronounceEvaluator" code:-2 userInfo:nil]);
            return;
        }
        if (self.onProgressPercent && progressPercent >= 0 && progressPercent <= 100) {
            self.onProgressPercent(progressPercent);
        }
        YTScoreResult *result = [[YTScoreResult alloc] init];
        result.expectedText = expectedText ?: @"";
        if (rawScore >= 0) {
            result.score = (NSInteger)MIN(100, MAX(0, rawScore));
        } else {
            result.score = serverCorrect ? 100 : 0;
        }
        result.verdict = serverCorrect ? YTScoreVerdictCorrect : YTScoreVerdictTryAgain;
        completion(result, nil);
    }];
}

@end
