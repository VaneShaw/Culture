//
//  YTAudioMuxService.m
//  YiTongProject
//

#import "YTAudioMuxService.h"
#import "AudioPlayerManager.h"

@implementation YTAudioMuxService

/**
 音频播放“互斥”服务
 
 设计意图：
 - 同一时刻只允许一个音频在播放（避免题干音频与句子音频叠加）
 - 复用工程内现有播放器 `AudioPlayerManager`，不重复造轮子
 
 约定：
 - `playURLString:` 会直接触发播放，调用方若需要“播放前停止其它音频”，可以先调用 `stop`
 - 队列播放用于困难段落的多句合并播放（或未来扩展）
 */
+ (instancetype)shared {
    static YTAudioMuxService *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[YTAudioMuxService alloc] init];
    });
    return s;
}

- (void)stop {
    // 互斥的最小实现：直接停掉播放器当前所有音频
    [[AudioPlayerManager sharedManager] stopAllAudio];
}

- (void)playURLString:(NSString *)urlString completion:(YTAudioCompletion)completion {
    if (urlString.length == 0) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"YTAudioMuxService" code:1001 userInfo:@{NSLocalizedDescriptionKey: @"无效音频URL"}]);
        }
        return;
    }
    // 统一走工程内播放器：内部已处理音频 session / 播放回调
    [[AudioPlayerManager sharedManager] playShortAudioWithURL:urlString completion:^(BOOL success, NSError * _Nullable error) {
        if (completion) completion(success, error);
    }];
}

- (void)playURLStringsInQueue:(NSArray<NSString *> *)urlStrings completion:(YTAudioCompletion)completion {
    if (urlStrings.count == 0) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"YTAudioMuxService" code:1002 userInfo:@{NSLocalizedDescriptionKey: @"无效音频URL列表"}]);
        }
        return;
    }
    // 合并播放：适用于段落/多句一次性连续播放（避免容器自己管理队列状态）
    [[AudioPlayerManager sharedManager] playMergedAudioWithURLs:urlStrings completion:^(BOOL success, NSError * _Nullable error) {
        if (completion) completion(success, error);
    }];
}

@end

