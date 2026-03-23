//
//  YTDepthPrimaryButton.m
//  YiTongProject
//

#import "YTDepthPrimaryButton.h"
#import <Masonry/Masonry.h>

static const CGFloat kYTDepthPrimaryDefaultDarkening = 0.78f;

@interface YTDepthPrimaryButton ()

@property (nonatomic, assign, readwrite) CGFloat faceHeight;
@property (nonatomic, assign, readwrite) CGFloat depthOffset;

@property (nonatomic, strong) UIView *depthView;
@property (nonatomic, strong) UIView *faceView;
@property (nonatomic, strong, readwrite) UIButton *actionButton;

@end

@implementation YTDepthPrimaryButton

+ (UIColor *)autoDepthColorForFaceColor:(UIColor *)faceColor darkeningFactor:(CGFloat)factor {
    if (!faceColor) {
        return [UIColor clearColor];
    }
    CGFloat r, g, b, a;
    if (![faceColor getRed:&r green:&g blue:&b alpha:&a]) {
        return faceColor;
    }
    CGFloat k = factor;
    return [UIColor colorWithRed:(r * k) green:(g * k) blue:(b * k) alpha:a];
}

+ (instancetype)learningFlowPrimaryButton {
    return [[self alloc] initWithFaceHeight:54.0 depthOffset:5.0];
}

+ (instancetype)answerResultSheetPrimaryButton {
    return [[self alloc] initWithFaceHeight:52.0 depthOffset:5.0];
}

- (instancetype)initWithFaceHeight:(CGFloat)faceHeight depthOffset:(CGFloat)depthOffset {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _faceHeight = faceHeight;
        _depthOffset = depthOffset;
        _depthDarkeningFactor = kYTDepthPrimaryDefaultDarkening;
        self.backgroundColor = [UIColor clearColor];
        [self yt_buildHierarchy];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _faceHeight = 54.0;
        _depthOffset = 5.0;
        _depthDarkeningFactor = kYTDepthPrimaryDefaultDarkening;
        self.backgroundColor = [UIColor clearColor];
        [self yt_buildHierarchy];
    }
    return self;
}

- (CGFloat)totalHeight {
    return self.faceHeight + self.depthOffset;
}

- (void)setFaceColor:(UIColor *)faceColor {
    _faceColor = faceColor;
    self.faceView.backgroundColor = faceColor;
    [self yt_refreshDepthBackground];
}

- (void)setDepthColor:(UIColor *)depthColor {
    _depthColor = depthColor;
    [self yt_refreshDepthBackground];
}

- (void)setDepthDarkeningFactor:(CGFloat)depthDarkeningFactor {
    _depthDarkeningFactor = depthDarkeningFactor;
    [self yt_refreshDepthBackground];
}

- (void)yt_refreshDepthBackground {
    UIColor *resolved = self.depthColor;
    if (!resolved) {
        resolved = [self.class autoDepthColorForFaceColor:self.faceColor darkeningFactor:self.depthDarkeningFactor];
    }
    self.depthView.backgroundColor = resolved;
}

- (void)yt_buildHierarchy {
    CGFloat radius = self.faceHeight / 2.0;

    [self addSubview:self.depthView];
    [self addSubview:self.faceView];
    [self addSubview:self.actionButton];

    self.depthView.layer.cornerRadius = radius;
    self.depthView.layer.masksToBounds = YES;

    self.faceView.layer.cornerRadius = radius;
    self.faceView.layer.masksToBounds = YES;

    [self.depthView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self).offset(self.depthOffset);
        make.height.mas_equalTo(self.faceHeight);
    }];
    [self.faceView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(self.faceHeight);
    }];
    [self.actionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    self.actionButton.backgroundColor = [UIColor clearColor];
}

- (UIView *)depthView {
    if (!_depthView) {
        _depthView = [[UIView alloc] init];
        _depthView.userInteractionEnabled = NO;
    }
    return _depthView;
}

- (UIView *)faceView {
    if (!_faceView) {
        _faceView = [[UIView alloc] init];
        _faceView.userInteractionEnabled = NO;
    }
    return _faceView;
}

- (UIButton *)actionButton {
    if (!_actionButton) {
        _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _actionButton;
}

@end
