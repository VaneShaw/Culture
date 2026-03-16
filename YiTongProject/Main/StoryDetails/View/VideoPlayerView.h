//
//  VideoPlayerView.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/11.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "VideoManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoPlayerView : UIView
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIButton *centerPlayBtn;
// 设置视频URL
- (void)setVideoURL:(NSURL *)url;
// 外部调用：播放视频并关闭音频播放器
- (void)playVideoAndStopAudio;

// 外部调用：关闭视频播放
- (void)stopVideo;
- (void)turnOffVideoPlayback;
//部分完成
- (void)videoDidFinish;
// 全屏回调
@property (nonatomic, copy) void (^enterFullScreenBlock)(AVPlayer *player);

@end

NS_ASSUME_NONNULL_END
