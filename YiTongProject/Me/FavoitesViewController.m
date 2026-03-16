//
//  FavoitesViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/8/8.
//

#import "FavoitesViewController.h"
@interface FavoitesViewController ()

@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *lblTitle;
@end

@implementation FavoitesViewController
//收藏
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    [self addGlobalBackButton];
    //self.navigationController.navigationBarHidden = YES;
 
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    self.imgView = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH-140)/2, statusBarH + 16 + 200, 140, 140)];
    self.imgView.image = [UIImage imageNamed:@"file_blue"];
    [self.view addSubview:self.imgView];
    
    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(25, 2 + self.imgView.frame.origin.y + self.imgView.frame.size.height, SCREEN_WIDTH - 40, 50)];
    lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
    lblTitle.textColor = [self.view colorWithHexString:@"#8F8F8F" alpha:1];
    lblTitle.numberOfLines = 0;
    lblTitle.textAlignment = NSTextAlignmentCenter;
    //lblTitle.text = NSLocalizedString(@"No orders found. \nPurchases will appear here once completed.",@"");
    //lblTitle.text = NSLocalizedString(@"You haven’t collected anything yet.\nStart exploring and add your favorites here!",@"");
    lblTitle.text = NSLocalizedString(@"You haven’t collected anything yet.Start exploring and add your favorites here!",@"");//@"\n"
    [self.view addSubview:lblTitle];
    self.lblTitle = lblTitle;
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
