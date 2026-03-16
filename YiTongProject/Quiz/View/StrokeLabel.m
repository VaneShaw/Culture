//
//  StrokeLabel.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/28.
//

#import "StrokeLabel.h"

@implementation StrokeLabel
- (void)drawTextInRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, self.strokeWidth);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetTextDrawingMode(context, kCGTextStroke);

    self.textColor = self.strokeColor;
    [super drawTextInRect:rect]; // 描边

    CGContextSetTextDrawingMode(context, kCGTextFill);
    self.textColor = [UIColor whiteColor];
    [super drawTextInRect:rect]; // 填充
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
