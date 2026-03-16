//
//  MediaPlayManager.m
//  YiTongProject
//
//  Created by ios01 on 2026/1/29.
//

#import "MediaPlayManager.h"
#import "VideoPlayerView.h"
@implementation MediaPlayManager
#pragma mark - 单例初始化
+ (instancetype)sharedManager {
    static MediaPlayManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[MediaPlayManager alloc] init];
    });
    return manager;
}

#pragma mark - 播放视频并关闭音频
- (void)playVideoAndStopAudio:(VideoPlayerView *)videoPlayer {
    AVPlayerItem *item = videoPlayer.player.currentItem;
    NSURL *url = [(AVURLAsset *)item.asset URL]; // 转成 AVURLAsset 拿 URL
    NSString *urlString = url.absoluteString;
    NSLog(@"当前视频 URL = 【%@】--------", urlString);
    

    NSLog(@"--------AAA----------------------------22------------");
    if (!videoPlayer || !videoPlayer.player) return;
    // 1️⃣ 暂停当前视频播放器（如果和当前不同）
    if (self.currentVideoPlayer && self.currentVideoPlayer != videoPlayer) {
        [self.currentVideoPlayer stopVideo];
        NSLog(@"--------AAA----------------------------00------------");
    } else {
        NSLog(@"--------AAA----------------------------11------------");
    }

    // 2️⃣ 设置当前视频播放器
    self.currentVideoPlayer = videoPlayer;

    // 3️⃣ 播放当前视频
    [self.currentVideoPlayer playVideoAndStopAudio];

    // 4️⃣ 预留关闭全局故事音频接口
    //    这里调用你自己实现的关闭音频方法
    //    例如：
    //    [[AudioManager sharedManager] stopStoryAudio];
    //[self stopStoryAudioIfNeeded]; // 👈 你自己的音频逻辑

}

#pragma mark - 停止当前视频
- (void)stopCurrentVideo {
    if (self.currentVideoPlayer) {
        [self.currentVideoPlayer stopVideo];
      
        self.currentVideoPlayer = nil;
    }
}
- (void)turnOffVideoPlayback1 {
    
    if (self.currentVideoPlayer) {
        [self.currentVideoPlayer turnOffVideoPlayback];
        self.currentVideoPlayer = nil;
    }
    
}
//- (void)stopCurrentVideoIfNeeded {
//    if (self.currentVideoPlayer) {
//        [self.currentVideoPlayer stopVideo];
//        self.currentVideoPlayer = nil;
//    }
//}
@end

