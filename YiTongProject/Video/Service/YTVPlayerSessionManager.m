//
//  YTVPlayerSessionManager.m
//  YiTongProject
//

#import "YTVPlayerSessionManager.h"
#import "AudioManager.h"
#import "MediaPlayManager.h"
#import <AVFoundation/AVFoundation.h>

static void *kYTVPlayerItemStatusContext = &kYTVPlayerItemStatusContext;
static void *kYTVPlayerLayerReadyForDisplayContext = &kYTVPlayerLayerReadyForDisplayContext;

@interface YTVPlayerSessionManager ()
@property (nonatomic, strong, readwrite) AVPlayer *player;
@property (nonatomic, assign, readwrite) NSUInteger currentRequestId;
@property (nonatomic, strong, nullable) AVPlayerItem *observedItem;
@property (nonatomic, weak, nullable) AVPlayerLayer *observedPlayerLayer;
@property (nonatomic, copy, nullable) void (^pendingReadyCompletion)(NSError * _Nullable error);
@property (nonatomic, assign) NSUInteger pendingReadyRequestId;
@property (nonatomic, assign) NSUInteger firstFrameRequestId;
@property (nonatomic, assign) BOOL firstFrameDeliveredForCurrentRequest;
@end

@implementation YTVPlayerSessionManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(ytv_handleAppDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self clearPlayback];
}

- (void)ytv_handleAppDidEnterBackground {
    [self pause];
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [[AVPlayer alloc] init];
        _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    }
    return _player;
}

- (void)replacePlaybackWithURL:(NSURL *)url completion:(void (^)(NSError * _Nullable))completion {
    [self replacePlaybackWithURL:url preferredPrewarmedPlayerItem:nil playerLayer:nil completion:completion];
}

/// 替换播放资源并同时绑定首帧观察层；completion 仅表示 item 已 ready 或失败。
- (NSUInteger)replacePlaybackWithURL:(NSURL *)url
          preferredPrewarmedPlayerItem:(AVPlayerItem *)prewarmedItem
                            playerLayer:(AVPlayerLayer *)playerLayer
                             completion:(void (^)(NSError * _Nullable))completion {
    if (!url) {
        if (completion) {
            NSError *err = [NSError errorWithDomain:@"YTVPlayerSessionManager"
                                               code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: @"URL is nil"}];
            completion(err);
        }
        return 0;
    }
    AVPlayerItem *item = nil;
    if ([prewarmedItem isKindOfClass:[AVPlayerItem class]]) {
        AVAsset *asset = prewarmedItem.asset;
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            NSURL *assetURL = [(AVURLAsset *)asset URL];
            if (assetURL && [assetURL.absoluteString isEqualToString:url.absoluteString]) {
                item = prewarmedItem;
            }
        }
    }
    if (!item) {
        item = [[AVPlayerItem alloc] initWithURL:url];
    }
    self.currentRequestId += 1;
    NSUInteger requestId = self.currentRequestId;
    self.firstFrameDeliveredForCurrentRequest = NO;
    [self ytv_bindPlayerLayerForFirstFrameObservation:playerLayer requestId:requestId];
    [self ytv_installObservedPlayerItem:item requestId:requestId completion:completion];
    return requestId;
}

- (void)bindPlayerLayerForFirstFrameObservation:(AVPlayerLayer *)playerLayer {
    [self ytv_bindPlayerLayerForFirstFrameObservation:playerLayer requestId:self.currentRequestId];
}

/// 绑定当前渲染层，readyForDisplay 仅对当前 request 生效。
- (void)ytv_bindPlayerLayerForFirstFrameObservation:(AVPlayerLayer *)playerLayer requestId:(NSUInteger)requestId {
    [self ytv_removeFirstFrameObserver];
    self.observedPlayerLayer = playerLayer;
    self.firstFrameRequestId = requestId;
    if (!playerLayer) {
        return;
    }
    [playerLayer addObserver:self
                  forKeyPath:@"readyForDisplay"
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:kYTVPlayerLayerReadyForDisplayContext];
}

