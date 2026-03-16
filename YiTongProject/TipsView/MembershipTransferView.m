//
//  MembershipTransferView.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/9.
//

#import "MembershipTransferView.h"

@interface MembershipTransferView()
@property (nonatomic, strong) UIView *bkView;
@property (nonatomic, strong) UIImageView *imgCode;
@property (nonatomic, strong) UIImageView *contentView;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation MembershipTransferView

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
    MembershipTransferView *pleasefoView = [[MembershipTransferView alloc] initWithFrame:CGRectZero showViewTitle:title buttonArrayTitle:titlArray callBack:callBack];
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
    _contentView.image = [UIImage imageNamed:@"bg_blue_02.png"];
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
    lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:20];
    lblTitle.textColor = BLACK_COLOR_1F;
    lblTitle.tag = 505;
    lblTitle.text = NSLocalizedString(titleArray[0], @"");
    [_contentView addSubview:lblTitle];

    int temp = 10;
    UILabel *lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(interval, 75, width -  interval - temp, 60)];
    lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Medium size:14];
    lblSubtitle.textColor = BLACK_COLOR_1F;
    lblSubtitle.numberOfLines = 0;
    lblSubtitle.text = NSLocalizedString(titleArray[1], @"");
    [_contentView addSubview:lblSubtitle];
    
    CGSize labelSize = [lblSubtitle sizeThatFits:CGSizeMake(width - 2 * interval,MAXFLOAT)];
    lblSubtitle.frame = CGRectMake(interval, 75, width - 2 * interval, labelSize.height + 5);
    
    int y = 75 + labelSize.height + 5 + 12;
    UILabel *lblContent = [[UILabel alloc]initWithFrame:CGRectMake(interval, y, width -  interval - temp, 60 )];
    lblContent.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    lblContent.textColor = [self colorWithHexString:@"#63637D" alpha:1];
    lblContent.numberOfLines = 0;
    lblContent.text = NSLocalizedString(titleArray[2], @"");
    [_contentView addSubview:lblContent];
    
    CGSize labelSize2 = [lblContent sizeThatFits:CGSizeMake(width - 56,MAXFLOAT)];
    lblContent.frame = CGRectMake(interval, y, width - interval - temp, labelSize2.height + 10);
    _contentView.frame = CGRectMake((SCREEN_WIDTH - width)/2, (SCREEN_HEIGHT - height)/2 - 25, width, y + labelSize2.height + 10 + 102);
    
    NSString *title2 = NSLocalizedString(titleArray[3],@"");
    NSString *title3 = NSLocalizedString(titleArray[4],@"");
    int btnWidth = (width - interval * 3)/2;
    for (int i = 0; i < 2; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.frame = CGRectMake(interval + (btnWidth + interval) * i, _contentView.frame.size.height - 44 - interval, btnWidth, 44);
        [btn setTitle:@[title2,title3][i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:14];
        btn.backgroundColor = [self colorWithHexString:@[@"#EFEFEF",@"#4C9BEF"][i] alpha:1];
        btn.layer.cornerRadius = 22;//圆角
        btn.layer.masksToBounds = YES;
        btn.tag = 1000 + i;
        [btn addTarget:self action:@selector(btn123Action:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:btn];
        if(i==0){
            btn.tintColor = [self colorWithHexString:@"#63637D" alpha:1];
        } else {
            btn.tintColor = [UIColor whiteColor];
        }
    }
}

- (void)btn123Action:(UIButton *)sender {

    if(sender.tag==1000){
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
