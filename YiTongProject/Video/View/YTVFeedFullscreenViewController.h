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

/// 与 Feed 共用会话中的 `AVPlayer`，进入前赋值
@property (nonatomic, weak) AVPlayer *player;

@end

NS_ASSUME_NONNULL_END
