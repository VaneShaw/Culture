//
//  LaunchViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "LaunchViewController.h"
#import "LoginViewController.h"

@interface LaunchViewController ()
@property (strong, nonatomic) UIImageView *imgAvatar;
@property (strong, nonatomic) UIButton *btnGuest;
@property (strong, nonatomic) UIButton *btnEmail;

@end

@implementation LaunchViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //theAppDelegate.window
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    //UIColor *color = [self.view colorWithHexString:@"#D9EFFF" alpha:1];
    //UIColor *color2 = [self.view colorWithHexString:@"#F4F6F8" alpha:1];
    //UIColor *backgroundColor = [self.view gradientColorWithSize:CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT) colors:@[color, color2]];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIImage *backgroundImage = [UIImage imageNamed:@"launch_background"];
    backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    backgroundImageView.image = backgroundImage;
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    [self.view addSubview:self.imgAvatar];
    [self.view addSubview:self.btnEmail];
    //[self.view addSubview:self.btnGuest];
}
- (UIImageView *)imgAvatar {
    if(!_imgAvatar){
        int width = 122;
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        _imgAvatar = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH/2 - width/2, 122 + statusBarH, width, width)];
        //_imgAvatar.backgroundColor = [self.view gradientColorWithSize:CGSizeMake(width, _imgAvatar.frame.size.height) colors:@[[self.view colorWithHexString:@"#63A8F5" alpha:1], [self.view colorWithHexString:@"#3A89D8" alpha:1]]];
        _imgAvatar.layer.cornerRadius = 20;//圆角
        _imgAvatar.layer.masksToBounds = YES;
        
        UILabel *lblLogo = [[UILabel alloc]initWithFrame:CGRectMake(0, (_imgAvatar.frame.size.height-23)/2, _imgAvatar.frame.size.width, 23)];
        lblLogo.textColor = [UIColor whiteColor];
        //[_imgAvatar addSubview:lblLogo];
        lblLogo.textAlignment = NSTextAlignmentCenter;
        lblLogo.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
        //lblLogo.text = @"易通";
        _imgAvatar.image = [UIImage imageNamed:@"logo_blue"];
        //launch_background
        
        UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(0, _imgAvatar.frame.origin.y + _imgAvatar.frame.size.height + 23, SCREEN_WIDTH, 31)];
        lblTitle.textColor = [UIColor blackColor];
        [self.view addSubview:lblTitle];
        lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
        lblTitle.textAlignment = NSTextAlignmentCenter;
        lblTitle.text = @"Say hi to 汉字！";
    }
    return _imgAvatar;
}
- (UIButton *)btnEmail {
    if(!_btnEmail){
        _btnEmail = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnEmail.frame = CGRectMake(Distance＿X, self.imgAvatar.frame.origin.y + self.imgAvatar.frame.size.height + 143, SCREEN_WIDTH - 2 * Distance＿X, 52);
        _btnEmail.layer.cornerRadius = 8;//圆角
        _btnEmail.layer.masksToBounds = YES;
        _btnEmail.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:18];
        [_btnEmail setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_btnEmail addTarget:self action:@selector(btnEmailAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnEmail setTitle:@"Sign in with Email" forState:UIControlStateNormal];
        //_btnEmail.backgroundColor =[UIColor orangeColor];
        
        // 1. 创建 CAGradientLayer UIbutton颜色渐变
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = _btnEmail.bounds;
        gradientLayer.colors = @[(id)[self.view colorWithHexString:@"#63A8F5" alpha:1].CGColor, (id)[self.view colorWithHexString:@"#3A89D8" alpha:1].CGColor];
        gradientLayer.startPoint = CGPointMake(0, 0.5); // 水平渐变
        gradientLayer.endPoint = CGPointMake(1, 0.5);

        // 2. 添加到 button 的 layer
        [_btnEmail.layer insertSublayer:gradientLayer atIndex:0];
        // 3. 确保 button 的标题可见（否则会被遮挡）
        _btnEmail.titleLabel.backgroundColor = [UIColor clearColor];
    }
    return _btnEmail;
}
- (void)btnEmailAction:(UIButton *)sender {
    LoginViewController *loginVC = [LoginViewController new];
    //[theAppDelegate setNavieationBarColor:loginNC];
    [self.navigationController pushViewController:loginVC animated:YES];
}
- (UIButton *)btnGuest {
    if(!_btnGuest){
        _btnGuest = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnGuest.frame = CGRectMake(Distance＿X, self.btnEmail.frame.origin.y + self.btnEmail.frame.size.height +28, SCREEN_WIDTH - 2 * Distance＿X, 52);
        _btnGuest.layer.cornerRadius = 8;//圆角
        _btnGuest.layer.masksToBounds = YES;
        //_btnLoging.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
        _btnGuest.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:18];
        _btnGuest.backgroundColor = [self.view colorWithHexString:@"#E3F2FD" alpha:1];
        [_btnGuest setTitleColor:Main_COLOR forState:UIControlStateNormal];
        [_btnGuest addTarget:self action:@selector(btnGuestAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnGuest setTitle:@"Continue as Guest" forState:UIControlStateNormal];
        //Base style for 圆角矩形 1 拷
    }
    return _btnGuest;
}
- (void)btnGuestAction:(UIButton *)sender {
    [theAppDelegate setTabBarController];
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
