//
//  RestoreVipView.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/10.
//

#import "RestoreVipView.h"

static NSMutableArray<RestoreVipView *> *visibleViews = nil;

@interface RestoreVipView()
@property (nonatomic, strong) UIView *bkView;
@property (nonatomic, strong) UIImageView *imgCode;
@property (nonatomic, strong) UIImageView *contentView;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation RestoreVipView

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
+ (void)hiddenAll {
    [visibleViews enumerateObjectsUsingBlock:^(RestoreVipView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj hidden];
    }];
    
    [visibleViews removeAllObjects];
}

- (void)tapAction {
    [self hidden];
}
+ (void)showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack
{
    RestoreVipView *pleasefoView = [[RestoreVipView alloc] initWithFrame:CGRectZero showViewTitle:title buttonArrayTitle:titlArray callBack:callBack];
     UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    [window addSubview:pleasefoView];
  
    // 保存到数组
      if (!visibleViews) {
          visibleViews = [NSMutableArray array];
      }
    [visibleViews addObject:pleasefoView];
    
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
- (void)addLoadingIndicator {
    UIActivityIndicatorView *loadingView;

    if (@available(iOS 13.0, *)) {
        loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    } else {
        // iOS 12 及以下，仍然只能用 gray
        loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }

    loadingView.translatesAutoresizingMaskIntoConstraints = NO;

    // 🌊 淡蓝色（可微调）
    loadingView.color = [UIColor colorWithRed:0.45 green:0.70 blue:0.95 alpha:1.0];

    // 🔍 放大一点点（1.2 ~ 1.4 看效果）
    loadingView.transform = CGAffineTransformMakeScale(1.25, 1.25);

    [_contentView addSubview:loadingView];

    [NSLayoutConstraint activateConstraints:@[
        [loadingView.centerXAnchor constraintEqualToAnchor:_contentView.centerXAnchor],
        [loadingView.topAnchor constraintEqualToAnchor:_contentView.topAnchor constant:42],
        [loadingView.widthAnchor constraintEqualToConstant:66],
        [loadingView.heightAnchor constraintEqualToConstant:66]
    ]];

    [loadingView startAnimating];
     
}

- (void)addContentView:(NSString *)title buttonArrayTitle:(NSArray *)titleArray {
    if(titleArray.count < 2)return;
    self.title = title;
    
    int width = 305;
    int height = 241;
    _contentView = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - width)/2, (SCREEN_HEIGHT - height)/2 - 25, width, height)];
    _contentView.image = [UIImage imageNamed:@"bg_blue.png"];
    _contentView.layer.cornerRadius = 24;
    _contentView.layer.masksToBounds = YES;
    _contentView.userInteractionEnabled = YES;
    _contentView.clipsToBounds = YES;
    [self addSubview:_contentView];
    [self addLoadingIndicator];
    
    UIButton *btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
    btnClose.frame = CGRectMake(width - 12 - 30,12, 30, 30);
    [btnClose setImage:[UIImage imageNamed:@"close_gray"] forState:UIControlStateNormal];
    [btnClose addTarget:self action:@selector(btnCloseAction:) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:btnClose];

    int interval = 20;
    UILabel *lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(interval, 140, width - 2 * interval, 60)];
    lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
    lblSubtitle.textColor = BLACK_COLOR_1F;
    lblSubtitle.numberOfLines = 0;
    lblSubtitle.textAlignment = NSTextAlignmentCenter;
    lblSubtitle.text = NSLocalizedString(titleArray[0], @"");
    [_contentView addSubview:lblSubtitle];
    
    CGSize labelSize = [lblSubtitle sizeThatFits:CGSizeMake(width - 2 * interval,MAXFLOAT)];
    lblSubtitle.frame = CGRectMake(interval, 140, width - 2 * interval, labelSize.height + 5);
    
    int y = 140 + labelSize.height + 5 + 6;
    UILabel *lblContent = [[UILabel alloc]initWithFrame:CGRectMake(interval, y, width - 2 * interval, 60)];
    lblContent.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    lblContent.textColor = [self colorWithHexString:@"#63637D" alpha:1];
    lblContent.numberOfLines = 0;
    lblContent.textAlignment = NSTextAlignmentCenter;
    lblContent.text = NSLocalizedString(titleArray[1], @"");
    [_contentView addSubview:lblContent];
    
    CGSize labelSize2 = [lblSubtitle sizeThatFits:CGSizeMake(width - 2 * interval,MAXFLOAT)];
    lblContent.frame = CGRectMake(interval, y, width - 2 * interval, labelSize2.height + 10);
    _contentView.frame = CGRectMake((SCREEN_WIDTH - width)/2, (SCREEN_HEIGHT - height)/2 - 25, width, y + labelSize2.height + 10 + 42);
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
