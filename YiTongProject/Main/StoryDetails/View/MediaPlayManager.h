//
//  MediaPlayManager.h
//  YiTongProject
//
//  Created by ios01 on 2026/1/29.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class VideoPlayerView;
NS_ASSUME_NONNULL_BEGIN

/*单例管理器，管理全局视频播放：
 1️⃣ 保证同一时间只有一个视频在播放（全局互斥）
 2️⃣ 预留接口，在播放视频时关闭故事音频
 3️⃣ 提供统一控制接口：播放、停止
 */
@interface MediaPlayManager : NSObject

/// 当前正在播放的视频播放器
@property (nonatomic, weak) VideoPlayerView *currentVideoPlayer;

/// 单例
+ (instancetype)sharedManager;

/// 播放视频并关闭故事音频
/// @param videoPlayer 当前要播放的视频播放器
- (void)playVideoAndStopAudio:(VideoPlayerView *)videoPlayer;

/// 停止当前视频播放
- (void)stopCurrentVideo;
/// 关闭当前视频播放
- (void)turnOffVideoPlayback1;
@end

NS_ASSUME_NONNULL_END
