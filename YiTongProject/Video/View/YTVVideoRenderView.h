//
//  YTVVideoRenderView.h
//  YiTongProject
//
//  仅负责 AVPlayerLayer 展示（根 layer 为 AVPlayerLayer），与 Story 的 VideoPlayerView 无关
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AVPlayer;

@interface YTVVideoRenderView : UIView

@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;

/// 绑定会话中的 player；传 nil 则清空画面
- (void)attachPlayer:(nullable AVPlayer *)player;

@end

NS_ASSUME_NONNULL_END
