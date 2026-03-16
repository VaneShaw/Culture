//
//  UnlockedView.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/3.
//

#import "UnlockedView.h"
@interface UnlockedView()
@property (nonatomic, strong) UIView *bkView;
@property (nonatomic, strong) UIImageView *contentView;
@property (nonatomic, strong) UILabel *lblMessage;
@property (nonatomic, strong) NSString *trial_time;
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation UnlockedView


- (instancetype)initWithFrame:(CGRect)frame showViewTitle:(NSString *)title dataArray:(NSArray *)dataArray callBack:(void(^)(NSInteger index))callBack {
    frame = [UIScreen mainScreen].bounds;
    if (self = [super initWithFrame:frame]) {
        __weak typeof(self) weakSelf = self;
        [self setSelectedTypeIndex:^(NSInteger index) {
            if (callBack) {
                callBack(index);
            }
            [weakSelf hidden];
        }];
        
        _bkView = [[UIView alloc] initWithFrame:frame];
        [self addSubview:_bkView];
        
        //UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        //[_bkView addGestureRecognizer:tap];
        //[tap addTarget:self action:@selector(tapAction)];
        [self addContentView:title dataArray:dataArray];
        
    }
    return self;
}
- (void)tapAction {
    [self hidden];
}
+ (void)showViewTitle:(NSString *)title dataArray:(NSArray *)dataArray callBack:(void(^)(NSInteger index))callBack
{
    UnlockedView *pleasefoView = [[UnlockedView alloc] initWithFrame:CGRectZero showViewTitle:title dataArray:dataArray callBack:callBack];
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                window = scene.windows.firstObject;
                break;
            }
        }
    } else {
        window = [UIApplication sharedApplication].keyWindow;
    }
    if (window) {
        [window addSubview:pleasefoView];
    }
    [UIView animateWithDuration:0.25 animations:^{
        pleasefoView.bkView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
        pleasefoView.contentView.alpha = 1;
    }];
}
- (void)btnCloseAction:(UIButton *)sender {
    [self hidden];
}
- (void)addContentView:(NSString *)title dataArray:(NSArray *)dataArray {

    if(dataArray.count > 0){
        self.trial_time = dataArray[0];
    }
    // -----------------------------
    // 大图
    // -----------------------------
    self.contentView = [[UIImageView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.userInteractionEnabled = YES;
    NSString *image_blue = [NSString stringWithFormat:@"main_image_blue_3"];
    self.contentView.image = [UIImage imageNamed:image_blue]; // 替换
    self.contentView.contentMode = UIViewContentModeScaleAspectFill;
    self.contentView.clipsToBounds = YES;
    [self addSubview:self.contentView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.widthAnchor constraintEqualToConstant:307],
        [self.contentView.heightAnchor constraintEqualToConstant:289],
        [self.contentView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0],
        [self.contentView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-28]
    ]];
    
    // -----------------------------
    // 大图底部图标
    // -----------------------------

    UIView *tempView = [[UIView alloc] init];
    tempView.translatesAutoresizingMaskIntoConstraints = NO;
    tempView.userInteractionEnabled = YES;
    [self.contentView addSubview:tempView];
    [NSLayoutConstraint activateConstraints:@[
        [tempView.widthAnchor constraintEqualToConstant:307],
        [tempView.heightAnchor constraintEqualToConstant:289],
        [tempView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0],
        [tempView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor]
    ]];
    //tempView.backgroundColor = [UIColor orangeColor];
    // -----------------------------
    // 关闭按钮
    // -----------------------------
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton setImage:[UIImage imageNamed:@"close_white_1"] forState:UIControlStateNormal];
    //[closeButton addTarget:self action:@selector(hidden) forControlEvents:UIControlEventTouchUpInside];
    [closeButton addTarget:self action:@selector(btnTypeAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:closeButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [closeButton.topAnchor constraintEqualToAnchor:tempView.bottomAnchor constant:15],
        [closeButton.centerXAnchor constraintEqualToAnchor:tempView.centerXAnchor],
        [closeButton.widthAnchor constraintEqualToConstant:36],
        [closeButton.heightAnchor constraintEqualToConstant:36]
    ]];
    
    // -----------------------------
    // 大图上方两个小图 + 两个 UILabel + 一个按钮
    // -----------------------------

    GradientLabel *titleLabel = [[GradientLabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = NSLocalizedString(@"Unlocked!",@"");
    titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:28];
    [tempView addSubview:titleLabel];
    [titleLabel setGradientColors:@[
        [self colorWithHexString:@"#4DECFF" alpha:1], //
        [self colorWithHexString:@"#CDF5FF" alpha:1], // CDF5FF
        [self colorWithHexString:@"#FEC9FF" alpha:1]  // FEC9FF
    ] locations:nil];


    int space1 = 10;
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:tempView.topAnchor constant:89],
        [titleLabel.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:space1],
        [titleLabel.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-space1]
    ]];
    

    //两种状态    7 天免费试用已激活
    //会员特权已开启 全部内容无限畅享
    UILabel *lblMessage  = [[UILabel alloc] init];
    lblMessage.translatesAutoresizingMaskIntoConstraints = NO;
    lblMessage.textAlignment = NSTextAlignmentCenter;
    if(title.intValue == 1){
        // NSLocalizedString(@"Your 7-day free trial is now active.", @"");
        NSString *type = self.trial_time;
        NSString *message = [NSString stringWithFormat:@"%@ 内测特权已激活,快去开启你的畅读之旅吧。",type];
        if(IS_OVERSEAS_VERSION){
            //message = [NSString stringWithFormat: @"Your %@ early access is active. Enjoy your journey!",type.lowercaseString];//xx月份改小写
            
            message = [NSString stringWithFormat: @"Your %@ of early accessstarts now. Enjoy the journey!",type.lowercaseString];//xx月份改小写
            
        }
        lblMessage.text = message;
    } else {
        lblMessage.text = NSLocalizedString(@"Premium activated Unlimited access", @"");
    }

    lblMessage.font = [UIFont fontWithName:FONT_NAME_Medium size:18];
    lblMessage.textColor = [self colorWithHexString:@"#DBDBF2" alpha:1];
    lblMessage.numberOfLines = 0;
    [self addSubview:lblMessage];
 
    [NSLayoutConstraint activateConstraints:@[
        [lblMessage.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:18],
        [lblMessage.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:space1],
        [lblMessage.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-space1]
    ]];

    NSString *title0 = NSLocalizedString(@"Start Now", @"");
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title0 forState:UIControlStateNormal];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
    [btn setTitleColor:[self colorWithHexString:@"#1D1F2E" alpha:1] forState:UIControlStateNormal];
    btn.layer.cornerRadius = 20;//圆角
    btn.layer.masksToBounds = YES;
    btn.tag = 100;
    [btn addTarget:self action:@selector(btnTypeAction:) forControlEvents:UIControlEventTouchUpInside];
    [btn setBackgroundImage:[UIImage imageNamed:@"button_colours_0"] forState:UIControlStateNormal];
    [tempView addSubview:btn];
    //-31
    [NSLayoutConstraint activateConstraints:@[
        [btn.bottomAnchor constraintEqualToAnchor:tempView.bottomAnchor constant:-28],
        [btn.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:28],
        [btn.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-28],
        [btn.heightAnchor constraintEqualToConstant:44]
    ]];
}
- (void)btnTypeAction:(UIButton *)sender {
    self.selectedTypeIndex(1);
}
- (void)hidden{
    __weak typeof(self) weakSelf=self;
    [UIView animateWithDuration:0.25 animations:^{
        //weakSelf.bkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0];
        weakSelf.contentView.alpha = 0;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}
@end

