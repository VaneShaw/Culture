//
//  YTVShortVideoCell.h
//  YiTongProject
//
//  整页竖滑中的单条 cell：视频区宽度铺满，高度按素材宽高比居中；无尺寸信息前整页等比留白（不裁切）。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YTVVideoFeedItem;
@class YTVVideoRenderView;

@interface YTVShortVideoCell : UICollectionViewCell

@property (nonatomic, strong, readonly) YTVVideoRenderView *renderView;
/// 点击整页任意区域：暂停/播放切换（由 VC 绑定）。
@property (nonatomic, copy, nullable) void (^ytv_onVideoAreaTap)(YTVShortVideoCell *cell);
@property (nonatomic, copy, nullable) void (^ytv_onPlaybackRetryTap)(YTVShortVideoCell *cell);
/// 收藏 / 分享 / 横版全屏 / 摘要「查看全部」由 VC 绑定；与对应条目的模型一致并随 cell 滑动。
@property (nonatomic, copy, nullable) void (^ytv_onFavoriteChromeTap)(YTVShortVideoCell *cell);
@property (nonatomic, copy, nullable) void (^ytv_onShareChromeTap)(YTVShortVideoCell *cell);
@property (nonatomic, copy, nullable) void (^ytv_onFullScreenChromeTap)(YTVShortVideoCell *cell);
@property (nonatomic, copy, nullable) void (^ytv_onChromeSeeAllTap)(YTVShortVideoCell *cell);

- (void)configureWithItem:(nullable YTVVideoFeedItem *)item;

/// 接口或 AVAsset 探测更新横竖信息后刷新视频条带区域（不重绑 player）
- (void)ytv_applyVideoLayoutFromFeedItem:(nullable YTVVideoFeedItem *)item;

/// 历史兼容接口；当前短视频流不再显示封面图。
- (void)ytv_setCoverHidden:(BOOL)hidden animated:(BOOL)animated;
/// 历史兼容接口；当前实现为空显示。
- (void)ytv_showCoverImmediately;
/// 历史兼容接口；当前实现为空显示。
- (void)ytv_hideCoverAfterFirstFrameAnimated:(BOOL)animated;
/// 播放失败时直接显示失败遮罩。
- (void)ytv_showPlaybackFailureState;
/// 进入新绑定前清理失败态。
- (void)ytv_clearPlaybackFailureState;

/// 用户暂停时显示中央「播放」提示；继续播放时隐藏
- (void)ytv_setPausedPlayHintVisible:(BOOL)visible;

/// 横版条带布局时返回条带在 `view` 坐标系中的 frame；竖版全屏时为 `CGRectZero`（供 Feed 全屏按钮对齐）。
- (CGRect)ytv_landscapeVideoContentFrameConvertedToView:(UIView *)view;

/// 绑定左下标题/摘要、右侧收藏分享与横版全屏入口；`chromeEnabled` 为 NO 时整层隐藏（分类未激活、流未就绪等）。
- (void)ytv_configureInteractionChromeWithItem:(nullable YTVVideoFeedItem *)item chromeEnabled:(BOOL)chromeEnabled;

/// 跟手滑动：整页（含互动层）变暗，opacity 建议 0～0.5
- (void)ytv_setSwipeDimOpacity:(CGFloat)opacity;

/// 内联全屏动画期间隐藏互动层，避免与旋转层叠乱
- (void)ytv_setInteractionChromeSuppressed:(BOOL)suppressed;

/// 系统分享 popover 锚点（iPad）
- (UIView *)ytv_shareChromePresentationAnchor;

@end

NS_ASSUME_NONNULL_END
