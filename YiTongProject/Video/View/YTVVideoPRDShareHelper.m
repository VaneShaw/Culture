//
//  YTVVideoPRDShareHelper.m
//  YiTongProject
//

#import "YTVVideoPRDShareHelper.h"
#import "HeaderConfig.h"

@implementation YTVVideoPRDShareHelper

+ (NSString *)ytv_downloadLandingPageURLString {
    return @"https://shiyi.yitong.com/download";
}

+ (NSString *)ytv_shareActivityBodyText {
    return NSLocalizedString(@"YTV_PRD_share_activity_body", @"");
}

+ (void)ytv_presentSystemShareFromViewController:(UIViewController *)host
                                      sourceView:(UIView *)sourceView {
    if (!host) {
        return;
    }
    NSString *text = [self ytv_shareActivityBodyText];
    NSURL *downloadURL = [NSURL URLWithString:[self ytv_downloadLandingPageURLString]];
    if (text.length == 0 || downloadURL == nil) {
        [MBProgressHUD showLabel:NSLocalizedString(@"YTV_share_unavailable", @"")];
        return;
    }
    NSArray *items = @[ text, downloadURL ];
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIView *anchor = sourceView ?: host.view;
        UIPopoverPresentationController *pop = avc.popoverPresentationController;
        pop.sourceView = anchor;
        pop.sourceRect = CGRectIsEmpty(anchor.bounds)
            ? CGRectMake(CGRectGetMidX(host.view.bounds), CGRectGetMidY(host.view.bounds), 1, 1)
            : anchor.bounds;
    }
    [host presentViewController:avc animated:YES completion:nil];
}

+ (void)ytv_copyDownloadLinkAndShowToast {
    [UIPasteboard generalPasteboard].string = [self ytv_downloadLandingPageURLString];
    [MBProgressHUD showLabel:NSLocalizedString(@"YTV_PRD_copy_download_toast", @"")];
}

@end
