//
//  UIViewController+BackButton.m
//  YiTongProject
//
//  Created by Vincent on 2025/8/12.
//

#import "UIViewController+BackButton.h"

/// 深色圆底时使用浅色返回箭头，避免与 `return_black` 对比度不足。
static BOOL YTVBackButtonBackgroundIsDark(UIColor *color) {
    if (!color) {
        return NO;
    }
    CGFloat r, g, b, a;
    if (![color getRed:&r green:&g blue:&b alpha:&a]) {
        return NO;
    }
    CGFloat lum = 0.299 * r + 0.587 * g + 0.114 * b;
    return lum < 0.45;
}

@implementation UIViewController (BackButton)
//@{@"title":@"Membership",@"color":@"#FFFFFF"}
- (void)addGlobalBackButtonColor:(UIColor *)color headerTitleDic:(NSDictionary *)dic {
    
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(Distance＿M, statusBarH, 55, 45)];
    buttonContainer.backgroundColor = [UIColor clearColor];

    NSString *title = dic[@"title"];
    // 创建返回按钮
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton addTarget:self action:@selector(globalBackAction) forControlEvents:UIControlEventTouchUpInside];
    backButton.backgroundColor = color;
    
    if (YTVBackButtonBackgroundIsDark(color) || [title isEqualToString:@"Membership"]) {
        [backButton setImage:[UIImage imageNamed:@"return_white"] forState:UIControlStateNormal];
    } else {
        [backButton setImage:[UIImage imageNamed:@"return_black"] forState:UIControlStateNormal];
    }
    //backButton.frame = CGRectMake(Distance＿M, 5 + statusBarH, width,width);
    backButton.frame = CGRectMake(0, 5, 40,40);
    backButton.layer.cornerRadius = 20;//圆角
    backButton.layer.masksToBounds = YES;
    [buttonContainer addSubview:backButton];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(globalBackAction)];
    [buttonContainer addGestureRecognizer:tap];
    [self.view addSubview:buttonContainer];
    // 添加按钮到视图
    //[self.view addSubview:backButton];
    //[self.view bringSubviewToFront:backButton];
    
    // 添加按钮到视图
    [self.view addSubview:buttonContainer];
    [self.view bringSubviewToFront:buttonContainer];
    
    // --------- 添加标题 UILabel ---------
    if(title.length > 0 && title){
        UILabel *lblTitle = [[UILabel alloc] init];
        lblTitle.text = NSLocalizedString(title,@"");
        NSString *color1 = dic[@"color"];
        lblTitle.textColor = [theAppDelegate.window colorWithHexString:color1 alpha:1];
        lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
        lblTitle.textAlignment = NSTextAlignmentCenter;
        // 先计算大小
        [lblTitle sizeToFit];
        // 水平居中
        CGFloat viewWidth = CGRectGetWidth(self.view.frame);
        lblTitle.center = CGPointMake(viewWidth / 2.0, backButton.center.y + statusBarH + 1); // 上下与 backButton 居中
        [self.view addSubview:lblTitle];
        [self.view bringSubviewToFront:lblTitle];
    }
}
- (void)addGlobalBackButton {
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(Distance＿M, statusBarH, 55, 45)];
    buttonContainer.backgroundColor = [UIColor clearColor];
    //buttonContainer.backgroundColor = [UIColor orangeColor];
    // 创建返回按钮
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton addTarget:self action:@selector(globalBackAction) forControlEvents:UIControlEventTouchUpInside];

    backButton.layer.cornerRadius = 20;//圆角
    backButton.layer.masksToBounds = YES;
    backButton.backgroundColor = [self.view colorWithHexString:@"F1F1F1" alpha:1];
    [backButton setImage:[UIImage imageNamed:@"return_black"] forState:UIControlStateNormal];
 
    //backButton.frame = CGRectMake(Distance＿M, 5 + statusBarH, 40,40);
    backButton.frame = CGRectMake(0, 3, 40,40);
    [buttonContainer addSubview:backButton];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(globalBackAction)];
    [buttonContainer addGestureRecognizer:tap];
    [self.view addSubview:buttonContainer];
    
    // 添加按钮到视图
    [self.view addSubview:buttonContainer];
    [self.view bringSubviewToFront:buttonContainer];
}
- (void)globalBackAction {
    // 默认返回逻辑
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
@end
