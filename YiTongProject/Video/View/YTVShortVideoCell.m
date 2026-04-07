//
//  YTVShortVideoCell.m
//  YiTongProject
//

#import "YTVShortVideoCell.h"
#import "YTVVideoFeedItem.h"
#import "YTVVideoRenderView.h"
#import "HeaderConfig.h"
#import <AVFoundation/AVFoundation.h>

@interface YTVShortVideoCell ()
@property (nonatomic, strong, readwrite) YTVVideoRenderView *renderView;
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *fullScreenTapView;
@property (nonatomic, strong) UIImageView *pausedPlayHintView;
/// 横版内容：cell 内居中 16:9 条带 + ResizeAspect；竖版：铺满 + AspectFill
@property (nonatomic, assign) BOOL ytv_landscapeBandLayout;
@end

@implementation YTVShortVideoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor blackColor];
        [self.contentView addSubview:self.renderView];
        [self.contentView addSubview:self.coverImageView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.fullScreenTapView];
        [self.fullScreenTapView addSubview:self.pausedPlayHintView];
        self.titleLabel.userInteractionEnabled = NO;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ytv_onFullScreenTap:)];
        [self.fullScreenTapView addGestureRecognizer:tap];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    /// 全屏时 `renderView` 可能挂在 Feed 遮罩上，不能在这里 `attachPlayer:nil`，否则会停播。
    if (self.renderView.superview == self.contentView) {
        [self.renderView attachPlayer:nil];
    }
    [self.coverImageView sd_cancelCurrentImageLoad];
    self.coverImageView.image = nil;
    [self ytv_showCoverImmediately];
    [self ytv_clearPlaybackFailureState];
    self.titleLabel.text = @"";
    self.pausedPlayHintView.hidden = YES;
    self.ytv_onVideoAreaTap = nil;
    self.ytv_landscapeBandLayout = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = CGRectGetWidth(self.contentView.bounds);
    CGFloat h = CGRectGetHeight(self.contentView.bounds);
    self.fullScreenTapView.frame = self.contentView.bounds;
    CGRect videoFrame;
    BOOL landscapeLayout = self.ytv_landscapeBandLayout;
    if (landscapeLayout) {
        CGFloat bandH = w * (9.0 / 16.0);
        CGFloat y = (h - bandH) * 0.5;
        videoFrame = CGRectMake(0, y, w, bandH);
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        videoFrame = CGRectMake(0, 0, w, h);
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    /// 抖音式全屏会把 `renderView` 临时挂到遮罩上，仍在 cell 上时不要改其 frame。
    if (self.renderView.superview == self.contentView) {
        self.renderView.frame = videoFrame;
        self.coverImageView.frame = videoFrame;
        self.renderView.playerLayer.videoGravity = landscapeLayout ? AVLayerVideoGravityResizeAspect : AVLayerVideoGravityResizeAspectFill;
    } else {
        self.coverImageView.frame = videoFrame;
    }
    CGFloat hintSide = MIN(88, MIN(CGRectGetWidth(self.fullScreenTapView.bounds), CGRectGetHeight(self.fullScreenTapView.bounds)) * 0.28);
    hintSide = MAX(hintSide, 56);
    self.pausedPlayHintView.bounds = CGRectMake(0, 0, hintSide, hintSide);
    self.pausedPlayHintView.center = CGPointMake(CGRectGetMidX(self.fullScreenTapView.bounds), CGRectGetMidY(self.fullScreenTapView.bounds));
    UIEdgeInsets sa = self.contentView.safeAreaInsets;
    CGFloat titleH = 40.0;
    CGFloat titleY = h - sa.bottom - titleH - 10.0;
    titleY = MAX(0, titleY);
    self.titleLabel.frame = CGRectMake(16.0 + sa.left, titleY, w - 32.0 - sa.left - sa.right, titleH);
}

