//
//  GradientProgressView.m
//  YiTongProject
//
//  Created by ios01 on 2025/7/3.
//

#import "GradientProgressView.h"

@implementation GradientProgressView{
    CALayer *_progressLayer;
    CAGradientLayer *_gradientLayer;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}
- (void)setupView {
    // 默认配置
    //#C0DEFF
    // 背景层
    self.backgroundColor = [self colorWithHexString:@"#F4F3FD" alpha:1];
    //self.layer.cornerRadius = self.frame.size.height / 2;
    self.clipsToBounds = YES;
    
    // 进度遮罩层
    _progressLayer = [CALayer layer];
    _progressLayer.frame = CGRectMake(0, 0, 0, self.frame.size.height);
    _progressLayer.backgroundColor = [UIColor blackColor].CGColor;
    _progressLayer.cornerRadius = self.layer.cornerRadius;

    //渐变色
    _gradientLayer = [CAGradientLayer layer];
    _gradientLayer.colors = @[
        (id)[self colorWithHexString:@"#C0DEFF" alpha:1].CGColor,
        (id)[self colorWithHexString:@"#3B8AD9" alpha:1].CGColor
     ];
    _gradientLayer.startPoint = CGPointMake(0, 0.5);
    _gradientLayer.endPoint = CGPointMake(1, 0.5);
    

    _gradientLayer.frame = self.bounds;
    _gradientLayer.cornerRadius = self.layer.cornerRadius;
    [self.layer addSublayer:_gradientLayer];
    _gradientLayer.mask = _progressLayer;
}

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:NO];
}

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    _progress = MIN(MAX(progress, 0.0), 1.0);
    CGFloat targetWidth = self.frame.size.width * _progress;


    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self->_progressLayer.frame;
            frame.size.width = targetWidth;
            self->_progressLayer.frame = frame;
        }];
    } else {
        CGRect frame = _progressLayer.frame;
        frame.size.width = targetWidth;
        _progressLayer.frame = frame;
    }
}
- (void)setColorProgress:(CGFloat)progress color:(NSString *)color alpha:(float)alpha animated:(BOOL)animated {
    _progress = MIN(MAX(progress, 0.0), 1.0);
    CGFloat targetWidth = self.frame.size.width * _progress;
    
    _gradientLayer.colors = @[
        (id)[self colorWithHexString:color alpha:alpha].CGColor,
        (id)[self colorWithHexString:color alpha:1].CGColor
    ];
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self->_progressLayer.frame;
            frame.size.width = targetWidth;
            self->_progressLayer.frame = frame;
        }];
    } else {
        CGRect frame = _progressLayer.frame;
        frame.size.width = targetWidth;
        _progressLayer.frame = frame;
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated color:(NSArray *)colors {
    _progress = MIN(MAX(progress, 0.0), 1.0);
    CGFloat targetWidth = self.frame.size.width * _progress;

    //NSArray *colors = @[@"#E3F2FD",@"#63A8F5"];
    if(colors.count > 1){
        _gradientLayer.startPoint = CGPointMake(progress, 0.5);
        _gradientLayer.endPoint = CGPointMake(0, 0.5);
        _gradientLayer.colors = @[
            (id)[self colorWithHexString:colors[0] alpha:1].CGColor, // 浅色
            (id)[self colorWithHexString:colors[1] alpha:1].CGColor // 深色
        ];
    }

    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self->_progressLayer.frame;
            frame.size.width = targetWidth;
            self->_progressLayer.frame = frame;
        }];
    } else {
        CGRect frame = _progressLayer.frame;
        frame.size.width = targetWidth;
        _progressLayer.frame = frame;
    }
}

- (void)addDashedBorderWithColor:(UIColor *)color
                       lineWidth:(CGFloat)lineWidth
                     dashPattern:(NSArray<NSNumber *> *)dashPattern
                     cornerRadius:(CGFloat)cornerRadius {
    
    // 移除已有的虚线边框
    for (CALayer *layer in self.layer.sublayers) {
        if ([layer.name isEqualToString:@"DashedBorderLayer"]) {
            [layer removeFromSuperlayer];
        }
    }
    
    // 创建虚线图层
    CAShapeLayer *borderLayer = [CAShapeLayer layer];
    borderLayer.name = @"DashedBorderLayer";
    borderLayer.frame = self.bounds;
    borderLayer.fillColor = [UIColor clearColor].CGColor;
    borderLayer.strokeColor = color.CGColor;
    borderLayer.lineWidth = lineWidth;
    borderLayer.lineDashPattern = dashPattern;
    
    // 设置圆角
    if (cornerRadius > 0) {
        borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:borderLayer.bounds
                                                     cornerRadius:cornerRadius].CGPath;
    } else {
        borderLayer.path = [UIBezierPath bezierPathWithRect:borderLayer.bounds].CGPath;
    }
    
    [self.layer addSublayer:borderLayer];
}

@end
