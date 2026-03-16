//
//  AnimatedImageView.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/22.
//

#import "AnimatedImageView.h"
//用于拼音字母表
@implementation AnimatedImageView {
    BOOL _isAnimating;
    CADisplayLink *_displayLink;
    CGFloat _audioLevel;
    CGFloat _targetScale;
    CGFloat _currentScale;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _isAnimating = NO;
    _audioLevel = 0.0;
    _targetScale = 1.0;
    _currentScale = 1.0;
    
    // 设置默认样式
    self.contentMode = UIViewContentModeScaleAspectFit;
    NSString *currentKey = [ColorManager currentColorKey];
    self.image = [UIImage imageNamed:[NSString stringWithFormat:@"sound_wave_%@",currentKey]];
    
    // 添加轻微阴影增强深度感
    self.layer.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.3].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 2);
    self.layer.shadowRadius = 3;
    self.layer.shadowOpacity = 0.5;
}

- (void)startAnimation {
    if (_isAnimating) return;
    _isAnimating = YES;
    
    // 重置缩放
    self.transform = CGAffineTransformIdentity;
    _currentScale = 1.0;
    _targetScale = 1.0;
    
    // 创建显示链接
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateAnimation)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopAnimation {
    if (!_isAnimating) return;
    _isAnimating = NO;
    
    // 移除显示链接
    [_displayLink invalidate];
    _displayLink = nil;
    
    // 平滑停止动画
    [UIView animateWithDuration:0.4
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)setAudioLevel:(CGFloat)level {
    // 确保音频级别在0-1范围内
    _audioLevel = fmax(0.0, fmin(1.0, level));
    
    // 根据音频级别设置目标缩放
    // 使用非线性映射使动画更自然
    _targetScale = 1.0 + (_audioLevel * 0.55);
}

- (void)updateAnimation {
    // 平滑过渡到目标缩放
    CGFloat damping = 0.3; // 阻尼系数
    _currentScale = _currentScale * (1 - damping) + _targetScale * damping;
    
    // 应用缩放变换
    self.transform = CGAffineTransformMakeScale(_currentScale, _currentScale);
    
    // 添加轻微旋转效果模拟音频波动
    CGFloat rotation = sin(CACurrentMediaTime() * 2.0) * 0.01 * _audioLevel;
    self.transform = CGAffineTransformRotate(self.transform, rotation);
}


@end
