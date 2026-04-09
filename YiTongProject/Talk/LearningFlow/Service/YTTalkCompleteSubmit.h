//
//  YTTalkCompleteSubmit.h
//  提交单步学习结果：POST /talk/complete（multipart，scene_id 等与 read_audio 均在请求 Body）
//

#import <Foundation/Foundation.h>

@class YTUnit;

NS_ASSUME_NONNULL_BEGIN

@interface YTTalkCompleteSubmit : NSObject

/// 无 `unit` 时兜底序列化（建议学习流提交使用带 `unit` 的方法）
+ (NSString *)answerJSONStringFromAnswerPayload:(NSDictionary * _Nullable)payload;

/// 优先按 `unit.serverCorrectAnswerTemplate`（即 `content.correct_answer`）的键与类型封装；无模板时走本地兜底
+ (NSString *)answerJSONStringFromAnswerPayload:(NSDictionary * _Nullable)payload unit:(YTUnit * _Nullable)unit;

/// `sceneId` / `levelId`：学习流入口兜底；若 `unit.contentSceneId` / `unit.contentLevelIdString` 有值则提交用 content 内字段
/// `progressPercent` / `rawScore`：仅当 `data` 含对应字段时 ≥0，否则为 -1
+ (void)submitWithSceneId:(NSString *)sceneId
                  levelId:(NSInteger)levelId
                     unit:(YTUnit *)unit
         answerJSONString:(NSString *)answerJSON
         readAudioFileURL:(NSURL * _Nullable)fileURL
               completion:(void (^)(BOOL httpSuccess, BOOL serverSaysCorrect, NSInteger progressPercent, NSInteger rawScore, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
