//
//  YTRecordingMeterBarsView.m
//

#import "YTRecordingMeterBarsView.h"
#import <math.h>

static const NSInteger kYTBarCount = 20;
static const CGFloat kYTBarWidth = 2.0;
static const CGFloat kYTBarGap = 3.0;
static const CGFloat kYTMinHeightRatio = 0.12f;

/// 每条起伏系数（0~1）；`phase` 随时间增大时波形沿索引方向流动
static float YTBarWaveMultiplier(NSInteger i, CGFloat phase) {
    float t = (kYTBarCount <= 1) ? 0.f : (float)i / (float)(kYTBarCount - 1);
    float a = 0.5f + 0.5f * sinf(t * 2.65f * (float)M_PI + phase);
    float b = 0.5f + 0.5f * sinf(t * 4.9f * (float)M_PI + 0.85f + phase * 1.35f);
    float c = 0.5f + 0.5f * sinf((float)i * 0.41f + 1.15f + phase * 0.95f);
    float mix = a * 0.42f + b * 0.38f + c * 0.20f;
    return 0.16f + 0.84f * mix;
}

@interface YTRecordingMeterBarsView ()
@property (nonatomic, strong) NSArray<UIView *> *barViews;
@property (nonatomic, assign) CGFloat smoothedLevel;
@end

@implementation YTRecordingMeterBarsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        _barColor = [UIColor whiteColor];
        _smoothedLevel = kYTMinHeightRatio;
        _wavePhase = 0;
        [self yt_addBars];
    }
    return self;
}

- (void)yt_addBars {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:kYTBarCount];
    for (NSInteger i = 0; i < kYTBarCount; i++) {
        UIView *v = [self yt_makeBar];
        [arr addObject:v];
        [self addSubview:v];
    }
    self.barViews = [arr copy];
}

- (UIView *)yt_makeBar {
    UIView *v = [[UIView alloc] init];
    v.layer.cornerRadius = kYTBarWidth / 2.0;
    v.layer.masksToBounds = YES;
    v.backgroundColor = self.barColor;
    return v;
}

- (void)setBarColor:(UIColor *)barColor {
    _barColor = barColor ?: [UIColor whiteColor];
    for (UIView *v in self.barViews) {
        v.backgroundColor = _barColor;
    }
}

- (void)setWavePhase:(CGFloat)wavePhase {
    _wavePhase = wavePhase;
    [self setNeedsLayout];
}

- (void)setMeterLevel:(CGFloat)meterLevel {
    CGFloat v = MAX(0.0, MIN(1.0, meterLevel));
    _meterLevel = v;
    self.smoothedLevel = self.smoothedLevel * 0.58 + v * 0.42;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;
    if (W < 1 || H < 1 || self.barViews.count != kYTBarCount) return;

    CGFloat totalBarW = kYTBarWidth * (CGFloat)kYTBarCount + kYTBarGap * (CGFloat)(kYTBarCount - 1);
    CGFloat x0 = (W - totalBarW) / 2.0;
    CGFloat midY = H / 2.0;
    CGFloat base = self.smoothedLevel;
    CGFloat phase = self.wavePhase;

    [self.barViews enumerateObjectsUsingBlock:^(UIView *bar, NSUInteger idx, BOOL *stop) {
        float wave = YTBarWaveMultiplier((NSInteger)idx, phase);
        CGFloat amp = kYTMinHeightRatio + (1.0 - kYTMinHeightRatio) * base * wave;
        CGFloat h = MAX(1.5, H * amp);
        CGFloat x = x0 + (kYTBarWidth + kYTBarGap) * (CGFloat)idx;
        CGFloat y = midY - h / 2.0;
        bar.frame = CGRectMake(x, y, kYTBarWidth, h);
    }];
}

@end
