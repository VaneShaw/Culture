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
/// 点击 16:9 视频区域：暂停/播放切换（由 VC 绑定）
@property (nonatomic, copy, nullable) void (^ytv_onVideoAreaTap)(YTVShortVideoCell *cell);
/// 点击视频外区域（上下黑边、标题区等）：仅用于暂停态下继续播放（由 VC 绑定）
@property (nonatomic, copy, nullable) void (^ytv_onOutsideVideoResumeTap)(YTVShortVideoCell *cell);

- (void)configureWithItem:(nullable YTVVideoFeedItem *)item;

/// 首帧就绪后隐藏封面（技术设计 §5 封面→画面）
- (void)ytv_setCoverHidden:(BOOL)hidden animated:(BOOL)animated;

/// 用户暂停时显示中央「播放」提示；继续播放时隐藏
- (void)ytv_setPausedPlayHintVisible:(BOOL)visible;

@end

NS_ASSUME_NONNULL_END
