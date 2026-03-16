//
//  PaymentFooterView.m
//  YiTongProject
//
//  Created by ios01 on 2025/11/28.
//

#import "PaymentFooterView.h"
@interface PaymentFooterView()
@property (strong, nonatomic) UIView *exclusiveView;
@property (strong, nonatomic) UIView *helpEnView;
@property (strong, nonatomic) UIView *helpCnView;
@property (strong, nonatomic) UIButton *btnPlay;


@end
@implementation PaymentFooterView
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.exclusiveView];
        
        UIView *tempView;
        int height = 25;
        if(IS_OVERSEAS_VERSION){
            [self addSubview:self.helpEnView];
            tempView = self.helpEnView;
            self.frame = CGRectMake(0, 0, SCREEN_WIDTH, 20 + self.exclusiveView.frame.size.height + self.helpEnView.frame.size.height + height);
        } else {
            [self addSubview:self.helpCnView];
            tempView = self.helpCnView;
            self.frame = CGRectMake(0, 0, SCREEN_WIDTH, 20 + self.exclusiveView.frame.size.height + self.helpCnView.frame.size.height + height);
        }
        
        GradientLabel *titleLabel = [[GradientLabel alloc] init];
        titleLabel.text = NSLocalizedString(@"Service & Help",@"");
        titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [tempView addSubview:titleLabel];
        [titleLabel setGradientColors:@[
            [self colorWithHexString:@"#4DECFF" alpha:1], //
            [self colorWithHexString:@"#CDF5FF" alpha:1], // CDF5FF
            [self colorWithHexString:@"#FEC9FF" alpha:1]  // FEC9FF
        ] locations:nil];
 
        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.topAnchor constraintEqualToAnchor:tempView.topAnchor constant:40],
            [titleLabel.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:20],
            [titleLabel.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-20],
        ]];
    }
    return self;
}

