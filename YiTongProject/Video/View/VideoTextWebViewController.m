//
//  VideoTextWebViewController.m
//  YiTongProject
//

#import "VideoTextWebViewController.h"
#import "HeaderConfig.h"
#import <WebKit/WebKit.h>

@interface VideoTextWebViewController () <WKNavigationDelegate>
@property (nonatomic, copy) NSURL *pageURL;
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation VideoTextWebViewController

- (instancetype)initWithPageURL:(NSURL *)pageURL {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _pageURL = [pageURL copy];
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self addGlobalBackButton];
    [self addGlobalBackButtonColor:[self.view colorWithHexString:@"F1F1F1" alpha:1]
                    headerTitleDic:@{ @"title": @"YTV_full_text_title", @"color": @"#1F1F39" }];
    [self.view addSubview:self.webView];
    CGFloat topInset = [PublicTool getStatusBarHeight] + 52;
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(topInset);
        make.left.right.bottom.equalTo(self.view);
    }];
    NSURLRequest *req = [NSURLRequest requestWithURL:self.pageURL];
    [self.webView loadRequest:req];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [MBProgressHUD hideHUD];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [MBProgressHUD hideHUD];
}

#pragma mark - Lazy

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
        _webView.navigationDelegate = self;
        _webView.backgroundColor = [UIColor whiteColor];
        _webView.scrollView.backgroundColor = [UIColor whiteColor];
    }
    return _webView;
}

@end
