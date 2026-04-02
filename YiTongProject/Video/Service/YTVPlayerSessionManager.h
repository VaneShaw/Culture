//
//  YTVPlayerSessionManager.h
//  YiTongProject
//
//  视频 Tab 专用会话级播放器（与 Story 模块 VideoPlayerView 独立，勿混用）
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AVPlayer;
@class AVPlayerItem;

/// 维护单个 AVPlayer 与当前 AVPlayerItem，负责切换资源、KVO 与通知清理，避免与旧播放器互相影响
@interface YTVPlayerSessionManager : NSObject

@property (nonatomic, strong, readonly) AVPlayer *player;

/// 替换播放地址并在可播或失败时于主线程回调 completion（成功 error 为 nil）
- (void)replacePlaybackWithURL:(NSURL *)url completion:(void (^)(NSError * _Nullable error))completion;

/// 若 `prewarmedItem` 与 url 同源则复用预热项，否则等同仅传 url（技术设计 §5 媒体预热）
- (void)replacePlaybackWithURL:(NSURL *)url
    preferredPrewarmedPlayerItem:(nullable AVPlayerItem *)prewarmedItem
                      completion:(void (^)(NSError * _Nullable error))completion;

- (void)play;
- (void)pause;

/// 释放当前 item 与观察者，Tab 离开或不再需要播放时调用以降低内存与后台解码占用
- (void)clearPlayback;

@end

NS_ASSUME_NONNULL_END
