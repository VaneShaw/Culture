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
@property (nonatomic, strong) UIView *outsideResumeTapView;
@property (nonatomic, strong) UIView *videoTapOverlay;
@property (nonatomic, strong) UIImageView *pausedPlayHintView;
@end

@implementation YTVShortVideoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor blackColor];
        [self.contentView addSubview:self.outsideResumeTapView];
        [self.contentView addSubview:self.renderView];
        [self.contentView addSubview:self.coverImageView];
        [self.contentView addSubview:self.videoTapOverlay];
        [self.videoTapOverlay addSubview:self.pausedPlayHintView];
        [self.contentView addSubview:self.titleLabel];
        self.titleLabel.userInteractionEnabled = NO;
        self.renderView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        UITapGestureRecognizer *outTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ytv_onOutsideResumeTap:)];
        [self.outsideResumeTapView addGestureRecognizer:outTap];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ytv_onVideoTapOverlay:)];
        [self.videoTapOverlay addGestureRecognizer:tap];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.renderView attachPlayer:nil];
    [self.coverImageView sd_cancelCurrentImageLoad];
    self.coverImageView.image = nil;
    self.coverImageView.hidden = NO;
    self.coverImageView.alpha = 1;
    self.titleLabel.text = @"";
    self.pausedPlayHintView.hidden = YES;
    self.ytv_onVideoAreaTap = nil;
    self.ytv_onOutsideVideoResumeTap = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = CGRectGetWidth(self.contentView.bounds);
    CGFloat h = CGRectGetHeight(self.contentView.bounds);
    self.outsideResumeTapView.frame = self.contentView.bounds;
    CGFloat videoH = w * 9.0 / 16.0;
    CGFloat y = (h - videoH) * 0.5;
    self.renderView.frame = CGRectMake(0, y, w, videoH);
    self.coverImageView.frame = self.renderView.frame;
    self.videoTapOverlay.frame = self.renderView.frame;
    CGFloat hintSide = MIN(88, MIN(CGRectGetWidth(self.videoTapOverlay.bounds), CGRectGetHeight(self.videoTapOverlay.bounds)) * 0.28);
    hintSide = MAX(hintSide, 56);
    self.pausedPlayHintView.bounds = CGRectMake(0, 0, hintSide, hintSide);
    self.pausedPlayHintView.center = CGPointMake(CGRectGetMidX(self.videoTapOverlay.bounds), CGRectGetMidY(self.videoTapOverlay.bounds));
    CGFloat titleY = CGRectGetMaxY(self.renderView.frame) + 8;
    self.titleLabel.frame = CGRectMake(16, titleY, w - 32, 36);
}

- (void)configureWithItem:(YTVVideoFeedItem *)item {
    if (!item) {
        self.titleLabel.text = @"";
        [self.coverImageView sd_cancelCurrentImageLoad];
        self.coverImageView.image = nil;
        self.coverImageView.hidden = NO;
        self.coverImageView.alpha = 1;
        return;
    }
    self.titleLabel.text = item.title.length ? item.title : @"";
    self.coverImageView.hidden = NO;
    self.coverImageView.alpha = 1;
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

- (void)ytv_setPausedPlayHintVisible:(BOOL)visible {
    self.pausedPlayHintView.hidden = !visible;
    self.pausedPlayHintView.alpha = visible ? 1 : 0;
}

- (void)ytv_onVideoTapOverlay:(UITapGestureRecognizer *)gr {
    if (gr.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if (self.ytv_onVideoAreaTap) {
        self.ytv_onVideoAreaTap(self);
    }
}

- (void)ytv_onOutsideResumeTap:(UITapGestureRecognizer *)gr {
    if (gr.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if (self.ytv_onOutsideVideoResumeTap) {
        self.ytv_onOutsideVideoResumeTap(self);
    }
}

- (UIView *)outsideResumeTapView {
    if (!_outsideResumeTapView) {
        _outsideResumeTapView = [[UIView alloc] init];
        _outsideResumeTapView.backgroundColor = [UIColor clearColor];
        _outsideResumeTapView.userInteractionEnabled = YES;
    }
    return _outsideResumeTapView;
}

- (UIView *)videoTapOverlay {
    if (!_videoTapOverlay) {
        _videoTapOverlay = [[UIView alloc] init];
        _videoTapOverlay.backgroundColor = [UIColor clearColor];
        _videoTapOverlay.userInteractionEnabled = YES;
    }
    return _videoTapOverlay;
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
