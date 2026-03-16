//
//  StoryAudioPlayer.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/29.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
NS_ASSUME_NONNULL_BEGIN

@interface StoryAudioPlayer : NSObject
@property (nonatomic, strong, readonly) AVPlayer *playerAudio;
@property (nonatomic, strong, readonly) AVPlayerItem *playerItem;
//@property (nonatomic, assign, readonly) Float64 currentSeconds;
@property (nonatomic, assign) Float64 currentSeconds;
@property (nonatomic, assign, readonly) Float64 totalSeconds;

// 当前时间文本（MM:SS）
//@property (nonatomic, copy, readonly) NSString *currentTimeText;
//@property (nonatomic, copy, readonly) NSString *totalTimeText;

@property (nonatomic, strong) NSString *currentTimeText;
// 总时长文本（MM:SS）
@property (nonatomic, strong) NSString *totalTimeText;

// 播放进度更新回调 (currentSeconds, totalSeconds)
@property (nonatomic, copy) void (^onProgressUpdate)(Float64 current, Float64 total);
// 播放完成回调
@property (nonatomic, copy) void (^onPlaybackFinished)(void);
// 当前章节变化回调
@property (nonatomic, copy) void (^onChapterChange)(NSInteger chapterIndex);

// 当前故事id（用于封面）
@property (nonatomic, copy) NSString *storyId;//v
// 标题（锁屏用）
@property (nonatomic, copy) NSString *storyTitle;//v

// 章节时间数组
@property (nonatomic, strong) NSArray<NSString *> *timeRanges;
- (instancetype)initWithURL:(NSString *)url;

- (void)play;
- (void)pause;
- (void)togglePlayPause;
- (void)seekToTime:(Float64)seconds;
//- (void)seekToTime22:(Float64)seconds;
- (void)setupRemoteControls;
- (void)updateNowPlayingInfo;

/// 销毁（移除监听）
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END
