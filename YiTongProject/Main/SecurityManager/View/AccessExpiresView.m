//
//  AccessExpiresView.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/3.
//

#import "AccessExpiresView.h"

@interface AccessExpiresView()
@property (nonatomic, strong) UIView *bkView;

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *lblTitle;
@property (nonatomic, strong) UILabel *lblMessage;
@property (nonatomic, strong) UIImageView *mainImageView;

@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation AccessExpiresView

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
    AccessExpiresView *pleasefoView = [[AccessExpiresView alloc] initWithFrame:CGRectZero showViewTitle:title dataArray:dataArray callBack:callBack];
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
        pleasefoView.mainImageView.alpha = 1;
    }];
}
- (void)btnCloseAction:(UIButton *)sender {
    [self hidden];
}
- (void)addContentView:(NSString *)title dataArray:(NSArray *)dataArray {

  
    // -----------------------------
    // 大图
    // -----------------------------
    self.mainImageView = [[UIImageView alloc] init];
    self.mainImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mainImageView.userInteractionEnabled = YES;
    NSString *image_blue = [NSString stringWithFormat:@"main_image_blue_2"];
    self.mainImageView.image = [UIImage imageNamed:image_blue]; // 替换
    self.mainImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.mainImageView.clipsToBounds = YES;
    [self addSubview:self.mainImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.mainImageView.widthAnchor constraintEqualToConstant:307],
        [self.mainImageView.heightAnchor constraintEqualToConstant:289],
        [self.mainImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:0],
        [self.mainImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-28]
    ]];
    
    // -----------------------------
    // 大图底部图标
    // -----------------------------

    UIView *tempView = [[UIView alloc] init];
    tempView.translatesAutoresizingMaskIntoConstraints = NO;
    tempView.userInteractionEnabled = YES;
    [self.mainImageView addSubview:tempView];
    [NSLayoutConstraint activateConstraints:@[
        [tempView.widthAnchor constraintEqualToConstant:307],
        [tempView.heightAnchor constraintEqualToConstant:289],
        [tempView.topAnchor constraintEqualToAnchor:self.mainImageView.topAnchor constant:0],
        [tempView.leadingAnchor constraintEqualToAnchor:self.mainImageView.leadingAnchor]
    ]];
    //tempView.backgroundColor = [UIColor orangeColor];
    // -----------------------------
    // 关闭按钮
    // -----------------------------
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.closeButton setImage:[UIImage imageNamed:@"close_white_1"] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(hidden) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.closeButton.topAnchor constraintEqualToAnchor:tempView.bottomAnchor constant:15],
        [self.closeButton.centerXAnchor constraintEqualToAnchor:tempView.centerXAnchor],
        [self.closeButton.widthAnchor constraintEqualToConstant:36],
        [self.closeButton.heightAnchor constraintEqualToConstant:36]
    ]];

    //多种状态类型   到期1天  or   到期 7天
    self.lblTitle = [[UILabel alloc] init];
    self.lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
    self.lblTitle.textAlignment = NSTextAlignmentCenter;
    self.lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:22];
    if([title isEqualToString:@"1"]){
        self.lblTitle.text = NSLocalizedString(@"Access Expires in 1 Days", @"");
    } else {
        self.lblTitle.text = NSLocalizedString(@"Access Expires in 7 Days", @"");
    }
    self.lblTitle.textColor = BLACK_COLOR_1F;
    self.lblTitle.numberOfLines = 0;
    [self addSubview:self.lblTitle];
    
    int space1 = 10;
    [NSLayoutConstraint activateConstraints:@[
        [self.lblTitle.topAnchor constraintEqualToAnchor:tempView.topAnchor constant:92],
        [self.lblTitle.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:space1],
        [self.lblTitle.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-space1]
    ]];
    
    // 第二个 label
    self.lblMessage = [[UILabel alloc] init];
    self.lblMessage.translatesAutoresizingMaskIntoConstraints = NO;
    self.lblMessage.textAlignment = NSTextAlignmentCenter;
    self.lblMessage.text = NSLocalizedString(@"Reactivate your subscription to keep all stories and features.", @"");
    self.lblMessage.font = [UIFont fontWithName:FONT_NAME_Regular size:18];
    self.lblMessage.textColor = BLACK_COLOR_1F;
    self.lblMessage.numberOfLines = 0;
    [self addSubview:self.lblMessage];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.lblMessage.topAnchor constraintEqualToAnchor:self.lblTitle.bottomAnchor constant:17],
        [self.lblMessage.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:space1],
        [self.lblMessage.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-space1]
    ]];

    NSString *title0 = NSLocalizedString(@"Manage Subscription", @"");
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title0 forState:UIControlStateNormal];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
    [btn setTitleColor:[self colorWithHexString:@"#BDE4FF" alpha:1] forState:UIControlStateNormal];
    btn.layer.cornerRadius = 20;//圆角
    btn.layer.masksToBounds = YES;
    [btn addTarget:self action:@selector(btnTypeAction:) forControlEvents:UIControlEventTouchUpInside];
    [btn setBackgroundImage:[UIImage imageNamed:@"buttton_dark_0"] forState:UIControlStateNormal];
    [tempView addSubview:btn];
    
    [NSLayoutConstraint activateConstraints:@[
        [btn.bottomAnchor constraintEqualToAnchor:tempView.bottomAnchor constant:-31],
        [btn.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:28],
        [btn.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-28],
        [btn.heightAnchor constraintEqualToConstant:44]
    ]];
}
- (void)btnTypeAction:(UIButton *)sender {
    self.selectedTypeIndex(sender.tag);
}
- (void)hidden{
    __weak typeof(self) weakSelf=self;
    [UIView animateWithDuration:0.25 animations:^{
        //weakSelf.bkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.0];
        weakSelf.mainImageView.alpha = 0;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}
@end

