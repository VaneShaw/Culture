//
//  YTVPlayerSessionManager.m
//  YiTongProject
//

#import "YTVPlayerSessionManager.h"
#import "AudioManager.h"
#import "MediaPlayManager.h"
#import <AVFoundation/AVFoundation.h>

static void *kYTVPlayerItemStatusContext = &kYTVPlayerItemStatusContext;

@interface YTVPlayerSessionManager ()
@property (nonatomic, strong, readwrite) AVPlayer *player;
@property (nonatomic, strong, nullable) AVPlayerItem *observedItem;
@property (nonatomic, copy, nullable) void (^pendingReadyCompletion)(NSError * _Nullable error);
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
        _player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    }
    return _player;
}

- (void)replacePlaybackWithURL:(NSURL *)url completion:(void (^)(NSError * _Nullable))completion {
    [self replacePlaybackWithURL:url preferredPrewarmedPlayerItem:nil completion:completion];
}

- (void)replacePlaybackWithURL:(NSURL *)url
    preferredPrewarmedPlayerItem:(AVPlayerItem *)prewarmedItem
                      completion:(void (^)(NSError * _Nullable))completion {
    if (!url) {
        if (completion) {
            NSError *err = [NSError errorWithDomain:@"YTVPlayerSessionManager"
                                               code:-1
                                           userInfo:@{NSLocalizedDescriptionKey: @"URL is nil"}];
            completion(err);
        }
        return;
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
    [self ytv_installObservedPlayerItem:item completion:completion];
}

- (void)ytv_installObservedPlayerItem:(AVPlayerItem *)item completion:(void (^)(NSError * _Nullable))completion {
    [self ytv_removeItemObservers];
    self.pendingReadyCompletion = completion;
    self.observedItem = item;
    [item addObserver:self
           forKeyPath:@"status"
              options:NSKeyValueObservingOptionNew
              context:kYTVPlayerItemStatusContext];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ytv_itemFailedToPlay:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:item];
    [self.player replaceCurrentItemWithPlayerItem:item];
    [self ytv_resolvePendingIfTerminalStatusForItem:item];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (context != kYTVPlayerItemStatusContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    [self ytv_resolvePendingIfTerminalStatusForItem:(AVPlayerItem *)object];
}

/// 在 status 已达 Ready/Failed 时触发一次性 completion
- (void)ytv_resolvePendingIfTerminalStatusForItem:(AVPlayerItem *)item {
    if (!item || item != self.observedItem) {
        return;
    }
    switch (item.status) {
        case AVPlayerItemStatusReadyToPlay:
            [self ytv_deliverPendingWithError:nil];
            break;
        case AVPlayerItemStatusFailed: {
            NSError *err = item.error ?: [NSError errorWithDomain:@"YTVPlayerSessionManager"
                                                             code:-2
                                                         userInfo:@{NSLocalizedDescriptionKey: @"AVPlayerItem failed"}];
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
    if (self.pendingReadyCompletion) {
        NSError *out = err ?: [NSError errorWithDomain:@"YTVPlayerSessionManager"
                                                  code:-3
                                              userInfo:@{NSLocalizedDescriptionKey: @"Playback failed"}];
        [self ytv_deliverPendingWithError:out];
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
        _observedItem = nil;
    }
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
    self.pendingReadyCompletion = nil;
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
}

@end
