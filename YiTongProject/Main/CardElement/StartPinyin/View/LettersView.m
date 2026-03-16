//
//  LettersView.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/3.
//
#import "LettersView.h"

@implementation LettersView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        [self setupShadow];
        //self.backgroundColor = [self colorWithHexString:@"#FFE0E9" alpha:1];
        [self addSubview:self.lblTitle];
        [self addSubview:self.lblSubtitle];
        [self addSubview:self.btnChart];
        
        UIButton *btnView = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btnView.frame = CGRectMake(20, 10, (SCREEN_WIDTH - 55)/2, 172);
        [self addSubview:btnView];
        btnView.backgroundColor = [UIColor clearColor];
        self.btnView = btnView;
    }
    return self;
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(12, 22, (SCREEN_WIDTH - 55)/2 - 24, 27)];
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        _lblTitle.numberOfLines = 0;
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(self.lblTitle.frame.origin.x,  54 , self.lblTitle.frame.size.width, 36 + 5)];
        _lblSubtitle.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        _lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
        _lblSubtitle.numberOfLines = 0;
    }
    return _lblSubtitle;
}
- (UIButton *)btnChart {
    if(!_btnChart){
        _btnChart = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnChart.frame = CGRectMake((SCREEN_WIDTH-55)/2 - 98 - 18, 172-26-18, 98, 26);
        _btnChart.layer.cornerRadius = 13;//圆角
        _btnChart.layer.masksToBounds = YES;
        _btnChart.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:12];
        _btnChart.layer.masksToBounds = YES;
        _btnChart.layer.borderWidth = 1;//边框
        _btnChart.layer.borderColor = [self colorWithHexString:@"#FC789F" alpha:1].CGColor;
        [_btnChart setTitleColor:[self colorWithHexString:@"#FC789F" alpha:1] forState:UIControlStateNormal];
        //[_btnChart addTarget:self action:@selector(btnStartAction:) forControlEvents:UIControlEventTouchUpInside];

        _btnChart.backgroundColor = [self colorWithHexString:@"#FFE0E9" alpha:1];
        _btnChart.titleEdgeInsets = UIEdgeInsetsMake(0,-18, 0, 0);
        UIImageView *imgArrow = [[UIImageView alloc]initWithFrame:CGRectMake(98-16-8, 5, 16, 16)];
        imgArrow.image = [UIImage imageNamed:@"next_pink"];
        [_btnChart addSubview:imgArrow];
    }
    return _btnChart;
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
