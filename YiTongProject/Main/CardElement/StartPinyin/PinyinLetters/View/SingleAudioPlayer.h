//
//  SingleAudioPlayer.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef void(^AudioPlayCompletionHandler)(BOOL success, NSError *error);

@interface SingleAudioPlayer : NSObject

+ (instancetype)sharedManager;

// 停止所有音频播放
- (void)stopAllAudio;

// 播放本地或网络短音频
- (void)playAudioWithURL:(NSString *)urlString
              completion:(AudioPlayCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
