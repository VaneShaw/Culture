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
        self.renderView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ytv_onFullScreenTap:)];
        [self.fullScreenTapView addGestureRecognizer:tap];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.renderView attachPlayer:nil];
    [self.coverImageView sd_cancelCurrentImageLoad];
    self.coverImageView.image = nil;
    [self ytv_showCoverImmediately];
    [self ytv_clearPlaybackFailureState];
    self.titleLabel.text = @"";
    self.pausedPlayHintView.hidden = YES;
    self.ytv_onVideoAreaTap = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = CGRectGetWidth(self.contentView.bounds);
    CGFloat h = CGRectGetHeight(self.contentView.bounds);
    self.fullScreenTapView.frame = self.contentView.bounds;
    CGFloat videoH = w * 9.0 / 16.0;
    CGFloat y = (h - videoH) * 0.5;
    self.renderView.frame = CGRectMake(0, y, w, videoH);
    self.coverImageView.frame = self.renderView.frame;
    CGFloat hintSide = MIN(88, MIN(CGRectGetWidth(self.fullScreenTapView.bounds), CGRectGetHeight(self.fullScreenTapView.bounds)) * 0.28);
    hintSide = MAX(hintSide, 56);
    self.pausedPlayHintView.bounds = CGRectMake(0, 0, hintSide, hintSide);
    self.pausedPlayHintView.center = CGPointMake(CGRectGetMidX(self.fullScreenTapView.bounds), CGRectGetMidY(self.fullScreenTapView.bounds));
    CGFloat titleY = CGRectGetMaxY(self.renderView.frame) + 8;
    self.titleLabel.frame = CGRectMake(16, titleY, w - 32, 36);
}

- (void)configureWithItem:(YTVVideoFeedItem *)item {
    if (!item) {
        self.titleLabel.text = @"";
        [self.coverImageView sd_cancelCurrentImageLoad];
        self.coverImageView.image = nil;
        [self ytv_showCoverImmediately];
        return;
    }
    self.titleLabel.text = item.title.length ? item.title : @"";
    [self ytv_showCoverImmediately];
    [self ytv_clearPlaybackFailureState];
    if (item.coverURL.length > 0) {
        NSURL *u = [NSURL URLWithString:item.coverURL];
        if (u) {
            [self.coverImageView sd_setImageWithURL:u placeholderImage:nil];
        } else {
            [self.coverImageView sd_cancelCurrentImageLoad];
            self.coverImageView.image = nil;
        }
    } else {
        [self.coverImageView sd_cancelCurrentImageLoad];
        self.coverImageView.image = nil;
    }
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