/// 安装 item 观察者并记录当前 request，对旧回调做隔离。
- (void)ytv_installObservedPlayerItem:(AVPlayerItem *)item requestId:(NSUInteger)requestId completion:(void (^)(NSError * _Nullable))completion {
    [self ytv_removeItemObservers];
    self.pendingReadyCompletion = completion;
    self.pendingReadyRequestId = requestId;
    self.observedItem = item;
    [item addObserver:self
           forKeyPath:@"status"
              options:NSKeyValueObservingOptionNew
              context:kYTVPlayerItemStatusContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ytv_itemFailedToPlay:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:item];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ytv_itemDidPlayToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:item];
    [self.player replaceCurrentItemWithPlayerItem:item];
    [self ytv_resolvePendingIfTerminalStatusForItem:item];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (context == kYTVPlayerItemStatusContext) {
        [self ytv_resolvePendingIfTerminalStatusForItem:(AVPlayerItem *)object];
        return;
    }
    if (context == kYTVPlayerLayerReadyForDisplayContext) {
        [self ytv_handleReadyForDisplayChanged:(AVPlayerLayer *)object];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

/// 渲染层真正 readyForDisplay 后再发首帧事件，避免 ReadyToPlay 过早揭封面。
- (void)ytv_handleReadyForDisplayChanged:(AVPlayerLayer *)playerLayer {
    if (!playerLayer || playerLayer != self.observedPlayerLayer) {
        return;
    }
    if (!playerLayer.readyForDisplay || self.firstFrameDeliveredForCurrentRequest) {
        return;
    }
    self.firstFrameDeliveredForCurrentRequest = YES;
    [self ytv_emitEvent:YTVPlayerSessionEventTypeFirstFrameRendered requestId:self.firstFrameRequestId error:nil];
}

/// 在 status 已达 Ready/Failed 时触发一次性 completion
- (void)ytv_resolvePendingIfTerminalStatusForItem:(AVPlayerItem *)item {
    if (!item || item != self.observedItem) {
        return;
    }
    switch (item.status) {
        case AVPlayerItemStatusReadyToPlay:
            [self ytv_emitEvent:YTVPlayerSessionEventTypeItemReady requestId:self.pendingReadyRequestId error:nil];
            [self ytv_deliverPendingWithError:nil];
            break;
        case AVPlayerItemStatusFailed: {
            NSError *err = item.error ?: [NSError errorWithDomain:@"YTVPlayerSessionManager"
                                                             code:-2
                                                         userInfo:@{NSLocalizedDescriptionKey: @"AVPlayerItem failed"}];
            [self ytv_emitEvent:YTVPlayerSessionEventTypePlayFailed requestId:self.pendingReadyRequestId error:err];
            [self ytv_deliverPendingWithError:err];
            break;
        }
        default:
            break;
    }
}

- (void)ytv_deliverPendingWithError:(NSError *)error {
    void (^block)(NSError *) = self.pendingReadyCompletion;
    self.pendingReadyCompletion = nil;
    self.pendingReadyRequestId = 0;
    if (!block) {
        return;
    }
    if ([NSThread isMainThread]) {
        block(error);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(error);
        });
    }
}

- (void)ytv_itemFailedToPlay:(NSNotification *)note {
    NSError *err = note.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
    NSError *out = err ?: [NSError errorWithDomain:@"YTVPlayerSessionManager"
                                              code:-3
                                          userInfo:@{NSLocalizedDescriptionKey: @"Playback failed"}];
    [self ytv_emitEvent:YTVPlayerSessionEventTypePlayFailed requestId:self.pendingReadyRequestId ?: self.currentRequestId error:out];
    if (self.pendingReadyCompletion) {
        [self ytv_deliverPendingWithError:out];
    }
}

/// 单条视频播放结束后自动回到开头继续播，保持短视频循环体验。
- (void)ytv_itemDidPlayToEnd:(NSNotification *)note {
    AVPlayerItem *item = note.object;
    if (!item || item != self.observedItem) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [item seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !finished || item != self.observedItem) {
            return;
        }
        [self.player play];
    }];
}

/// 将播放事件统一派发到主线程，供 VC 校验 requestId 后更新 UI。
- (void)ytv_emitEvent:(YTVPlayerSessionEventType)eventType requestId:(NSUInteger)requestId error:(NSError *)error {
    YTVPlayerSessionEventHandler handler = self.eventHandler;
    if (!handler || requestId == 0) {
        return;
    }
    if ([NSThread isMainThread]) {
        handler(eventType, requestId, error);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(eventType, requestId, error);
        });
    }
}

- (void)ytv_removeItemObservers {
    if (_observedItem) {
        @try {
            [_observedItem removeObserver:self forKeyPath:@"status" context:kYTVPlayerItemStatusContext];
        } @catch (__unused NSException *e) {
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemFailedToPlayToEndTimeNotification
                                                      object:_observedItem];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:_observedItem];
        _observedItem = nil;
    }
}

- (void)ytv_removeFirstFrameObserver {
    if (_observedPlayerLayer) {
        @try {
            [_observedPlayerLayer removeObserver:self forKeyPath:@"readyForDisplay" context:kYTVPlayerLayerReadyForDisplayContext];
        } @catch (__unused NSException *e) {
        }
        _observedPlayerLayer = nil;
    }
    self.firstFrameRequestId = 0;
}

- (void)play {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StopAudioPlayerNotification" object:nil];
    [[AudioManager sharedManager] pausePlayback];
    [[MediaPlayManager sharedManager] stopCurrentVideo];
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                           error:&sessionError];
    if (!sessionError) {
        [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
    }
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)clearPlayback {
    [self ytv_removeItemObservers];
    [self ytv_removeFirstFrameObserver];
    self.pendingReadyCompletion = nil;
    self.pendingReadyRequestId = 0;
    self.firstFrameDeliveredForCurrentRequest = NO;
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

@end
