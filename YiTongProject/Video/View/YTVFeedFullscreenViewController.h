//
//  YTVFeedFullscreenViewController.h
//  YiTongProject
//
//  视频 Feed 专用全屏：竖屏占满屏幕；竖版视频铺满，横版视频居中留黑边（与故事横屏全屏页分离）
//

#import "BaseViewController.h"

@class AVPlayer;

NS_ASSUME_NONNULL_BEGIN

@interface YTVFeedFullscreenViewController : BaseViewController

/// 与 Feed 共用同一会话里的 `AVPlayer`（同一实例、不 replace item）。进入全屏前 Feed 会从列表 cell 上 detach，避免多个 `AVPlayerLayer` 抢同一路输出导致全屏黑屏。
@property (nonatomic, weak) AVPlayer *player;

@end

NS_ASSUME_NONNULL_END
