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
@class AVPlayerLayer;
@class NSURL;

typedef NS_ENUM(NSInteger, YTVPlayerSessionEventType) {
    YTVPlayerSessionEventTypeItemReady = 0,
    YTVPlayerSessionEventTypeFirstFrameRendered,
    YTVPlayerSessionEventTypePlayFailed,
};

typedef void (^YTVPlayerSessionEventHandler)(YTVPlayerSessionEventType eventType, NSUInteger requestId, NSError * _Nullable error);

/// 维护单个 AVPlayer 与当前 AVPlayerItem，负责切换资源、KVO 与通知清理，避免与旧播放器互相影响
@interface YTVPlayerSessionManager : NSObject

@property (nonatomic, strong, readonly) AVPlayer *player;
/// 当前播放请求编号；每次 replace 都会递增，用于过滤旧回调。
@property (nonatomic, assign, readonly) NSUInteger currentRequestId;
@property (nonatomic, assign) NSTimeInterval foregroundBufferDuration;
@property (nonatomic, assign) NSTimeInterval standbyBufferGoalDuration;
/// 会话级播放事件回调：item ready / 首帧显示 / 播放失败。
@property (nonatomic, copy, nullable) YTVPlayerSessionEventHandler eventHandler;

/// 替换播放地址并在可播或失败时于主线程回调 completion（成功 error 为 nil）。
- (void)replacePlaybackWithURL:(NSURL *)url completion:(void (^)(NSError * _Nullable error))completion;

/// 若 `prewarmedItem` 与 url 同源则复用预热项，否则等同仅传 url（技术设计 §5 媒体预热）。
- (NSUInteger)replacePlaybackWithURL:(NSURL *)url
          preferredPrewarmedPlayerItem:(nullable AVPlayerItem *)prewarmedItem
                            playerLayer:(nullable AVPlayerLayer *)playerLayer
                             completion:(void (^)(NSError * _Nullable error))completion;

/// 更新首帧监听所依附的渲染层；切 cell 重绑同一 player 时调用。
- (void)bindPlayerLayerForFirstFrameObservation:(nullable AVPlayerLayer *)playerLayer;

/// 后台候场：仅为 next1 进入可播/有缓冲状态；不触发前台 layer 绑定。
- (void)prepareStandbyPlaybackWithURL:(NSURL *)url
               preferredPlayerItem:(nullable AVPlayerItem *)prewarmedItem
                         completion:(void (^)(BOOL ready, NSError * _Nullable error))completion;

/// 当前前台请求是否已被后台候场命中；命中时直接接管候场 item。
- (BOOL)hasStandbyPlaybackMatchingURL:(NSURL *)url;
- (NSUInteger)promoteStandbyPlaybackMatchingURL:(NSURL *)url
                                     playerLayer:(nullable AVPlayerLayer *)playerLayer
                                      completion:(void (^)(NSError * _Nullable error))completion;

/// 命中候场后复用同源 asset 重建前台 item，避免直接复用已绑定过 standbyPlayer 的 AVPlayerItem。
- (NSUInteger)promoteStandbyPlaybackByRebuildingItemMatchingURL:(NSURL *)url
                                                    playerLayer:(nullable AVPlayerLayer *)playerLayer
                                                     completion:(void (^)(NSError * _Nullable error))completion;

/// 候场路径是否已经达到可播态（ready + 初始缓冲阈值）。
- (BOOL)standbyPlaybackReadyForURL:(NSURL *)url;

/// 当前条或候场条切换后，取消无效候场，避免额外占用解码与带宽。
- (void)clearStandbyPlayback;

- (void)play;
- (void)pause;

/// 释放当前 item 与观察者，Tab 离开或不再需要播放时调用以降低内存与后台解码占用
- (void)clearPlayback;

@end

NS_ASSUME_NONNULL_END
