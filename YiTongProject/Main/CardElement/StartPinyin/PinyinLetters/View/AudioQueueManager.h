//
//  AudioQueueManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^AudioQueueCompletionHandler)(BOOL success, NSError *error);

@interface AudioQueueManager : NSObject

+ (instancetype)sharedManager;

/// 播放多个音频（顺序播放）
/// urls: 网络 URL 字符串数组（可传 1 个或多个）
/// completion：全部播放完毕或失败的回调
- (void)playAudioQueueWithURLs:(NSArray<NSString *> *)urls
                    completion:(AudioQueueCompletionHandler)completion;

/// 停止播放队列
- (void)stopAllAudio;

@end

NS_ASSUME_NONNULL_END
