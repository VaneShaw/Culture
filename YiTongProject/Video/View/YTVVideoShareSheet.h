//
//  YTVVideoShareSheet.h
//  YiTongProject
//
//  自定义分享面板（技术设计 §7 / 阶段 8，替代系统 UIActivityViewController）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTVVideoShareSheet : UIView

/// `shareURLString` 优先（服务端 `share_url`）；为空时用 `videoId` 拼 `https://shiyi.yitong.com/app/video?id=…&from=share`
+ (void)ytv_presentFromHostViewController:(UIViewController *)host
                               sourceView:(nullable UIView *)sourceView
                           shareURLString:(nullable NSString *)shareURLString
                                  videoId:(NSString *)videoId
                               videoTitle:(nullable NSString *)videoTitle;

@end

NS_ASSUME_NONNULL_END
