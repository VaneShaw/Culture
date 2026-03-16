//
//  ShadowView.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/3.
//

#import "ShadowView.h"
@interface ShadowView()

@end
@implementation ShadowView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        [self setupShadow];
        
        [self addSubview:self.lblTitle];
        [self addSubview:self.lblSubtitle];
        
        self.progressView = [[GradientProgressView alloc]initWithFrame:CGRectMake(self.lblTitle.frame.origin.x, 110, self.lblTitle.frame.size.width,6)];
        self.progressView.layer.cornerRadius = 3;//圆角
        self.progressView.layer.masksToBounds = YES;
        self.progressView.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.progressView];

        [self addSubview:self.lblState];
        [self addSubview:self.lblCompletion];
        [self addSubview:self.btnStart];
        
        int width = (SCREEN_WIDTH - 55)/2;
        int height = 223;
        UIButton *btnView = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btnView.frame = CGRectMake(0, 0, width, height);
        [self addSubview:btnView];
        btnView.backgroundColor = [UIColor clearColor];
        self.btnView = btnView;
        
        CellCoverView *cover = [[CellCoverView alloc] initWithFrame:self.bounds
                                                            title:NSLocalizedString(@"Unlock the full Pinyin course",@"")];
        [self addSubview:cover];
        cover.userInteractionEnabled = NO;
        // AutoLayout 也可以
        cover.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[

            [cover.topAnchor constraintEqualToAnchor:self.topAnchor constant:-0],
            [cover.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:-2],
            [cover.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:2],
            [cover.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0]
        ]];
        self.cover = cover;
        self.cover.hidden = YES;
    }
    return self;
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(12, 22, (SCREEN_WIDTH - 55)/2 - 24, 25)];
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        _lblTitle.numberOfLines = 0;
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(12, 52, (SCREEN_WIDTH - 55)/2 - 20 + 20, 36 + 5)];
        _lblSubtitle.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        _lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
        _lblSubtitle.numberOfLines = 0;
        _lblSubtitle.lineBreakMode = NSLineBreakByWordWrapping;
        
        
    }
    return _lblSubtitle;
}
- (UILabel *)lblState {
    if(!_lblState){
        _lblState = [[UILabel alloc]initWithFrame:CGRectMake(self.lblTitle.frame.origin.x, 16 + self.progressView.frame.origin.y, self.lblTitle.frame.size.width, 14)];
        _lblState.textColor = BLACK_COLOR_1F;
        _lblState.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
    }
    return _lblState;
}
- (UILabel *)lblCompletion {
    if(!_lblCompletion){
        _lblCompletion = [[UILabel alloc]initWithFrame:CGRectMake(self.lblTitle.frame.origin.x, 26 + self.progressView.frame.origin.y + 6, self.lblTitle.frame.size.width, 28)];
        _lblCompletion.textColor = BLACK_COLOR_1F;
        _lblCompletion.font = [UIFont fontWithName:FONT_NAME_Semibold size:20];
    }
    return _lblCompletion;
}
- (UIButton *)btnStart {
    if(!_btnStart){
        _btnStart = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnStart.frame = CGRectMake(self.lblTitle.frame.origin.x, 238 - 16 - 40, self.lblTitle.frame.size.width, 40);
        _btnStart.layer.cornerRadius = 8;//圆角
        _btnStart.layer.masksToBounds = YES;
        _btnStart.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
  
        [_btnStart setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        //[_btnStart addTarget:self action:@selector(btnStartAction:) forControlEvents:UIControlEventTouchUpInside];
        //[_btnStart setTitle:@"Explore Finals " forState:UIControlStateNormal];
        //_btnStart.backgroundColor = [self colorWithHexString:@"#398A80" alpha:1];
    }
    return _btnStart;
}
- (void)btnStartAction:(UIButton *)sender {
    
}
- (void)setupShadow {
    // 默认配置
    _shadowColor = [self colorWithHexString:@"#000000" alpha:0.05]; // 浅灰色阴影
    _shadowRadius = 3.0;  // 阴影模糊 3pt
    _cornerRadius = 12.0; // 圆角 12pt
    
    // 基础设置
    self.backgroundColor = [UIColor whiteColor];
    self.layer.masksToBounds = NO;
    // 阴影配置（四周均匀阴影）
    self.layer.shadowColor = _shadowColor.CGColor;
    self.layer.shadowOffset = CGSizeZero; // 四周阴影需偏移量为0
    self.layer.shadowOpacity = 0.2;       // 完全不透明
    self.layer.shadowRadius = _shadowRadius;
    //圆角
    self.layer.cornerRadius = _cornerRadius;
    // 提升性能：固定阴影路径
    [self updateShadowPath];
    
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateShadowPath]; // 自动布局时更新阴影路径
}
// 更新阴影路径（匹配圆角）
- (void)updateShadowPath {
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:_cornerRadius].CGPath;
}

#pragma mark - 属性设置方法
- (void)setShadowColor:(UIColor *)shadowColor {
    _shadowColor = shadowColor;
    self.layer.shadowColor = shadowColor.CGColor;
}

- (void)setShadowRadius:(CGFloat)shadowRadius {
    _shadowRadius = shadowRadius;
    self.layer.shadowRadius = shadowRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = cornerRadius;
    [self updateShadowPath];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
