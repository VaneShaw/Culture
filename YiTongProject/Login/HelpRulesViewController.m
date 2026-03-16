//
//  HelpRulesViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/22.
//

#import "HelpRulesViewController.h"
#import <WebKit/WebKit.h>

@interface HelpRulesViewController ()<WKNavigationDelegate,WKUIDelegate,UIGestureRecognizerDelegate,UINavigationControllerDelegate>
@property (strong, nonatomic) WKWebView *wkView;

@end

@implementation HelpRulesViewController

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
    //self.title = kLocalizedTableString(@"User Agreement", @"HomeLocalizable");
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    [self addGlobalBackButton];
    [self addGlobalBackButtonColor:[self.view colorWithHexString:@"F1F1F1" alpha:1] headerTitleDic:@{@"title":self.title,@"color":@"#1F1F39"}];

    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    CGRect rectNav = self.navigationController.navigationBar.frame;
    int y = rectNav.size.height + statusBarH;

    CGRect frame =  CGRectMake(10, y + 15, SCREEN_WIDTH-15, SCREEN_HEIGHT - y - 30);
    WKWebView *wkView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - y)];
    wkView.frame = frame;
    wkView.navigationDelegate = self;
    wkView.UIDelegate = self;
    wkView.scrollView.backgroundColor = [UIColor clearColor];
    wkView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:wkView];
    self.wkView = wkView;
    
    self.wkView.hidden = YES;
    [MBProgressHUD showMessage:@""];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(Countdown_Seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUD];
        self.wkView.hidden = NO;
    });
    [self getPrivacy];
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    //禁止用户选择
    /*[webView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none';" completionHandler:nil];
    [webView evaluateJavaScript:@"document.activeElement.blur();" completionHandler:nil];
    // 适当增大字体大小
    [webView evaluateJavaScript:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '230%'" completionHandler:nil];
    
    //if (THEME_Index == 1) {
    [ webView evaluateJavaScript:@"document.getElementsByTagName('body')[0].style.webkitTextFillColor= '#FFFFFF'"completionHandler:nil];
    //[webView evaluateJavaScript:@"document.body.style.backgroundColor=\"#130d44\"" completionHandler:nil];
    
    [webView evaluateJavaScript:@"document.body.style.backgroundColor=\"#FFFFFF\"" completionHandler:nil];*/
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation {
    [MBProgressHUD hideHUD];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.wkView.hidden = NO;
    });
}
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [MBProgressHUD hideHUD];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.wkView.hidden = NO;
    });
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (void)getPrivacy{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    params[@"is_member"] = @"1";
    
    //@"agreement"用户协议     @"privacy"隐私政策    @"member" 会员协议
    [HttpTools postRequest:@"/auth/getPrivacy/" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        if (success) {
            NSDictionary *dic = [NSDictionary dictionaryWithDictionary:response.data];
            //NSString *agreement = [NSString stringWithFormat:@"%@",dic[@"agreement"]];//用户协议
            //NSString *privacy = [NSString stringWithFormat:@"%@",dic[@"privacy"]];   //隐私政策
            
            NSString *content = [NSString stringWithFormat:@"%@",dic[self.rule_type]];
            NSLog(@"------ccc-----------aaa----[%@]------------",content);
            NSURL *url = [NSURL URLWithString:content];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [self.wkView loadRequest:request];
        
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
     
    } failure:^(NSError * _Nonnull error) {
    }];
}
@end