/// 短视频首显只读取已预取到缓存里的封面，不在 cell 露出瞬间再发起网络请求，避免拖慢滑动手势。
- (void)configureWithItem:(YTVVideoFeedItem *)item {
    if (!item) {
        self.titleLabel.text = @"";
        [self.coverImageView sd_cancelCurrentImageLoad];
        self.coverImageView.image = nil;
        [self ytv_showCoverImmediately];
        [self ytv_applyVideoLayoutFromFeedItem:nil];
        return;
    }
    [self ytv_applyVideoLayoutFromFeedItem:item];
    self.titleLabel.text = item.title.length ? item.title : @"";
    [self ytv_showCoverImmediately];
    [self ytv_clearPlaybackFailureState];
    [self.coverImageView sd_cancelCurrentImageLoad];
    self.coverImageView.image = nil;
    if (item.coverURL.length == 0) {
        return;
    }
    NSURL *coverURL = [NSURL URLWithString:item.coverURL];
    if (!coverURL) {
        return;
    }
    NSString *coverPathExtension = coverURL.pathExtension.lowercaseString;
    if ([coverPathExtension isEqualToString:@"gif"]) {
        return;
    }
    NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:coverURL];
    UIImage *cachedImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:cacheKey];
    if (cachedImage) {
        self.coverImageView.image = cachedImage;
    }
}

- (void)ytv_applyVideoLayoutFromFeedItem:(YTVVideoFeedItem *)item {
    BOOL next = item && item.ytv_hasNaturalVideoSize && [item ytv_isLandscapeNaturalVideo];
    self.ytv_landscapeBandLayout = next;
    [self setNeedsLayout];
}

- (void)ytv_setCoverHidden:(BOOL)hidden animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.18 animations:^{
            self.coverImageView.alpha = hidden ? 0 : 1;
        } completion:^(BOOL finished) {
            if (finished) {
                self.coverImageView.hidden = hidden;
                if (!hidden) {
                    self.coverImageView.alpha = 1;
                }
            }
        }];
    } else {
        self.coverImageView.hidden = hidden;
        self.coverImageView.alpha = hidden ? 0 : 1;
    }
}

- (void)ytv_showCoverImmediately {
    [self ytv_setCoverHidden:NO animated:NO];
}

- (void)ytv_hideCoverAfterFirstFrameAnimated:(BOOL)animated {
    [self ytv_setCoverHidden:YES animated:animated];
}

- (void)ytv_showPlaybackFailureState {
    [self ytv_showCoverImmediately];
    [self ytv_setPausedPlayHintVisible:NO];
}

- (void)ytv_clearPlaybackFailureState {
    // 第一版失败态仅保留封面，不额外增加控件。
}

- (void)ytv_setPausedPlayHintVisible:(BOOL)visible {
    self.pausedPlayHintView.hidden = !visible;
    self.pausedPlayHintView.alpha = visible ? 1 : 0;
}

- (void)ytv_onFullScreenTap:(UITapGestureRecognizer *)gr {
    if (gr.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if (self.ytv_onVideoAreaTap) {
        self.ytv_onVideoAreaTap(self);
    }
}


- (UIView *)fullScreenTapView {
    if (!_fullScreenTapView) {
        _fullScreenTapView = [[UIView alloc] init];
        _fullScreenTapView.backgroundColor = [UIColor clearColor];
        _fullScreenTapView.userInteractionEnabled = YES;
    }
    return _fullScreenTapView;
}


- (UIImageView *)pausedPlayHintView {
    if (!_pausedPlayHintView) {
        _pausedPlayHintView = [[UIImageView alloc] init];
        _pausedPlayHintView.contentMode = UIViewContentModeScaleAspectFit;
        _pausedPlayHintView.userInteractionEnabled = NO;
        UIImage *img = nil;
        if (@available(iOS 13.0, *)) {
            img = [UIImage systemImageNamed:@"play.circle.fill"];
        }
        if (img == nil) {
            img = [UIImage imageNamed:@"play_black"];
        }
        _pausedPlayHintView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _pausedPlayHintView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        _pausedPlayHintView.hidden = YES;
    }
    return _pausedPlayHintView;
}

- (YTVVideoRenderView *)renderView {
    if (!_renderView) {
        _renderView = [[YTVVideoRenderView alloc] initWithFrame:CGRectZero];
    }
    return _renderView;
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.clipsToBounds = YES;
        _coverImageView.backgroundColor = [UIColor blackColor];
    }
    return _coverImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

@end
