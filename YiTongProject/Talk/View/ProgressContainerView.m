//
//  ProgressContainerView.m
//  YiTongProject
//
//  Created by ios01 on 2026/2/28.
//

#import "ProgressContainerView.h"

@implementation ProgressContainerView {
    CAShapeLayer *_borderLayer;       // 黑色边框
    CAShapeLayer *_fillShapeLayer;    // 渐变遮罩路径
    CAGradientLayer *_gradientLayer;  // 渐变颜色
}

#pragma mark - 初始化

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
        [self setupLayers];
        self.progress = 0;
        self.gradientColors = @[[UIColor redColor], [UIColor yellowColor]]; // 默认渐变
    }
    return self;
}

- (void)setupViews {
    // 左侧标题
    self.leftLabel = [[UILabel alloc] init];
    self.leftLabel.font = [UIFont systemFontOfSize:14];
    self.leftLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.leftLabel];
    
    // 右侧百分比
    self.rightLabel = [[UILabel alloc] init];
    self.rightLabel.font = [UIFont boldSystemFontOfSize:14];
    self.rightLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.rightLabel];
}

- (void)setupLayers {
    // 边框层
    _borderLayer = [CAShapeLayer layer];
    _borderLayer.strokeColor = [UIColor blackColor].CGColor;
    _borderLayer.fillColor = [UIColor clearColor].CGColor;
    _borderLayer.lineWidth = 1.0;
    [self.layer addSublayer:_borderLayer];
    
    // 渐变层
    _gradientLayer = [CAGradientLayer layer];
    _gradientLayer.startPoint = CGPointMake(0, 0.5);
    _gradientLayer.endPoint = CGPointMake(1, 0.5);
    [self.layer insertSublayer:_gradientLayer below:_borderLayer];
    
    // 遮罩层，用于控制渐变填充进度
    _fillShapeLayer = [CAShapeLayer layer];
    _fillShapeLayer.fillColor = [UIColor blackColor].CGColor;
    _gradientLayer.mask = _fillShapeLayer;
}

#pragma mark - 布局

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat height = self.bounds.size.height;
    CGFloat leftWidth = 110;
    CGFloat rightWidth = 38;
    
    // 左标题
    self.leftLabel.frame = CGRectMake(0, 0, leftWidth, height);
    
    // 右百分比
    self.rightLabel.frame = CGRectMake(self.bounds.size.width - rightWidth, 0, rightWidth, height);
    
    // 更新边框路径
    [self updateBorderPath];
    
    // 更新渐变填充
    [self updateGradient];
}

#pragma mark - 绘制路径

- (void)updateBorderPath {
    CGFloat height = self.bounds.size.height;
    CGFloat leftWidth = 110;
    CGFloat rightWidth = 38;
    CGFloat overlap = 4; // 左右交集宽度
    
    // 左椭圆
    UIBezierPath *leftPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, leftWidth, height)
                                                        cornerRadius:height/2];
    
    // 右圆
    UIBezierPath *rightPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(leftWidth - overlap, 0, rightWidth, height)];
    
    // 交集部分透明，使用奇偶填充
    [leftPath appendPath:rightPath];
    _borderLayer.path = leftPath.CGPath;
    _borderLayer.fillRule = kCAFillRuleEvenOdd;
}

- (void)updateGradient {
    _gradientLayer.frame = self.bounds;
    
    // 安全方式设置CGColor数组
    NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:self.gradientColors.count];
    for (UIColor *color in self.gradientColors) {
        [cgColors addObject:(id)color.CGColor];
    }
    _gradientLayer.colors = cgColors;
    
    CGFloat totalWidth = self.bounds.size.width;
    _fillShapeLayer.frame = CGRectMake(0, 0, totalWidth * self.progress, self.bounds.size.height);
    
    // 遮罩路径 = 与边框相同
    CGFloat height = self.bounds.size.height;
    CGFloat leftWidth = 110;
    CGFloat rightWidth = 38;
    CGFloat overlap = 4;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, leftWidth, height)
                                                       cornerRadius:height/2];
    UIBezierPath *rightPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(leftWidth - overlap, 0, rightWidth, height)];
    [maskPath appendPath:rightPath];
    _fillShapeLayer.path = maskPath.CGPath;
    _fillShapeLayer.fillRule = kCAFillRuleEvenOdd;
}

#pragma mark - 设置进度

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    _progress = MIN(MAX(progress, 0), 1.0);
    self.rightLabel.text = [NSString stringWithFormat:@"%.0f%%", _progress * 100];
    CGFloat totalWidth = self.bounds.size.width;
    if (animated) {
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.3];
        _fillShapeLayer.frame = CGRectMake(0, 0, totalWidth * _progress, self.bounds.size.height);
        [CATransaction commit];
    } else {
        _fillShapeLayer.frame = CGRectMake(0, 0, totalWidth * _progress, self.bounds.size.height);
    }
    
}

@end
