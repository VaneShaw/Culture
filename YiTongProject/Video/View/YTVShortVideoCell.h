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

- (void)configureWithItem:(nullable YTVVideoFeedItem *)item;

/// 首帧就绪后隐藏封面（技术设计 §5 封面→画面）
- (void)ytv_setCoverHidden:(BOOL)hidden animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