- (UIView *)helpCnView {
    if(!_helpCnView){
        _helpCnView = [UIView new];
        _helpCnView.frame = CGRectMake(0, self.exclusiveView.frame.size.height + 20, SCREEN_WIDTH, 285);
        UIView *tempView = _helpCnView;
        for (int i = 0; i < 2; i++) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            btn.backgroundColor = [self colorWithHexString:@"#0F103B" alpha:1];
            btn.layer.cornerRadius = 8;
            btn.layer.masksToBounds = YES;
            btn.translatesAutoresizingMaskIntoConstraints = NO;
            [tempView addSubview:btn];
            // 约束：上边距
            if (i == 0) {
                [btn.topAnchor constraintEqualToAnchor:tempView.topAnchor constant:85].active = YES;
                self.btnSubscriptions = btn;
            } else {
                UIButton *prevBtn = tempView.subviews[tempView.subviews.count - 2];
                [btn.topAnchor constraintEqualToAnchor:prevBtn.bottomAnchor constant:12].active = YES;
                self.btnHelp = btn;
            }
            [btn.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:20].active = YES;
            [btn.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-20].active = YES;

            // -------- 图片 --------
            UIImageView *imgIcon = [UIImageView new];
            imgIcon.image = [UIImage imageNamed:@"img_arrow_gray"];
            imgIcon.translatesAutoresizingMaskIntoConstraints = NO;
            [btn addSubview:imgIcon];
            [NSLayoutConstraint activateConstraints:@[
                [imgIcon.widthAnchor constraintEqualToConstant:20],
                [imgIcon.heightAnchor constraintEqualToConstant:20],
                [imgIcon.topAnchor constraintEqualToAnchor:btn.topAnchor constant:11],
                [imgIcon.trailingAnchor constraintEqualToAnchor:btn.trailingAnchor constant:-3]
            ]];
            // -------- 标题 --------
            UILabel *lblTitle = [UILabel new];
            lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
            NSString *strTitle = @[@"Manage Subscription",@"Customer Support"][i];
            lblTitle.text = NSLocalizedString(strTitle, @"");
            lblTitle.font = [UIFont fontWithName:FONT_NAME_Medium size:16];
            lblTitle.textColor = [self colorWithHexString:@"#DBDBF2" alpha:1];
            [btn addSubview:lblTitle];
            [NSLayoutConstraint activateConstraints:@[
                [lblTitle.leadingAnchor constraintEqualToAnchor:btn.leadingAnchor constant:10],
                [lblTitle.topAnchor constraintEqualToAnchor:btn.topAnchor constant:10],
                [lblTitle.trailingAnchor constraintEqualToAnchor:imgIcon.leadingAnchor constant:-10]
            ]];
            // -------- 副标题（可多行） --------
            UILabel *lblSubtitle = [UILabel new];
            lblSubtitle.translatesAutoresizingMaskIntoConstraints = NO;
            lblSubtitle.numberOfLines = 0;
            NSString *strSubtitle = @[@"Subscriptions are managed through your Apple ID.",@"Questions? Contact us via form or email"][i];
            lblSubtitle.text = NSLocalizedString(strSubtitle, @"");
            lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
            lblSubtitle.textColor = [self colorWithHexString:@"#A3A3D0" alpha:1];
            [btn addSubview:lblSubtitle];
         
            [NSLayoutConstraint activateConstraints:@[
                [lblSubtitle.leadingAnchor constraintEqualToAnchor:btn.leadingAnchor constant:10],
                [lblSubtitle.topAnchor constraintEqualToAnchor:lblTitle.bottomAnchor constant:6],
                [lblSubtitle.trailingAnchor constraintEqualToAnchor:btn.trailingAnchor constant:-10],
                [lblSubtitle.bottomAnchor constraintEqualToAnchor:btn.bottomAnchor constant:-10], // ★★★ 自动撑高 btn
            ]];
     
        }
        [_helpCnView layoutIfNeeded];
        
        //UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, self.btnHelp.frame.origin.y, 15, self.btnHelp.frame.size.height)];
        //view.backgroundColor = [UIColor orangeColor];
        //[_helpCnView addSubview:view];
        _helpCnView.frame = CGRectMake(0, self.exclusiveView.frame.size.height + 20, SCREEN_WIDTH, self.btnHelp.frame.origin.y + self.btnHelp.frame.size.height + 12 - 7);
        //_helpCnView.backgroundColor = [UIColor yellowColor];
        
    }
    return _helpCnView;
}
- (UIView *)helpEnView {
    if(!_helpEnView){
        _helpEnView = [UIView new];
        _helpEnView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 323);
        
        [self setupUI1];
    }
    return _helpEnView;
}
- (void)setupUI1 {
  
    UILabel *label2 = [UILabel new];
    UILabel *label3 = [UILabel new];
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeSystem];
    UILabel *label4 = [UILabel new];
    NSArray *views = @[label2, label3, button1, button2, label4];

    self.btnSubscriptions = button1;
    self.btnHelp = button2;
    
    for (UIView *v in views) {
        v.translatesAutoresizingMaskIntoConstraints = NO;
        [self.helpEnView addSubview:v];
        
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *lab = (UILabel *)v;
            lab.numberOfLines = 0;
            lab.lineBreakMode = NSLineBreakByWordWrapping;
        }
    }
 
   
    label2.font = [UIFont fontWithName:FONT_NAME_Medium size:16];
    label2.textColor = [self colorWithHexString:@"#DBDBF2" alpha:1];
    label3.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    label3.textColor = [self colorWithHexString:@"#DBDBF2" alpha:1];
    
    button1.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    [button1 setTitleColor:[self colorWithHexString:@"#B0FFFC" alpha:1] forState:UIControlStateNormal];
    button2.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    [button2 setTitleColor:[self colorWithHexString:@"#B0FFFC" alpha:1] forState:UIControlStateNormal];
    
    label4.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    label4.textColor = [self colorWithHexString:@"#9DABC2" alpha:1];
    
    // 为按钮设置换行 + 左对齐
    button1.titleLabel.numberOfLines = 0;
    button1.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button1.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    button2.titleLabel.numberOfLines = 0;
    button2.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    button2.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    // 给按钮设置下划线文字
    [button1 setAttributedTitle:
     [self underline:NSLocalizedString(@"Manage via Apple ID",@"")] forState:UIControlStateNormal];

    [button2 setAttributedTitle:
     [self underline:NSLocalizedString(@"Customer Support",@"")] forState:UIControlStateNormal];

    // Label 示例文本
   
    label2.text = NSLocalizedString(@"Manage Subscription",@"");
    label3.text = NSLocalizedString(@"Subscriptions are managed through your Apple ID.",@"");
    label4.text = NSLocalizedString(@"Payments and renewals are handled by Apple",@"");

    UIView *tempView = self.helpEnView;
    [NSLayoutConstraint activateConstraints:@[
    
  
        // label2: 16
        [label2.topAnchor constraintEqualToAnchor:tempView.topAnchor constant:81],
        [label2.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:20],
        [label2.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-20],

        // label3: 6
        [label3.topAnchor constraintEqualToAnchor:label2.bottomAnchor constant:6],
        [label3.leadingAnchor constraintEqualToAnchor:label2.leadingAnchor],
        [label3.trailingAnchor constraintEqualToAnchor:label2.trailingAnchor],

        // button1: 16
        [button1.topAnchor constraintEqualToAnchor:label3.bottomAnchor constant:16],
        [button1.leadingAnchor constraintEqualToAnchor:label2.leadingAnchor],
        [button1.trailingAnchor constraintEqualToAnchor:label2.trailingAnchor],

        // button2: 16
        [button2.topAnchor constraintEqualToAnchor:button1.bottomAnchor constant:16],
        [button2.leadingAnchor constraintEqualToAnchor:label2.leadingAnchor],
        [button2.trailingAnchor constraintEqualToAnchor:label2.trailingAnchor],

        // label4: 60
        [label4.topAnchor constraintEqualToAnchor:button2.bottomAnchor constant:60],
        [label4.leadingAnchor constraintEqualToAnchor:label2.leadingAnchor],
        [label4.trailingAnchor constraintEqualToAnchor:label2.trailingAnchor],
    ]];
    
    [self.helpEnView layoutIfNeeded];
    CGFloat maxWidth = SCREEN_WIDTH - 20*2; // 左右间距
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);

    // 计算副标题高度
    CGSize subtitleSize = [label4 sizeThatFits:maxSize];
    CGFloat subtitleHeight = subtitleSize.height;

    UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(20, label4.frame.origin.y - 30, SCREEN_WIDTH-40, 1)];
    lineView.backgroundColor = [self colorWithHexString:@"#0F2254" alpha:1];
    [tempView addSubview:lineView];
    
    // 计算副标题 y 轴
    //CGFloat subtitleY = CGRectGetMaxY(label4.frame); // 10 是你设置的间距
    self.helpEnView.frame = CGRectMake(0, self.exclusiveView.frame.size.height + 20, SCREEN_WIDTH, label4.frame.origin.y + subtitleHeight + 5);
}
// 下划线方法
- (NSAttributedString *)underline:(NSString *)text {
    NSMutableAttributedString *attr =
        [[NSMutableAttributedString alloc] initWithString:text];

    [attr addAttribute:NSUnderlineStyleAttributeName
                 value:@(NSUnderlineStyleSingle)
                 range:NSMakeRange(0, text.length)];
    return attr;
}

