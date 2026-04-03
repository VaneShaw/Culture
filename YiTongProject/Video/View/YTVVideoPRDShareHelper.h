//
//  YTVVideoPRDShareHelper.h
//  YiTongProject
//
//  PRD v2.0：系统 UIActivityViewController + 固定中英文案 + 下载落地页；单独复制下载链接 + Toast。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTVVideoPRDShareHelper : NSObject

+ (NSString *)ytv_downloadLandingPageURLString;

/// 系统分享：`activityItems` 为本地化长文案 + 下载页 `NSURL`。
+ (void)ytv_presentSystemShareFromViewController:(UIViewController *)host
                                      sourceView:(nullable UIView *)sourceView;

/// 仅复制下载落地页 URL，并弹出 PRD 固定 Toast。
+ (void)ytv_copyDownloadLinkAndShowToast;

@end

NS_ASSUME_NONNULL_END
