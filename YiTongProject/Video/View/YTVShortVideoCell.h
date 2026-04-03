//
//  YTVShortVideoCell.h
//  YiTongProject
//
//  整页竖滑中的单条 cell：16:9 渲染区居中，上下黑边（技术设计 §2）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YTVVideoFeedItem;
@class YTVVideoRenderView;

@interface YTVShortVideoCell : UICollectionViewCell

@property (nonatomic, strong, readonly) YTVVideoRenderView *renderView;
/// 点击整页任意区域：暂停/播放切换（由 VC 绑定）。
@property (nonatomic, copy, nullable) void (^ytv_onVideoAreaTap)(YTVShortVideoCell *cell);

- (void)configureWithItem:(nullable YTVVideoFeedItem *)item;

/// 首帧就绪后隐藏封面（技术设计 §5 封面→画面）。
- (void)ytv_setCoverHidden:(BOOL)hidden animated:(BOOL)animated;
/// 切源前立即恢复封面，避免 ready 但未出帧时露底。
- (void)ytv_showCoverImmediately;
/// 首帧到达后再隐藏封面。
- (void)ytv_hideCoverAfterFirstFrameAnimated:(BOOL)animated;
/// 播放失败时保留封面并重置额外态。
- (void)ytv_showPlaybackFailureState;
/// 进入新绑定前清理失败态。
- (void)ytv_clearPlaybackFailureState;

/// 用户暂停时显示中央「播放」提示；继续播放时隐藏
- (void)ytv_setPausedPlayHintVisible:(BOOL)visible;

@end

NS_ASSUME_NONNULL_END