- (UIView *)exclusiveView {
    if(!_exclusiveView){
        _exclusiveView = [UIView new];
        _exclusiveView.backgroundColor = [self colorWithHexString:@"#223387" alpha:1];
        _exclusiveView.layer.cornerRadius = 30;//圆角
        _exclusiveView.layer.masksToBounds = YES;
        
        NSDictionary *dic0 = @{@"icon":@"type_colours_0",@"title":@"Exclusive Content",@"subtitle":@"Pinyin, characters, and stories in one place"};
        NSDictionary *dic1 = @{@"icon":@"type_colours_1",@"title":@"Guided Skill Practice",@"subtitle":@"Practice across listening, speaking, reading & writing."};
        NSDictionary *dic2 = @{@"icon":@"type_colours_2",@"title":@"Progress Tracking",@"subtitle":@"See completed lessons and current progress"};
        NSDictionary *dic3 = @{@"icon":@"type_colours_3",@"title":@"Premium Access",@"subtitle":@"Full stories and advanced tests, updated regularly"};
        NSArray *dataArray = @[dic0,dic1,dic2,dic3];
        
        NSString *longestText1 = @""; // 保存最长的字符串
        for (int i = 0; i <dataArray.count; i++) {
            NSString *str = dataArray[i][@"subtitle"];
            NSString *text = NSLocalizedString(str,@"");
            if (text.length > longestText1.length) {
                longestText1 = text;
            }
        }
        UIFont *font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        CGFloat maxWidth = (SCREEN_WIDTH-55)/2 - 22; // box 宽度 - 左右 padding
        CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
        CGRect rect = [longestText1 boundingRectWithSize:maxSize
                                     options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName: font}
                                     context:nil];
        CGFloat detailHeight = ceil(rect.size.height);
        
        UIView *parent = _exclusiveView;             // 1. 顶部标题
        GradientLabel *titleLabel = [[GradientLabel alloc] init];
        titleLabel.text = NSLocalizedString(@"Premium Benefits",@"");
        titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [parent addSubview:titleLabel];
        [titleLabel setGradientColors:@[
            [self colorWithHexString:@"#4DECFF" alpha:1], //
            [self colorWithHexString:@"#CDF5FF" alpha:1], // CDF5FF
            [self colorWithHexString:@"#FEC9FF" alpha:1]  // FEC9FF
        ] locations:nil];

        
        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.topAnchor constraintEqualToAnchor:parent.topAnchor constant:25],
            [titleLabel.centerXAnchor constraintEqualToAnchor:parent.centerXAnchor]
        ]];
        int tempHgight = 150;
        if((110 + detailHeight) > 150){
            tempHgight = 110 + detailHeight;
        }
    
        _exclusiveView.frame = CGRectMake(0, 20, SCREEN_WIDTH, 113 + tempHgight * 2);
