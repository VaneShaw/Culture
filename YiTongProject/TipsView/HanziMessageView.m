//
//  HanziMessageView.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/27.
//

#import "HanziMessageView.h"


@interface HanziMessageView()
@property (nonatomic, strong) UIView *bkView;
@property (nonatomic, strong) UIImageView *imgCode;
@property (nonatomic, strong) UIImageView *contentView;
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation HanziMessageView

- (instancetype)initWithFrame:(CGRect)frame showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack {
    frame = [UIScreen mainScreen].bounds;
    if (self = [super initWithFrame:frame]) {
        __weak typeof(self) weakSelf = self;
        [self setSelectedTypeIndex:^(NSInteger index) {
            if (callBack) {
                callBack(index);
            }
            //[weakSelf hidden];
        }];
      
        _bkView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 70 - IPHONE_X * 25)];
        //_bkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        [self addSubview:_bkView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [_bkView addGestureRecognizer:tap];
        [tap addTarget:self action:@selector(tapAction)];
        [self addContentView:title buttonArrayTitle:titlArray];
        
        UIButton *btnReset = [UIButton buttonWithType:UIButtonTypeCustom];
        btnReset.frame = CGRectMake(0,SCREEN_HEIGHT - 70 - IPHONE_X * 25, 65, 70 + IPHONE_X * 25);
        [btnReset addTarget:self action:@selector(btnResetAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btnReset];
    }
    return self;
}
- (void)tapAction {
    [self hidden];
}
- (void)btnResetAction:(UIButton *)sender {
    if(self.selectedTypeIndex){
        self.selectedTypeIndex(101);
    }
}
+ (void)showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack
{
    HanziMessageView *pleasefoView = [[HanziMessageView alloc] initWithFrame:CGRectZero showViewTitle:title buttonArrayTitle:titlArray callBack:callBack];
     UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    [window addSubview:pleasefoView];
    
    [UIView animateWithDuration:0.25 animations:^{
        //pleasefoView.bkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        pleasefoView.bkView.backgroundColor = [UIColor clearColor];
        pleasefoView.contentView.alpha = 1;
    }];
}
- (void)addContentView:(NSString *)title buttonArrayTitle:(NSArray *)titleArray {

    int width = SCREEN_WIDTH - 2 * (85 -  10 * IS_Formal_Screen);
    int height = 100;
    _contentView = [[UIImageView alloc]init];
    _contentView.backgroundColor = [self colorWithHexString:@"#1F1F39" alpha:1];
    _contentView.layer.cornerRadius = 8;
    _contentView.layer.masksToBounds = YES;
    [self addSubview:_contentView];

    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, width - 20, height - 30)];
    lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
    lblTitle.textColor = [self colorWithHexString:@"#FFFFFF" alpha:1];
    lblTitle.text = title;
    lblTitle.numberOfLines = 0;
    [_contentView addSubview:lblTitle];
    
    CGSize labelSize = [lblTitle sizeThatFits:CGSizeMake(width - 20,MAXFLOAT)];
    height = labelSize.height + 15;
    lblTitle.frame = CGRectMake(10, 10, width - 20, height);
    _contentView.frame = CGRectMake((SCREEN_WIDTH-width)/2, (SCREEN_HEIGHT - height)/2 - 30 - 30, width, height + 30);
}
- (void)hidden{
    __weak typeof(self) weakSelf=self;
    [UIView animateWithDuration:0.25 animations:^{
        weakSelf.contentView.alpha = 0;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}
@end

