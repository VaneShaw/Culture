//
//  EllipseGradientView.m
//  YiTongProject
//
//  Created by ios01 on 2026/2/28.
//

#import "EllipseGradientView.h"
@interface EllipseGradientView ()

@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) NSArray<UIColor *> *gradientColors;

@end
@implementation EllipseGradientView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.gradientColors = @[[UIColor redColor], [UIColor orangeColor], [UIColor yellowColor]]; // 默认渐变色
        [self loadImage];
    }
    return self;
}

- (void)loadImage {
    // 加载图片
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"union_blakc" ofType:@"png"];
    if (imagePath) {
        self.originalImage = [UIImage imageWithContentsOfFile:imagePath];
    } else {
        // 如果没有找到图片，创建一个示例椭圆
        self.originalImage = [self createSampleEllipseImage];
    }
}

// 创建示例椭圆图片（用于测试）
- (UIImage *)createSampleEllipseImage {
    CGSize size = CGSizeMake(300, 200);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(10, 10, 280, 180)];
    [[UIColor blackColor] setStroke];
    path.lineWidth = 2;
    [path stroke];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)setGradientColors:(NSArray<UIColor *> *)colors {
    _gradientColors = colors;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!self.originalImage) return;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 创建图片上下文
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    CGContextRef imageContext = UIGraphicsGetCurrentContext();
    
    // 绘制原始图片
    [self.originalImage drawInRect:self.bounds];
    
    // 获取图片中的黑色线条信息（假设线条是黑色的）
    UIImage *lineImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 创建掩码层
    CGImageRef maskRef = lineImage.CGImage;
    
    // 创建颜色掩码 - 只提取黑色线条
    const CGFloat maskingColors[6] = {0, 0.1, 0, 0.1, 0, 0.1}; // RGB范围，提取接近黑色的像素
    
    CGImageRef mask = CGImageCreateWithMaskingColors(maskRef, maskingColors);
    
    // 清除临时上下文
    UIGraphicsEndImageContext();
    
    if (mask) {
        // 保存当前图形状态
        CGContextSaveGState(context);
        
        // 应用蒙版
        CGContextClipToMask(context, self.bounds, mask);
        
        // 绘制渐变色
        [self drawGradientInContext:context];
        
        // 恢复图形状态
        CGContextRestoreGState(context);
        
        // 再次绘制原始图片的线条部分
        [self.originalImage drawInRect:self.bounds blendMode:kCGBlendModeNormal alpha:1.0];
        
        // 释放资源
        CGImageRelease(mask);
    } else {
        // 如果掩码创建失败，直接绘制渐变
        [self drawGradientInContext:context];
    }
}

- (void)drawGradientInContext:(CGContextRef)context {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in self.gradientColors) {
        [cgColors addObject:(id)color.CGColor];
    }
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)cgColors, NULL);
    
    CGPoint startPoint = CGPointMake(0, 0);
    CGPoint endPoint = CGPointMake(self.bounds.size.width, self.bounds.size.height);
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

@end
