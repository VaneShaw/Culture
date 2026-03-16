//
//  AudioBarsView.m
//  YiTongProject
//
//  Created by ios01 on 2025/11/11.
//

#import "AudioBarsView.h"
@interface AudioBarsView ()
@property (nonatomic, strong) UIView *bar1;
@property (nonatomic, strong) UIView *bar2;
@property (nonatomic, strong) UIView *bar3;

@property (nonatomic, strong) NSTimer *timer;
@end
@implementation AudioBarsView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        _barColor = [UIColor greenColor];
        [self setupBars];
    }
    return self;
}

- (void)setupBars {
    CGFloat barWidth = self.bounds.size.width / 5;
    CGFloat bottom = self.bounds.size.height;

    _bar1 = [[UIView alloc] initWithFrame:CGRectMake(0, bottom, barWidth, 0)];
    _bar2 = [[UIView alloc] initWithFrame:CGRectMake(barWidth*2-0.5,bottom, barWidth, 0)];
    _bar3 = [[UIView alloc] initWithFrame:CGRectMake(barWidth*4-1, bottom, barWidth, 0)];

    _bar1.layer.cornerRadius = barWidth/2;//圆角
    _bar1.layer.masksToBounds = YES;
    
    _bar2.layer.cornerRadius = barWidth/2;//圆角
    _bar2.layer.masksToBounds = YES;
    
    _bar3.layer.cornerRadius = barWidth/2;//圆角
    _bar3.layer.masksToBounds = YES;
    
    _bar1.backgroundColor = _bar2.backgroundColor = _bar3.backgroundColor = _barColor;
    [self addSubview:_bar1];
    [self addSubview:_bar2];
    [self addSubview:_bar3];
}

#pragma mark - 动画

- (void)startAnimating {
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.23
                                                  target:self
                                                selector:@selector(randomAnimate)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)randomAnimate {
    CGFloat maxHeight = self.bounds.size.height; // 现在最大就是 14

    NSArray *patterns = @[
        @[@(0.3*maxHeight), @(0.6*maxHeight), @(0.9*maxHeight)], // 短 中 长
        @[@(0.6*maxHeight), @(0.3*maxHeight), @(0.9*maxHeight)], // 中 短 长
        @[@(0.9*maxHeight), @(0.6*maxHeight), @(0.3*maxHeight)]  // 长 中 短
    ];
    
    NSUInteger index = arc4random_uniform((uint32_t)patterns.count);
    NSArray *heights = patterns[index];
    
    [UIView animateWithDuration:0.25 animations:^{
        self.bar1.frame = CGRectMake(self.bar1.frame.origin.x,
                                     maxHeight - [heights[0] floatValue],
                                     self.bar1.frame.size.width,
                                     [heights[0] floatValue]);
        self.bar2.frame = CGRectMake(self.bar2.frame.origin.x,
                                     maxHeight - [heights[1] floatValue],
                                     self.bar2.frame.size.width,
                                     [heights[1] floatValue]);
        self.bar3.frame = CGRectMake(self.bar3.frame.origin.x,
                                     maxHeight - [heights[2] floatValue],
                                     self.bar3.frame.size.width,
                                     [heights[2] floatValue]);
    }];
}

- (void)stopAnimatingWithHeights:(NSArray *)heights {
    [self.timer invalidate];
    self.timer = nil;
    
    CGFloat maxHeight = 15;
    if (heights.count != 3) return;
    
    
    float bar0hgiths = [heights[0] floatValue];
    float bar1hgiths = [heights[1] floatValue];
    float bar2hgiths = [heights[2] floatValue];
    [UIView animateWithDuration:0.25 animations:^{
        self.bar1.frame = CGRectMake(self.bar1.frame.origin.x,
                                     maxHeight - bar0hgiths,
                                     self.bar1.frame.size.width,
                                     bar0hgiths);
        self.bar2.frame = CGRectMake(self.bar2.frame.origin.x,
                                     maxHeight - bar1hgiths,
                                     self.bar2.frame.size.width,
                                     bar1hgiths);
        self.bar3.frame = CGRectMake(self.bar3.frame.origin.x,
                                     maxHeight - bar2hgiths,
                                     self.bar3.frame.size.width,
                                     bar2hgiths);
    }];
}

- (void)changeBarColor:(UIColor *)color {
    self.barColor = color;
    self.bar1.backgroundColor = self.bar2.backgroundColor = self.bar3.backgroundColor = color;
}

@end
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