//==========================================================================================
            // 2. 创建 4 个圆角 View
        UIImageView *(^makeBox)(void) = ^UIImageView *{
            UIImageView *v = [[UIImageView alloc] init];
            //v.backgroundColor = [self colorWithHexString:@"#0C0B4D" alpha:1];
            v.image = [UIImage imageNamed:@"dark_blue_view"];
            //v.layer.cornerRadius = 20;
            v.translatesAutoresizingMaskIntoConstraints = NO;
            [v.widthAnchor constraintEqualToConstant:(SCREEN_WIDTH-55)/2].active = YES;
            [v.heightAnchor constraintEqualToConstant:tempHgight].active = YES;
            //[v.heightAnchor constraintGreaterThanOrEqualToConstant:150].active = YES;
            return v;
        };
   
        UIImageView *v1 = makeBox();
        UIImageView *v2 = makeBox();
        UIImageView *v3 = makeBox();
        UIImageView *v4 = makeBox();

        [self setupBoxLayout:v1 dataDic:dataArray[0]];
        [self setupBoxLayout:v2 dataDic:dataArray[1]];
        [self setupBoxLayout:v3 dataDic:dataArray[2]];
        [self setupBoxLayout:v4 dataDic:dataArray[3]];

        // 3. 上面一行 Stack
        UIStackView *row1 = [[UIStackView alloc] initWithArrangedSubviews:@[v1, v2]];
        row1.axis = UILayoutConstraintAxisHorizontal;
        row1.spacing = 15;
        row1.distribution = UIStackViewDistributionEqualSpacing;
        row1.alignment = UIStackViewAlignmentFill;
        row1.translatesAutoresizingMaskIntoConstraints = NO;

        // 4. 下面一行 Stack
        UIStackView *row2 = [[UIStackView alloc] initWithArrangedSubviews:@[v3, v4]];
        row2.axis = UILayoutConstraintAxisHorizontal;
        row2.spacing = 15;
        row2.distribution = UIStackViewDistributionEqualSpacing;
        row2.alignment = UIStackViewAlignmentFill;
        row2.translatesAutoresizingMaskIntoConstraints = NO;

        // 5. 两行竖排 Stack（整体 2×2）
        UIStackView *grid = [[UIStackView alloc] initWithArrangedSubviews:@[row1, row2]];
        grid.axis = UILayoutConstraintAxisVertical;
        grid.spacing = 15;
        grid.alignment = UIStackViewAlignmentCenter;  // 水平居中
        grid.translatesAutoresizingMaskIntoConstraints = NO;
        [parent addSubview:grid];
        [NSLayoutConstraint activateConstraints:@[
            [grid.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:20],
            [grid.centerXAnchor constraintEqualToAnchor:parent.centerXAnchor]
        ]];
    }
    return _exclusiveView;
}
- (void)setupBoxLayout:(UIView *)box dataDic:(NSDictionary *)dic {
    box.clipsToBounds = YES;
    // 1. 图标
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:dic[@"icon"]]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [box addSubview:icon];

    [NSLayoutConstraint activateConstraints:@[
        [icon.topAnchor constraintEqualToAnchor:box.topAnchor constant:15],
        [icon.leadingAnchor constraintEqualToAnchor:box.leadingAnchor constant:10],
        [icon.widthAnchor constraintEqualToConstant:22],
        [icon.heightAnchor constraintEqualToConstant:22]
    ]];
    
    // 2. 标题（可换行）
    GradientLabel *title = [[GradientLabel alloc] init];
    NSString *strTitle = dic[@"title"];
    title.text = NSLocalizedString(strTitle,@"");
    title.textColor = [self colorWithHexString:@"#4DECFF" alpha:1];
    title.font = [UIFont fontWithName:FONT_NAME_Semibold size:14];
    title.numberOfLines = 0;
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [title setGradientColors:@[
        [self colorWithHexString:@"#4DECFF" alpha:1], //
        [self colorWithHexString:@"#CDF5FF" alpha:1], // CDF5FF
        [self colorWithHexString:@"#FEC9FF" alpha:1]  // FEC9FF
    ] locations:nil];
    [box addSubview:title];

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:11],
        [title.leadingAnchor constraintEqualToAnchor:box.leadingAnchor constant:12],
        [title.trailingAnchor constraintEqualToAnchor:box.trailingAnchor constant:-10]
    ]];


    // 3. 内容文字（可换行）
    UILabel *detail = [[UILabel alloc] init];
    NSString *strSubtitle = dic[@"subtitle"];
    detail.text = NSLocalizedString(strSubtitle,@"");
    detail.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    detail.numberOfLines = 0;
    detail.textColor = [self colorWithHexString:@"#B0B0E0" alpha:1];
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    [box addSubview:detail];

    [NSLayoutConstraint activateConstraints:@[
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:12],
        [detail.leadingAnchor constraintEqualToAnchor:box.leadingAnchor constant:12],
        [detail.trailingAnchor constraintEqualToAnchor:box.trailingAnchor constant:-10],
        //[detail.bottomAnchor constraintLessThanOrEqualToAnchor:box.bottomAnchor constant:-12]
    ]];
    
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
