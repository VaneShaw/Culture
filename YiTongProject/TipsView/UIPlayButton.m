//
//  UIPlayButton.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/20.
//

#import "UIPlayButton.h"

@implementation UIPlayButton {
    UIImageView *_bgView;
    UIImageView *_normalView;
    UIImageView *_playingView;
}

// 修改 normalImage 时，自动更新显示
- (void)setNormalImage:(UIImage *)normalImage {
    _normalImage = normalImage;
    _normalView.image = normalImage;
}

// 修改 playingImage 时，自动更新显示
- (void)setPlayingImage:(UIImage *)playingImage {
    _playingImage = playingImage;
    _playingView.image = playingImage;
}
- (instancetype)initWithFrame:(CGRect)frame
              backgroundImage:(UIImage *)bgImage
                  normalImage:(UIImage *)normalImage
                 playingImage:(UIImage *)playingImage {
    if (self = [super initWithFrame:frame]) {
        _animationDuration = 0.8;
        _isPlaying = NO;
        
        // 背景图层
        _bgView = [[UIImageView alloc] initWithImage:bgImage];
        _bgView.frame = self.bounds;
        _bgView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_bgView];
        
        // 默认图层
        _normalView = [[UIImageView alloc] initWithImage:normalImage];
        _normalView.contentMode = UIViewContentModeCenter;
        _normalView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_normalView];

        // 动画图层
        _playingView = [[UIImageView alloc] initWithImage:playingImage];
        _playingView.contentMode = UIViewContentModeCenter;
        _playingView.hidden = YES;
        _playingView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_playingView];

        // ✅ 自动布局：居中 + 不超过父视图
        [NSLayoutConstraint activateConstraints:@[
            // normalView 居中
            [_normalView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_normalView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-5],
            [_normalView.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor],
            [_normalView.heightAnchor constraintLessThanOrEqualToAnchor:self.heightAnchor],

            // playingView 居中
            [_playingView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_playingView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-5],
            [_playingView.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor],
            [_playingView.heightAnchor constraintLessThanOrEqualToAnchor:self.heightAnchor],
        ]];
        
    }
    return self;
}

#pragma mark - 播放控制

- (void)startPlaying {
    if (_isPlaying) return;
    _isPlaying = YES;
    _normalView.hidden = YES;
    _playingView.hidden = NO;
    [self addBreathAnimation];
}
- (void)startCellPlaying {
    [self addBreathAnimation];
}
- (void)stopCellPlaying {
    [self.layer removeAnimationForKey:@"breathAnimation"];
}
- (void)stopPlaying {
    if (!_isPlaying) return;
    _isPlaying = NO;
    _normalView.hidden = NO;
    _playingView.hidden = YES;
    [self.layer removeAnimationForKey:@"breathAnimation"];
}

#pragma mark - 动画部分
// 呼吸放大缩小动画
- (void)addBreathAnimation {
    CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scale.fromValue = @(1.0);
    scale.toValue = @(1.2);
    scale.duration = _animationDuration; // ✅ 动画速度可调节
    scale.autoreverses = YES;
    scale.repeatCount = HUGE_VALF;
    scale.removedOnCompletion = NO;
    [_playingView.layer addAnimation:scale forKey:@"breathAnimation"];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
