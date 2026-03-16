//
//  AccountDeletionView.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/26.
//

#import "AccountDeletionView.h"


@interface AccountDeletionView()
@property (nonatomic, strong) UIView *bkView;
@property (nonatomic, strong) UIImageView *imgCode;
@property (nonatomic, strong) UIImageView *contentView;
@property (nonatomic, assign) BOOL isQuitNow;
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation AccountDeletionView
//无用可删

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
        self.isQuitNow = title.boolValue;
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
    AccountDeletionView *pleasefoView = [[AccountDeletionView alloc] initWithFrame:CGRectZero showViewTitle:title buttonArrayTitle:titlArray callBack:callBack];
    UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    [window addSubview:pleasefoView];
   
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

    int width = SCREEN_WIDTH - 70;
    int height = 250;
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
    
    //[self setChangColorWithView:_contentView andColorStart:[self colorWithHexString:@"#D0E6FF" alpha:1] andEndColor:[self colorWithHexString:@"#FFFFFF" alpha:1]];
    
    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(28, 28, width - 56, 23)];
    lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
    lblTitle.textColor = BLACK_COLOR_1F;
    lblTitle.text = @"Account Deletion";
    [_contentView addSubview:lblTitle];

    UILabel *lblTitle2 = [[UILabel alloc]initWithFrame:CGRectMake(28, 67, width - 56, 70)];
    lblTitle2.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
    lblTitle2.textColor = [self colorWithHexString:@"#63637D" alpha:1];
    lblTitle2.numberOfLines = 0;
    lblTitle2.text = @"Delete your YTong account? This action is permanent and cannot be undone.";
    [_contentView addSubview:lblTitle2];

    //"Yes, resume"     继续测试
    //“No, start over"  从第一题开始
    
    //Exit Anyway退回上一页   Keep Going回到当前

    NSArray *array1 = @[@"Cancel",@"Delete Account"];      //左上角返回

    //array1 = @[@"从第一题开始",@"继续测试"];
    //array2 = @[@"退回上一页",@"回到当前"];
    
    //int spacing = width - 240 - 56;
    int btnWidth = (width - 28 * 3)/2;
    for (int i = 0; i < 2; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.frame = CGRectMake(28 + (btnWidth + 28) * i, _contentView.frame.size.height - 44 - 28, btnWidth, 44);
        [btn setTitle:NSLocalizedString(array1[i],@"") forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:14];
        btn.backgroundColor = [self colorWithHexString:@[@"#EFEFEF",@"#4C9BEF"][i] alpha:1];
        btn.layer.cornerRadius = 22;//圆角
        btn.layer.masksToBounds = YES;
        btn.tag = 100 + i;
        [btn addTarget:self action:@selector(btn123Action:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:btn];
        if(i==0){
            btn.tintColor = BLACK_COLOR_1F;
        } else {
            btn.tintColor = [UIColor whiteColor];
        }
    }
    
}
- (void)btn123Action:(UIButton *)sender {
    self.selectedTypeIndex(sender.tag);
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
