//
//  CountDownButton.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/2.
//

#import "CountDownButton.h"
@interface CountDownButton()

@end
@implementation CountDownButton {
    NSTimer *_timer;
    NSInteger _remainingTime;
    UILabel *lblTime;
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _countDownTime = 60; // 默认60秒
        [self setupButton];
    }
    return self;
}

- (void)setupButton {

    self.userInteractionEnabled = NO;
    self.countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 105, 48)];
    self.countdownLabel.textAlignment = NSTextAlignmentCenter;
    self.countdownLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightMedium];
    
    self.countdownLabel.textColor = [self colorWithHexString:@"#C0D0E0" alpha:1];
    self.countdownLabel.text = NSLocalizedString(@"Send Code", @"");
    [self addSubview:self.countdownLabel];
}

#pragma mark - 点击事件
- (void)buttonClicked {
    if (_timer) return; // 防止重复点击
    
    // 1. 触发外部业务逻辑（如发送验证码请求）
    if (self.countDownBlock) {
        self.countDownBlock();
    }
    
    // 2. 开始倒计时
    [self startCountDown];
}

#pragma mark - 倒计时控制
- (void)startCountDown {
    _remainingTime = _countDownTime;
    self.enabled = NO;
    self.userInteractionEnabled = NO;
    self.countdownLabel.textColor = [self colorWithHexString:@"#A4CAF1" alpha:1];
  
    // 设置定时器
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(updateCountDown)
                                           userInfo:nil
                                            repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    [self updateCountDown]; // 立即更新一次
}

- (void)updateCountDown {
    if (_remainingTime <= 0) {
        [self stopCountDown];
        return;
    }
    
    // 更新按钮标题
    NSString *str = NSLocalizedString(@"Resend",@"");
    NSString *title = [NSString stringWithFormat:@"%@ (%lds)",str,(long)_remainingTime];
    //[self setTitle:title forState:UIControlStateDisabled];

    self.countdownLabel.text = title;
    self.countdownLabel.textColor = [self colorWithHexString:@"#C0D0E0" alpha:1];
    _remainingTime--;
}
- (void)stopCountDown {
    [_timer invalidate];
    _timer = nil;
    self.enabled = YES;
    self.userInteractionEnabled = YES;
    //self.titleLabel.tintColor = Main_COLOR;
    //[self setTitle:@"Send Code" forState:UIControlStateNormal];
    self.countdownLabel.textColor = Main_COLOR;
    self.countdownLabel.text = NSLocalizedString(@"Send Code",@"");
}
#pragma mark - 销毁时释放定时器
- (void)dealloc {
    [_timer invalidate];
    _timer = nil;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
