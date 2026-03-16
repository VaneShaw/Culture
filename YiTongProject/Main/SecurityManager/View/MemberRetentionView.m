//
//  MemberRetentionView.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/4.
//

#import "MemberRetentionView.h"

@interface MemberRetentionView()
@property (nonatomic, strong) UIView *bkView;
@property (nonatomic, strong) UIImageView *mainImageView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *lblTitle;
@property (nonatomic, strong) UILabel *lblMessage;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) NSString *vip_status;
@property (nonatomic, strong) NSString *trial_time;
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation MemberRetentionView

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
    MemberRetentionView *pleasefoView = [[MemberRetentionView alloc] initWithFrame:CGRectZero showViewTitle:title dataArray:dataArray callBack:callBack];
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
    self.vip_status = title;
    if(dataArray.count>0){
        self.trial_time = dataArray[0];
    }
    // -----------------------------
    // 大图
    // -----------------------------
    self.mainImageView = [[UIImageView alloc] init];
    self.mainImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mainImageView.userInteractionEnabled = YES;
    NSString *image_blue = [NSString stringWithFormat:@"main_image_blue_%d",is_Engin];
    self.mainImageView.image = [UIImage imageNamed:image_blue]; // 替换
    self.mainImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.mainImageView.clipsToBounds = YES;
    [self addSubview:self.mainImageView];
    
    int interval = 0;
    [NSLayoutConstraint activateConstraints:@[
        [self.mainImageView.widthAnchor constraintEqualToConstant:325],
        [self.mainImageView.heightAnchor constraintEqualToConstant:330],
        [self.mainImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor constant:12],
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
        [tempView.widthAnchor constraintEqualToConstant:305],
        [tempView.heightAnchor constraintEqualToConstant:250 + interval],
        [tempView.topAnchor constraintEqualToAnchor:self.mainImageView.topAnchor constant:78],
        [tempView.leadingAnchor constraintEqualToAnchor:self.mainImageView.leadingAnchor]
    ]];

    // -----------------------------
    // 关闭按钮
    // -----------------------------
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.closeButton setImage:[UIImage imageNamed:@"close_white_1"] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(hidden) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.closeButton.topAnchor constraintEqualToAnchor:tempView.bottomAnchor constant:20],
        [self.closeButton.centerXAnchor constraintEqualToAnchor:tempView.centerXAnchor],
        [self.closeButton.widthAnchor constraintEqualToConstant:36],
        [self.closeButton.heightAnchor constraintEqualToConstant:36]
    ]];
    
    // -----------------------------
    // 大图上方两个小图 + 两个 UILabel + 一个按钮
    // -----------------------------

    // 第一个 label
    self.lblTitle = [[UILabel alloc] init];
    self.lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
    self.lblTitle.textAlignment = NSTextAlignmentCenter;
    self.lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:19];//22
    //self.lblTitle.text = NSLocalizedString(@"Your Premium Trial Is Ready", @"");
    self.lblTitle.textColor = BLACK_COLOR_1F;
    self.lblTitle.numberOfLines = 0;
    [self addSubview:self.lblTitle];
    
    int space1 = 10;
    [NSLayoutConstraint activateConstraints:@[
        [self.lblTitle.topAnchor constraintEqualToAnchor:tempView.topAnchor constant:64],
        [self.lblTitle.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:space1],
        [self.lblTitle.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-space1]
    ]];
    
    // 第二个 label
    self.lblMessage = [[UILabel alloc] init];
    self.lblMessage.translatesAutoresizingMaskIntoConstraints = NO;
    self.lblMessage.textAlignment = NSTextAlignmentCenter;
    //self.lblMessage.text = NSLocalizedString(@"Unlock all stories and lessons when you start now.", @"");
    self.lblMessage.font = [UIFont fontWithName:FONT_NAME_Regular size:16];//18
    self.lblMessage.textColor = BLACK_COLOR_1F;
    self.lblMessage.numberOfLines = 0;
    [self addSubview:self.lblMessage];
    
    NSString *type = self.trial_time;//2个月
    NSString *strTitle = [NSString stringWithFormat:@"%@内测特权即将失效",type];
    NSString *strMessage = [NSString stringWithFormat:@"立即免费开启%@畅学，试用期不扣费，随时取消。",type];
    if(IS_OVERSEAS_VERSION){
    
        strMessage = [NSString stringWithFormat:@"Unlock %@ of full access \nfor $0 Cancel anytime risk-free.",type];
        strTitle = [NSString stringWithFormat:@"Don't Miss Your %@ Trial",type];
    }
    self.lblTitle.text = strTitle;
    self.lblMessage.text = strMessage;
    
    [NSLayoutConstraint activateConstraints:@[
        [self.lblMessage.topAnchor constraintEqualToAnchor:self.lblTitle.bottomAnchor constant:10-interval],
        [self.lblMessage.leadingAnchor constraintEqualToAnchor:tempView.leadingAnchor constant:space1],
        [self.lblMessage.trailingAnchor constraintEqualToAnchor:tempView.trailingAnchor constant:-space1]
    ]];
    //"Leave Anyway" = "忍痛离开";
    //"Continue" = "继续开通";
    NSString *title0 = NSLocalizedString(@"Leave Anyway", @"");
    
    NSString *title1 = NSLocalizedString(@"Continue", @"");
    if(self.vip_status.intValue == 1){
        title1 = NSLocalizedString(@"Continue11", @"");
    }
    
    int btnWidth = 133;
    int space = (305 - 266)/3;
    for (int i = 0; i < 2; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(space + (space + btnWidth) * i, 180 + interval *2, btnWidth, 40);
        [btn setTitle:@[title0,title1][i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
        [btn setTitleColor:[self colorWithHexString:@[@"#63637D",@"#BDE4FF"][i] alpha:1] forState:UIControlStateNormal];
        btn.layer.cornerRadius = 20;//圆角
        btn.layer.masksToBounds = YES;
        btn.tag = 2000 + i;
        [btn addTarget:self action:@selector(btnTypeAction:) forControlEvents:UIControlEventTouchUpInside];
        [tempView addSubview:btn];
        
        if(i==0){
            btn.layer.borderWidth = 1;  //边框
            btn.layer.borderColor = [self colorWithHexString:@"#63637D" alpha:1].CGColor;
        } else {
            [btn setBackgroundImage:[UIImage imageNamed:@"buttton_dark_0"] forState:UIControlStateNormal];
        }
    }
}
- (void)btnTypeAction:(UIButton *)sender {
    if(sender.tag == 2000){
        [self hidden];
    } else {
        self.selectedTypeIndex(sender.tag);
    }
   
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


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


