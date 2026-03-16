//
//  AudioPlayerManager.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/11.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^AudioPlayCompletionHandler)(BOOL success, NSError * _Nullable error);

@interface AudioPlayerManager : NSObject
// 单例实例
+ (instancetype)sharedManager;

/**
 播放短音频（自动释放）
 @param urlString 音频文件的URL字符串
 */
//- (void)playShortAudioWithURL:(NSString *)urlString;
- (void)playShortAudioWithURL:(NSString *)urlString
                  completion:(AudioPlayCompletionHandler)completion;

- (void)playMergedAudioWithURLs:(NSArray<NSString *> *)urlStrings
                     completion:(AudioPlayCompletionHandler)completion;
// 停止所有播放
- (void)stopAllAudio;
@end

NS_ASSUME_NONNULL_END
