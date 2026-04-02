//
//  VideoTextWebViewController.h
//  YiTongProject
//
//  全文页：WKWebView 打开 full_text_url（技术设计 §7）
//

#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoTextWebViewController : BaseViewController

- (instancetype)initWithPageURL:(NSURL *)pageURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
