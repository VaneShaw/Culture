//
//  StoryAudioPlayer.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/29.
//

#import "StoryAudioPlayer.h"
#import "PublicTool.h"
@interface StoryAudioPlayer ()
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *playerAudio;
@end
@implementation StoryAudioPlayer
- (instancetype)initWithURL:(NSString *)url {
    if (self = [super init]) {
        [self setupPlayerWithURL:url];
    }
    return self;
}

- (void)setupPlayerWithURL:(NSString *)url {
    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]];
    self.playerAudio = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    // 播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidFinish:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    // 监听状态和时长
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionNew context:nil];
    
    // 定时更新进度
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.playerAudio addPeriodicTimeObserverForInterval:CMTimeMake(1, 1)
                                                                  queue:dispatch_get_main_queue()
                                                             usingBlock:^(CMTime time) {
        [weakSelf updateProgress];
    }];
}

#pragma mark - 播放控制

- (void)play {
    [self.playerAudio play];
    [self updateNowPlayingInfo];
}

- (void)pause {
    [self.playerAudio pause];
    [self updateNowPlayingInfo];
}

- (void)togglePlayPause {
    if (self.playerAudio.rate == 0.0) {
        [self play];
    } else {
        [self pause];
    }
}

#pragma mark - 进度更新

- (void)updateProgress {
    Float64 current = CMTimeGetSeconds(self.playerAudio.currentItem.currentTime);
    Float64 total = CMTimeGetSeconds(self.playerItem.duration);
    if (isfinite(current) && isfinite(total)) {
        _currentSeconds = current;
        _totalSeconds = total;
        _currentTimeText = [self timeStringFromSeconds:current];
        _totalTimeText = [self timeStringFromSeconds:total];
        NSLog(@"current------------------[%lf]---------cuc",current);
        if (self.onProgressUpdate) self.onProgressUpdate(current, total);
        [self updateNowPlayingInfo];
        
        // 章节联动
        NSInteger index = [self indexForTime:(NSInteger)current inRanges:self.timeRanges];
        if (index >= 0 && self.onChapterChange) self.onChapterChange(index);
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object == self.playerItem && [keyPath isEqualToString:@"status"]) {
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            Float64 duration = CMTimeGetSeconds(self.playerItem.duration);
            _totalSeconds = duration;
            _totalTimeText = [self timeStringFromSeconds:duration];
            [self updateNowPlayingInfo];
        }
    }
}

#pragma mark - 拖动跳转

- (void)seekToTime:(Float64)seconds {
    CMTime time = [PublicTool cmTimeFromSecondsMillisecondPrecision:seconds];
    [self.playerAudio seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self updateNowPlayingInfo];
}

#pragma mark - 播放完成

- (void)playerDidFinish:(NSNotification *)note {
    [self.playerAudio seekToTime:kCMTimeZero];
    [self pause];
    if (self.onPlaybackFinished) self.onPlaybackFinished();
}

#pragma mark - 锁屏信息

- (void)updateNowPlayingInfo {

    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[MPMediaItemPropertyTitle] = self.storyTitle ?: @"";
    
    UIImage *art = [UIImage imageNamed:[NSString stringWithFormat:@"story_detail_%@", self.storyId]];
    if (!art) art = [UIImage imageNamed:@"blue_1024"];
    MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithBoundsSize:art.size requestHandler:^UIImage * _Nonnull(CGSize size) {
        return art;
    }];
    info[MPMediaItemPropertyArtwork] = artwork;
    
    if (isfinite(self.totalSeconds)) {
        info[MPMediaItemPropertyPlaybackDuration] = @(self.totalSeconds);
    }
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.currentSeconds);
    info[MPNowPlayingInfoPropertyPlaybackRate] = @(self.playerAudio.rate);
    
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = info;
    
   
}

#pragma mark - 远程控制

- (void)setupRemoteControls {
    //MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
    //[center.playCommand addTarget:self action:@selector(handlePlayCommand:)];
    //[center.pauseCommand addTarget:self action:@selector(handlePauseCommand:)];
    //[center.togglePlayPauseCommand addTarget:self action:@selector(handleTogglePlayPauseCommand:)];
  
}
//// 播放命令
//- (MPRemoteCommandHandlerStatus)handlePlayCommand:(MPRemoteCommandEvent *)event {
//    [self play]; // 你原来的播放逻辑
//    return MPRemoteCommandHandlerStatusSuccess;
//}
//
//// 暂停命令
//- (MPRemoteCommandHandlerStatus)handlePauseCommand:(MPRemoteCommandEvent *)event {
//    [self pause]; // 你原来的暂停逻辑
//    return MPRemoteCommandHandlerStatusSuccess;
//}
//
//// 切换播放/暂停命令
//- (MPRemoteCommandHandlerStatus)handleTogglePlayPauseCommand:(MPRemoteCommandEvent *)event {
//    [self togglePlayPause]; // 你原来的切换逻辑
//    return MPRemoteCommandHandlerStatusSuccess;
//}
#pragma mark - 工具函数

- (NSString *)timeStringFromSeconds:(Float64)seconds {
    int total = (int)seconds;
    return [NSString stringWithFormat:@"%02d:%02d", total / 60, total % 60];
}

- (NSInteger)indexForTime:(NSInteger)time inRanges:(NSArray<NSString *> *)ranges {
    for (NSInteger i = 0; i < ranges.count; i++) {
        NSArray *parts = [ranges[i] componentsSeparatedByString:@"-"];
        if (parts.count < 2) continue;
        NSInteger start = [parts[0] integerValue];
        NSInteger end = [parts[1] integerValue];
        if (time >= start && time <= end) return i;
    }
    return -1;
}

#pragma mark - 清理

- (void)cleanup {
    if (self.timeObserver) {
        [self.playerAudio removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"duration"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    [self cleanup];
}

@end
