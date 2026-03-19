//
//  YTAudioMuxService.h
//  YiTongProject
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^YTAudioCompletion)(BOOL success, NSError * _Nullable error);

/// 音频互斥播放：题干/选项/标准音始终只允许一个在播（PRD 6.3）
///
/// 说明：
/// - 当前实现复用工程 `AudioPlayerManager`
/// - `stop` 会停止所有音频，用于“切题/退出/开始录音前”做互斥清理
@interface YTAudioMuxService : NSObject

+ (instancetype)shared;

- (void)stop;
- (void)playURLString:(NSString *)urlString completion:(nullable YTAudioCompletion)completion;
- (void)playURLStringsInQueue:(NSArray<NSString *> *)urlStrings completion:(nullable YTAudioCompletion)completion;

@end

NS_ASSUME_NONNULL_END

