//
//  PasswordSuccessfulView.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "PasswordSuccessfulView.h"

@interface PasswordSuccessfulView()
@property (nonatomic, strong) UIView *bkView;
@property (nonatomic, strong) UIImageView *imgCode;
@property (nonatomic, strong) UIImageView *contentView;
@property (nonatomic, copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@end
@implementation PasswordSuccessfulView

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
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [_bkView addGestureRecognizer:tap];
        [tap addTarget:self action:@selector(tapAction)];
        [self addContentView:title buttonArrayTitle:titlArray];
    }
    return self;
}
- (void)tapAction {
    //[self hidden];
}
+ (void)showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack
{
    PasswordSuccessfulView *pleasefoView = [[PasswordSuccessfulView alloc] initWithFrame:CGRectZero showViewTitle:title buttonArrayTitle:titlArray callBack:callBack];
     UIWindow *window = [UIApplication sharedApplication].windows.firstObject;
    [window addSubview:pleasefoView];
    
    [UIView animateWithDuration:0.25 animations:^{
        //pleasefoView.bkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        pleasefoView.bkView.backgroundColor = [UIColor clearColor];
        pleasefoView.contentView.alpha = 1;
    }];
}
- (void)addContentView:(NSString *)title buttonArrayTitle:(NSArray *)titleArray {

    int width = 323;
    int height = 82;
    if(!IS_OVERSEAS_VERSION){
        height = 44;
    }
 
    _contentView = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH-width)/2, (SCREEN_HEIGHT - height)/2 - 25, width, height)];
    _contentView.backgroundColor = [self colorWithHexString:@"#242C32" alpha:1];
    _contentView.layer.cornerRadius = 8;
    _contentView.layer.masksToBounds = YES;
    [self addSubview:_contentView];

    UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(16, (height-32)/2, 32, 32)];
    imgView.image = [UIImage imageNamed:@"success_green"];
    [_contentView addSubview:imgView];
    
    UIImageView *imgIcon = [[UIImageView alloc]initWithFrame:CGRectMake(5, (height-22)/2, 22, 22)];
    imgIcon.image = [UIImage imageNamed:@"slice_green"];
    [imgView addSubview:imgIcon];
    
    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(64,0, width - 74, height)];
    lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaMedium size:14];
    lblTitle.textColor = [self colorWithHexString:@"#C8C5C5" alpha:1];
    if(title.length > 6){
        lblTitle.text = title;
    } else {
        lblTitle.text = NSLocalizedString(@"Password reset successful.Please log in", @"");
    }
    lblTitle.numberOfLines = 2;
    [_contentView addSubview:lblTitle];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hidden];
    });
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

