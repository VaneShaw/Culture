//
//  GradientLabel.m
//  YiTongProject
//
//  Created by ios01 on 2025/11/28.
//

#import "GradientLabel.h"

#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

@interface GradientLabel ()
@property (nonatomic, strong) CATextLayer *textMaskLayer;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@property (nonatomic, strong) CALayer *maskLayer;
@property (nonatomic, strong) CATextLayer *singleLineMaskLayer;
@end

@implementation GradientLabel

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // 渐变层
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.startPoint = CGPointMake(0, 0.5);
    self.gradientLayer.endPoint   = CGPointMake(1, 0.5);
    [self.layer addSublayer:self.gradientLayer];

    // 文字作为 Mask
    self.textMaskLayer = [CATextLayer layer];
    self.textMaskLayer.contentsScale = [UIScreen mainScreen].scale;

    // 文字透明
    self.textColor = UIColor.clearColor;
}

- (void)setGradientColors:(NSArray<UIColor *> *)colors locations:(NSArray<NSNumber *> *)locations {
    if (colors.count != 3) return;

    self.gradientLayer.colors = @[
        (id)colors[0].CGColor,
        (id)colors[1].CGColor,
        (id)colors[2].CGColor
    ];

    self.gradientLayer.locations = locations ?: @[@0.0, @0.5, @1.0];
    [self setNeedsLayout];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.text || self.text.length == 0) return;

    /** --------------------------------------------------------
        判断单行 or 多行
        numberOfLines == 1 并且没有换行符 → 单行模式
     -------------------------------------------------------- */
    BOOL isSingleLine = (self.numberOfLines == 1 &&
                         [self.text rangeOfString:@"\n"].location == NSNotFound);

    if (isSingleLine) {
        //[self applySingleLineMask];
        [self layoutSubviews111];
    } else {
        [self layoutSubviews222];
        //[self applyMultiLineMask];
        
    }
}

#pragma mark - 单行 Mask（颜色宽度 = 文字宽度）
- (void)applySingleLineMask {
    // 1. 计算文字宽度
    CGSize textSize = [self.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.bounds.size.height)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:self.font}
                                              context:nil].size;

    CGFloat width = textSize.width;
    CGFloat x = 0;

    if (self.textAlignment == NSTextAlignmentCenter) {
        x = (self.bounds.size.width - width) * 0.5;
    } else if (self.textAlignment == NSTextAlignmentRight) {
        x = self.bounds.size.width - width;
    }

    // 2. 渐变宽度 = 文字宽度
    self.gradientLayer.frame = CGRectMake(x, 0, width, self.bounds.size.height);

    // 3. 使用 CATextLayer 作为 mask
    if (!self.singleLineMaskLayer) {
        self.singleLineMaskLayer = [CATextLayer layer];
        self.singleLineMaskLayer.contentsScale = [UIScreen mainScreen].scale;
    }
    self.singleLineMaskLayer.frame = self.gradientLayer.bounds;
    self.singleLineMaskLayer.string = self.text;
    self.singleLineMaskLayer.fontSize = self.font.pointSize;
    self.singleLineMaskLayer.font = (__bridge CFTypeRef)self.font.fontName;
    self.singleLineMaskLayer.alignmentMode = kCAAlignmentLeft;

    self.gradientLayer.mask = self.singleLineMaskLayer;
}

#pragma mark - 多行 Mask（绘制文本，完美支持居中 + 换行）
- (void)applyMultiLineMask {
    // 1. UILabel 计算真实的文本区域
    CGRect textRect = [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];

    // 2. 校正 X 对齐
    CGFloat x = 0;
    if (self.textAlignment == NSTextAlignmentCenter) {
        x = (self.bounds.size.width - textRect.size.width) * 0.5;
    } else if (self.textAlignment == NSTextAlignmentRight) {
        x = self.bounds.size.width - textRect.size.width;
    }
    textRect.origin.x = x;

    // 3. 绘制文字 Bitmap
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    [self.text drawInRect:textRect withAttributes:@{NSFontAttributeName:self.font}];
    UIImage *maskImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // 4. 完整覆盖整个 label
    self.gradientLayer.frame = self.bounds;

    // 5. 生成 mask
    if (!self.maskLayer) {
        self.maskLayer = [CALayer layer];
    }
    self.maskLayer.frame = self.bounds;
    self.maskLayer.contents = (__bridge id)maskImage.CGImage;

    self.gradientLayer.mask = self.maskLayer;
}
- (void)layoutSubviews111 {
    [super layoutSubviews];

    // 1. 计算文字实际宽度（非常重要）
    CGSize textSize = [self.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.bounds.size.height)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName: self.font}
                                              context:nil].size;

    // 2. 渐变层宽度=文字宽度（避免右侧空白导致 3rd color 表现不出来）
    CGFloat gradientWidth = textSize.width;
    CGFloat gradientX = 0;

    if (self.textAlignment == NSTextAlignmentCenter) {
        gradientX = (self.bounds.size.width - gradientWidth) * 0.5;
    } else if (self.textAlignment == NSTextAlignmentRight) {
        gradientX = self.bounds.size.width - gradientWidth;
    }

    self.gradientLayer.frame = CGRectMake(gradientX,
                                          0,
                                          gradientWidth,
                                          self.bounds.size.height);

    // 3. mask 同样只覆盖文字宽度
    self.textMaskLayer.frame = self.gradientLayer.bounds;
    self.textMaskLayer.string = self.text;
    self.textMaskLayer.font = (__bridge CFTypeRef)self.font.fontName;
    self.textMaskLayer.fontSize = self.font.pointSize;
    self.textMaskLayer.alignmentMode = kCAAlignmentLeft;

    self.gradientLayer.mask = self.textMaskLayer;
}
- (void)layoutSubviews222 {
    [super layoutSubviews];

    if (!self.text || self.text.length == 0) return;

    // 1. 让 UILabel 自己算文本区域（支持多行 + 对齐方式）
    CGRect textRect = [self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];

    // 2. 计算 X 对齐（最核心的修复）
    CGFloat x = 0;
    if (self.textAlignment == NSTextAlignmentCenter) {
        x = (self.bounds.size.width - textRect.size.width) * 0.5;
    } else if (self.textAlignment == NSTextAlignmentRight) {
        x = (self.bounds.size.width - textRect.size.width);
    }
    textRect.origin.x = x;

    // 3. 绘制文字图像（作为 mask）
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    [self.text drawInRect:textRect
           withAttributes:@{ NSFontAttributeName: self.font }];
    UIImage *textImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // 4. 生成文字 mask
    if (!self.maskLayer) {
        self.maskLayer = [CALayer layer];
    }
    self.maskLayer.frame = self.bounds;
    self.maskLayer.contents = (__bridge id)textImage.CGImage;

    // 5. 渐变层覆盖整个 label（这样三段颜色最准确）
    self.gradientLayer.frame = self.bounds;
    self.gradientLayer.mask = self.maskLayer;
}
@end
