//
//  AudioRemoteControlManager.m
//  YiTongProject
//
//  Created by ios01 on 2026/1/4.
//

#import "AudioRemoteControlManager.h"
#import "PublicTool.h"
@interface AudioRemoteControlManager ()
@property (nonatomic, strong) MPRemoteCommandCenter *commandCenter;
@end
@implementation AudioRemoteControlManager
- (instancetype)initWithPlayer:(AVPlayer *)player {
    self = [super init];
    if (self) {
        _player = player;
        _commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    }
    return self;
}

#pragma mark - Public

- (void)setupRemoteControls {
    [self removeRemoteControls]; // 防止重复注册

    __weak typeof(self) weakSelf = self;

    // 播放
    [self.commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [weakSelf.player play];
        if (weakSelf.playStateChanged) {
            weakSelf.playStateChanged(YES);
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    // 暂停
    [self.commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [weakSelf.player pause];
        if (weakSelf.playStateChanged) {
            weakSelf.playStateChanged(NO);
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    // 切换
    [self.commandCenter.togglePlayPauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        if (weakSelf.player.rate == 0) {
            [weakSelf.player play];
            weakSelf.playStateChanged ? weakSelf.playStateChanged(YES) : nil;
        } else {
            [weakSelf.player pause];
            weakSelf.playStateChanged ? weakSelf.playStateChanged(NO) : nil;
        }
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    // 快进
    self.commandCenter.skipForwardCommand.enabled = YES;
    [self.commandCenter.skipForwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [weakSelf skipForward:(MPSkipIntervalCommandEvent *)event];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    // 快退
    self.commandCenter.skipBackwardCommand.enabled = YES;
    [self.commandCenter.skipBackwardCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [weakSelf skipBackward:(MPSkipIntervalCommandEvent *)event];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    // 拖动进度
    [self.commandCenter.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        MPChangePlaybackPositionCommandEvent *e = (MPChangePlaybackPositionCommandEvent *)event;
        CMTime time = [PublicTool cmTimeFromSecondsMillisecondPrecision:e.positionTime];
        [weakSelf.player seekToTime:time completionHandler:^(BOOL finished) {
            if (finished) {
                [weakSelf refreshNowPlayingAfterSeek];
            }
        }];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
}

- (void)removeRemoteControls {
    [self.commandCenter.playCommand removeTarget:nil];
    [self.commandCenter.pauseCommand removeTarget:nil];
    [self.commandCenter.togglePlayPauseCommand removeTarget:nil];
    [self.commandCenter.skipForwardCommand removeTarget:nil];
    [self.commandCenter.skipBackwardCommand removeTarget:nil];
    [self.commandCenter.changePlaybackPositionCommand removeTarget:nil];
}

#pragma mark - Skip

- (void)skipForward:(MPSkipIntervalCommandEvent *)event {
    NSTimeInterval interval = event.interval;
    CMTime target = CMTimeAdd(self.player.currentTime,
                              CMTimeMakeWithSeconds(interval, NSEC_PER_SEC));
    [self seekSafely:target];
}

- (void)skipBackward:(MPSkipIntervalCommandEvent *)event {
    NSTimeInterval interval = event.interval;
    CMTime target = CMTimeSubtract(self.player.currentTime,
                                   CMTimeMakeWithSeconds(interval, NSEC_PER_SEC));
    if (CMTimeGetSeconds(target) < 0) {
        target = kCMTimeZero;
    }
    [self seekSafely:target];
}

- (void)seekSafely:(CMTime)time {
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:time completionHandler:^(BOOL finished) {
        if (finished) {
            [weakSelf refreshNowPlayingAfterSeek];
        }
    }];
}

#pragma mark - Now Playing

- (void)refreshNowPlayingAfterSeek {
    MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:center.nowPlayingInfo ?: @{}];

    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] =
        @(CMTimeGetSeconds(self.player.currentTime));
    info[MPNowPlayingInfoPropertyPlaybackRate] =
        @(self.player.rate);

    center.nowPlayingInfo = info;
}

@end
