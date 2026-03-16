//
//  QuizResultViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/8/3.
//

#import "QuizResultViewController.h"
#import <FLAnimatedImage/FLAnimatedImage.h>
#import "StrokeLabel.h"
@interface QuizResultViewController ()
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) UIButton *btnKeep;

@end

@implementation QuizResultViewController
- (void)viewDidAppear:(BOOL)animated {//视图---出现
    [super viewDidAppear:animated];
}
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"quiz_result";
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;

    int width = 40;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    btn.frame = CGRectMake(Distance＿M , statusBarH + 5, width, width);
    btn.layer.cornerRadius = width/2;//圆角
    btn.layer.masksToBounds = YES;
    btn.backgroundColor = [self.view colorWithHexString:@"#DEDEDE" alpha:0.5];
    [btn setImage:[UIImage imageNamed:@"return_black"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    int spacing = 60;
    self.headerView = [[UIView alloc]initWithFrame:CGRectMake(0, btn.frame.origin.y + width + 109 - spacing, SCREEN_WIDTH, 265 + spacing)];
    self.headerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.headerView];

    NSString *gifPath = [[NSBundle mainBundle] pathForResource:@"fireworks_withe" ofType:@"gif"];
    NSData *gifData = [NSData dataWithContentsOfFile:gifPath];

    // 2. 使用 FLAnimatedImage 解析
    FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:gifData];
    FLAnimatedImageView *animatedImageView = [[FLAnimatedImageView alloc] init];
    animatedImageView.animatedImage = animatedImage;
    animatedImageView.frame = CGRectMake((SCREEN_WIDTH-animatedImage.size.width)/2, 0, animatedImage.size.width, animatedImage.size.height);

    // 5 秒后移除动画
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [animatedImageView removeFromSuperview];
    });
    
    UIImageView *imgResult = [[UIImageView alloc]initWithFrame:CGRectMake((self.headerView.frame.size.width- 232)/2, 32 + spacing, 232, 232)];

    int type;
    if (self.score < 9) {
        if (self.score < 6) {
            type = 2;
        } else {
            type = 1;
        }
    } else {
        type = 0;
    }
    
    imgResult.image = [UIImage imageNamed:[NSString stringWithFormat:@"quit_result_%d_%@",type,Language_Type]];
    [self.headerView addSubview:imgResult];
    [self.headerView addSubview:animatedImageView];
    if(self.score > 10){
        self.score = 10;
    }
    
    NSString *text = [NSString stringWithFormat:@"%d%@",self.score * 10,@"%"];
    //UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0,90 ,232, 52)];
    StrokeLabel *label = [[StrokeLabel alloc] initWithFrame:CGRectMake(0,90 ,232, 52)];
    label.text = text;
    label.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:50];
    label.textAlignment = NSTextAlignmentCenter;
    label.strokeColor = BLACK_COLOR_1F;
    label.strokeWidth = 4.0;
    [imgResult addSubview:label];
    [self.view addSubview:self.btnKeep];
   
    //UIImageView *imgArrow = [[UIImageView alloc]initWithFrame:CGRectMake(self.btnKeep.frame.size.width/2 + 75, (56-16)/2 + 2,16, 16)];
    //imgArrow.image = [self.view imageWithImageName:@"next_pink" tintColor:BLACK_COLOR];
    //[self.btnKeep addSubview:imgArrow];
}
- (UIButton *)btnKeep {
    if(!_btnKeep){//标题图button
        _btnKeep = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnKeep.frame = CGRectMake(43, self.headerView.frame.origin.y + self.headerView.frame.size.height + 40, SCREEN_WIDTH - 86, 56);
        _btnKeep.layer.cornerRadius = 28;//圆角
        _btnKeep.layer.masksToBounds = YES;
        _btnKeep.titleEdgeInsets = UIEdgeInsetsMake(0,-20, 0, 0);
        _btnKeep.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
        [_btnKeep setTintColor:[UIColor blackColor]];
        [_btnKeep setTitle:NSLocalizedString(@"Keep Practicing",@"") forState:UIControlStateNormal];
        _btnKeep.layer.borderWidth = 1;//边框
        _btnKeep.layer.borderColor = [UIColor blackColor].CGColor;
        [_btnKeep addTarget:self action:@selector(btnKeepAction:) forControlEvents:UIControlEventTouchUpInside];

        UIImage *arrowImage = [UIImage imageNamed:@"next_black"];
        [_btnKeep setImage:arrowImage forState:UIControlStateNormal];
        _btnKeep.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        _btnKeep.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _btnKeep.titleEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
        _btnKeep.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, -2);
        _btnKeep.adjustsImageWhenHighlighted = NO;
    }
    return _btnKeep;
}
- (void)btnKeepAction:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (void)backAction {
    //[self.navigationController popViewControllerAnimated:YES];
    //self.selectedTypeIndex(1);
    [self.navigationController popToRootViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
