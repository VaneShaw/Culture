//
//  StoryLockCoverView.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/2.
//

#import "StoryLockCoverView.h"
@interface StoryLockCoverView ()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIPanGestureRecognizer *pan;
@property (nonatomic, assign) BOOL isHandling; // 防止一次手势多次触发
@property (nonatomic, assign) CGFloat startTranslationY;
@end
@implementation StoryLockCoverView{
    CGFloat _startTranslationY;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
        //[self setupGesture];
    }
    return self;
}
/*
- (void)setupGesture {
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector//(handlePan:)];
    self.pan.delegate = self;
    [self addGestureRecognizer:self.pan];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {

    // hidden 时系统本就不会触发，这里只是防御
    if (self.hidden) return;

    CGPoint translation = [pan translationInView:self];
    CGPoint velocity = [pan velocityInView:self];

    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            self.startTranslationY = 0;
            self.isHandling = NO;
        } break;
        case UIGestureRecognizerStateChanged: {
            self.startTranslationY = translation.y;
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {

            if (self.isHandling) return;
            self.isHandling = YES;
            CGFloat distance = self.startTranslationY;
            CGFloat speed = velocity.y;

            // 阈值（模拟 UIScrollView 手感）
            CGFloat distanceThreshold = 80.0;
            CGFloat velocityThreshold = 800.0;
            // 👆 上滑
            if (distance < -distanceThreshold || speed < -velocityThreshold) {
                if (self.swipeUpBlock) {
                    self.swipeUpBlock();
                }
                return;
            }

            // 👇 下滑
            if (distance > distanceThreshold || speed > velocityThreshold) {
                if (self.swipeDownBlock) {
                    self.swipeDownBlock();
                }
                return;
            }

            // 未达阈值 → 什么都不做
        } break;

        default:
            break;
    }
}

#pragma mark - UIGestureRecognizerDelegate

// 不与底下 scrollView 共存（锁态不需要博弈）
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}*/
- (void)setupUI {

    self.translatesAutoresizingMaskIntoConstraints = NO;
    // -----------------------------
    //       背景渐变（图片）
    // -----------------------------
    UIImageView *bgImgView = [[UIImageView alloc] init];
    bgImgView.translatesAutoresizingMaskIntoConstraints = NO;
    bgImgView.image = [UIImage imageNamed:@"gradient_cover"]; // 你的渐变图
    bgImgView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:bgImgView];
    [self sendSubviewToBack:bgImgView];

    [NSLayoutConstraint activateConstraints:@[
        [bgImgView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [bgImgView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [bgImgView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [bgImgView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    // -----------------------------
    // 图标
    // -----------------------------
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.image = [UIImage imageNamed:@"lock_black"];
    [self addSubview:iconView];

    // -----------------------------
    // 文字
    // -----------------------------
    BOOL isLogin = [[UserModel sharedInstance] isLogin];
    NSString *title = @[@"Log in to continue reading",@"Unlock the complete Stories collection"][isLogin];
    NSString *str = @[@"Log In",@"Unlock Now"][isLogin];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = NSLocalizedString(title, @"");
    titleLabel.textColor = [self colorWithHexString:@"#63637D" alpha:1];
    titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:18];
    titleLabel.numberOfLines = 0;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;
    // -----------------------------
    // 按钮
    // -----------------------------
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.layer.cornerRadius = 25;
  
    btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Medium size:18];
    self.btnLogin = btn;
    [self.btnLogin setTitle:NSLocalizedString(str, @"") forState:UIControlStateNormal];
    self.titleLabel.text = NSLocalizedString(title, @"");
    

    
    if(isLogin){
        [btn setBackgroundImage:[UIImage imageNamed:@"button_blue_1"] forState:UIControlStateNormal];
        [btn setTitleColor:[self colorWithHexString:@"#0D1346" alpha:1] forState:UIControlStateNormal];
    } else {
        [btn setTitleColor:[self colorWithHexString:@"#FFFFFF" alpha:1] forState:UIControlStateNormal];
        btn.backgroundColor = [self colorWithHexString:@"#4C9BEF" alpha:1];
    }
    
    [btn addTarget:self action:@selector(clickSubscribe) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btn];

    // -----------------------------
    //       约束
    // -----------------------------
    [NSLayoutConstraint activateConstraints:@[
        // 图标
        [iconView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-250],
        [iconView.widthAnchor constraintEqualToConstant:30],
        [iconView.heightAnchor constraintEqualToConstant:30],

        // 文字
        [titleLabel.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:8],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        // 按钮
        [btn.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:20],
        [btn.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [btn.widthAnchor constraintEqualToConstant:192],
        [btn.heightAnchor constraintEqualToConstant:50],
    ]];
}

#pragma mark - 点击按钮
- (void)clickSubscribe {
    if (self.subscribeHandler) {
        self.subscribeHandler();
    }
}

#pragma mark - HEX 颜色
- (UIColor *)colorWithHexString:(NSString *)hex alpha:(CGFloat)alpha {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                           green:((rgbValue & 0x00FF00) >> 8) / 255.0
                            blue:(rgbValue & 0x0000FF) / 255.0
                           alpha:alpha];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
