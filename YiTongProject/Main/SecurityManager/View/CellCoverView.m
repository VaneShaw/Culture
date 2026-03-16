//
//  CellCoverView.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/2.
//

#import "CellCoverView.h"
@interface CellCoverView()
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation CellCoverView
- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 10;//圆角
        self.layer.masksToBounds = YES;
        self.titleText = title;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    
    // 遮罩背景图片
    UIImageView *bgImgView = [[UIImageView alloc] init];
    bgImgView.translatesAutoresizingMaskIntoConstraints = NO;
    bgImgView.image = [UIImage imageNamed:@"cover_blue_1"];
    bgImgView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:bgImgView];
    
//    [NSLayoutConstraint activateConstraints:@[
//        [bgImgView.topAnchor constraintEqualToAnchor:self.topAnchor],
//        [bgImgView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
//        [bgImgView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
//        [bgImgView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
//    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [bgImgView.topAnchor constraintEqualToAnchor:self.topAnchor constant:-3],
        [bgImgView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [bgImgView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [bgImgView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:3]
    ]];
    self.clipsToBounds = NO;
    bgImgView.layer.cornerRadius = 8;//圆角
    bgImgView.layer.masksToBounds = YES;
    
    self.bgImgView = bgImgView;
    // 禁止点击穿透
    //self.userInteractionEnabled = YES;
    
    // -------------------------
    // 图标
    // -------------------------
    self.iconView = [[UIImageView alloc] init];
    self.iconView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconView.image = [UIImage imageNamed:@"lock_blue"]; // 替换你的图标
    [self addSubview:self.iconView];
    // -------------------------
    // 文字
    // -------------------------
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.text = self.titleText;
    self.titleLabel.textColor = [self colorWithHexString:@"#2285F4" alpha:1];
    self.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:18];
    self.titleLabel.numberOfLines = 0; // 自动换行
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.titleLabel];
    
    // -------------------------
    // 布局约束
    // -------------------------
    CGFloat middleOffset = 4; // 图标/文字距中间线
    //CGFloat spacing = 8;      // 图标/文字间距
    [NSLayoutConstraint activateConstraints:@[
        // 图标：左右居中，上半区离中间线 4
        [self.iconView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.iconView.bottomAnchor constraintEqualToAnchor:self.centerYAnchor constant:-middleOffset],
        [self.iconView.widthAnchor constraintEqualToConstant:30],
        [self.iconView.heightAnchor constraintEqualToConstant:30],

        // 文字：左右居中，下半区离中间线 4
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.centerYAnchor constant:middleOffset],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
    ]];
}
- (void)updateIconImageColor:(UIColor *)imgColor bgColor:(NSString *)bgColor {
    self.iconView.image = [self imageWithImageName:@"lock_blue" tintColor:imgColor];
    self.bgImgView.hidden = YES;
    if(bgColor.length > 6){
        self.titleLabel.textColor = imgColor;
        self.backgroundColor = [self colorWithHexString:bgColor alpha:0.9];
    } else {
        self.titleLabel.textColor = [self colorWithHexString:@"#63637D" alpha:1];
        self.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
