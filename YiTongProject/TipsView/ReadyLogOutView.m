//
//  ReadyLogOutView.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/8.
//

#import "ReadyLogOutView.h"
#import "HelpRulesViewController.h"
@interface ReadyLogOutView()
@property (nonatomic, strong) UIView *bkView;
@property (nonatomic, strong) UIImageView *imgCode;
@property (nonatomic, strong) UIImageView *contentView;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation ReadyLogOutView

- (instancetype)initWithFrame:(CGRect)frame showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack {
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
        //_bkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        [self addSubview:_bkView];
        
        //UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        //[_bkView addGestureRecognizer:tap];
        //[tap addTarget:self action:@selector(tapAction)];
        [self addContentView:title buttonArrayTitle:titlArray];
    }
    return self;
}
- (void)tapAction {
    [self hidden];
}
+ (void)showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack
{
    ReadyLogOutView *pleasefoView = [[ReadyLogOutView alloc] initWithFrame:CGRectZero showViewTitle:title buttonArrayTitle:titlArray callBack:callBack];
     UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    [window addSubview:pleasefoView];
  
    //* title.boolValue
    [UIView animateWithDuration:0.25 animations:^{
        pleasefoView.bkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        //pleasefoView.bkView.backgroundColor = [UIColor clearColor];
        pleasefoView.contentView.alpha = 1;
    }];
}
- (void)btnCloseAction:(UIButton *)sender {
    [self hidden];

}

- (void)addContentView:(NSString *)title buttonArrayTitle:(NSArray *)titleArray {
    if(titleArray.count < 4)return;
    self.title = title;
    
    int width = SCREEN_WIDTH - 70;
    int height = 241;
    _contentView = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - width)/2, (SCREEN_HEIGHT - height)/2 - 25, width, height)];
    _contentView.image = [UIImage imageNamed:@"bg_blue.png"];
    _contentView.layer.cornerRadius = 24;
    _contentView.layer.masksToBounds = YES;
    _contentView.userInteractionEnabled = YES;
    [self addSubview:_contentView];
    
    UIButton *btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
    btnClose.frame = CGRectMake(width - 12 - 30,12, 30, 30);
    [btnClose setImage:[UIImage imageNamed:@"close_gray"] forState:UIControlStateNormal];
    [btnClose addTarget:self action:@selector(btnCloseAction:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:btnClose];
    int interval = 28;
    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(interval, 28, width - 2 * interval, 23)];
    lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
    lblTitle.textColor = BLACK_COLOR_1F;
    lblTitle.tag = 505;
    lblTitle.text = NSLocalizedString(titleArray[0], @"");
    [_contentView addSubview:lblTitle];

    UILabel *lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(interval, 75, width - 2 * interval, 60)];
    lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
    lblSubtitle.textColor = [self colorWithHexString:@"#63637D" alpha:1];
    lblSubtitle.numberOfLines = 0;
    lblSubtitle.text = NSLocalizedString(titleArray[1], @"");
  
    [_contentView addSubview:lblSubtitle];
    if(self.title.intValue == 1){
        lblSubtitle.hidden = YES;
        btnClose.hidden = YES;
    } else {
        lblSubtitle.hidden = NO;
        btnClose.hidden = NO;
    }
    //title.boolValue
    CGSize labelSize = [lblSubtitle sizeThatFits:CGSizeMake(width - 56,MAXFLOAT)];
    lblSubtitle.frame = CGRectMake(interval, 75, width - 2 * interval, labelSize.height + 5);

    
    _contentView.frame = CGRectMake((SCREEN_WIDTH - width)/2, (SCREEN_HEIGHT - height)/2 - 25, width, 75 + labelSize.height + 5 + 28 + 30 + 40);

    //数组第3个 为空 左按钮隐藏
    //title 1 加入协议     11 右边按钮 点击隐藏。
    if(title.intValue == 1){
        _contentView.frame = CGRectMake((SCREEN_WIDTH - width)/2, (SCREEN_HEIGHT - height)/2 - 25, width, 75 + 25 + 28 + 30 + 40);
        [self addAgreementView];
    }

    //_contentView.frame = CGRectMake((SCREEN_WIDTH - width)/2, (SCREEN_HEIGHT - height)/2 - 25, width, 75 + labelSize.height + 5 + 72 + 40);

    BOOL isTemp = [titleArray[2] length] == 0 ? YES : NO;
    NSString *title2 = NSLocalizedString(titleArray[2],@"");
    NSString *title3 = NSLocalizedString(titleArray[3],@"");
    int btnWidth = (width - interval * 3)/2;
    for (int i = 0; i < 2; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.frame = CGRectMake(interval + (btnWidth + interval) * i, _contentView.frame.size.height - 44 - 28, btnWidth, 44);
        [btn setTitle:@[title2,title3][i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:14];
        btn.backgroundColor = [self colorWithHexString:@[@"#EFEFEF",@"#4C9BEF"][i] alpha:1];
        btn.layer.cornerRadius = 22;//圆角
        btn.layer.masksToBounds = YES;
        btn.tag = 1000 + i;
        [btn addTarget:self action:@selector(btn123Action:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:btn];
        if(i==0){
            //btn.tintColor = BLACK_COLOR_1F;
            btn.tintColor = [self colorWithHexString:@"#63637D" alpha:1];
            btn.hidden = isTemp;
        } else {
            btn.tintColor = [UIColor whiteColor];
        }
        if(isTemp){
            btn.frame = CGRectMake((width-btnWidth)/2, _contentView.frame.size.height - 44 - 28, btnWidth, 44);
        }
    }
}
- (void)addAgreementView {
    NSURL *url = [NSURL URLWithString:@""];
    AgreementConsentView *agree = [[AgreementConsentView alloc] initWithAgreementURL:url privacyURL:url];
    agree.translatesAutoresizingMaskIntoConstraints = NO;
    // 初始是否勾选
    agree.checked = NO;

    // 回调：勾选/取消
    __weak typeof(self) weakSelf = self;
    agree.onToggle = ^(BOOL checked) {
        NSLog(@"checked? [%d]", checked);
        //checked 1 选中。  0 未打勾
        // 例如：设置注册按钮 enable
        //weakSelf.btnCode.enabled = checked;
    };
    //BOOL isChecked = agree.isChecked;
    agree.onTapLinkName = ^(NSString *name) {
        if ([name isEqualToString:@"用户协议"]) {
            self.selectedTypeIndex(200);
        } else if ([name isEqualToString:@"隐私政策"]) {
            self.selectedTypeIndex(201);
        }
    };
    [self.contentView addSubview:agree];
    UILabel *lblTitle = (UILabel *)[self.contentView viewWithTag:505];
    
    [NSLayoutConstraint activateConstraints:@[
        [agree.topAnchor constraintEqualToAnchor:lblTitle.bottomAnchor constant:25],
        [agree.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:0],
        [agree.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
    ]];
    [agree hideCheckboxAndAdjustTextMargins];
}
- (void)btn123Action:(UIButton *)sender {

    if(self.title.intValue == 11){
        [self hidden];
    } else {
        self.selectedTypeIndex(sender.tag);
    }
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
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


