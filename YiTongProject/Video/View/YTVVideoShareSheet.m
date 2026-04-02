//
//  YTVVideoShareSheet.m
//  YiTongProject
//

#import "YTVVideoShareSheet.h"
#import "HeaderConfig.h"
#import "LanguageHelper.h"

static NSString *YTVResolvedShareURLString(NSString * _Nullable shareURLString, NSString *videoId) {
    NSString *trim = [shareURLString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trim.length > 0) {
        NSURL *u = [NSURL URLWithString:trim];
        if (u && ([u.scheme.lowercaseString isEqualToString:@"http"] || [u.scheme.lowercaseString isEqualToString:@"https"])) {
            return trim;
        }
    }
    if (videoId.length == 0) {
        return @"";
    }
    NSMutableCharacterSet *allowed = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowed addCharactersInString:@"-_.~"];
    NSString *enc = [videoId stringByAddingPercentEncodingWithAllowedCharacters:allowed];
    if (enc.length == 0) {
        enc = @"";
    }
    return [NSString stringWithFormat:@"https://shiyi.yitong.com/app/video?id=%@&from=share", enc];
}

static BOOL YTVShareUseDomesticChannelOrder(void) {
    NSString *lang = [LanguageHelper currentLanguage] ?: @"";
    return [lang hasPrefix:@"zh"];
}

@interface YTVVideoShareSheet ()
@property (nonatomic, weak) UIViewController *hostViewController;
@property (nonatomic, copy) NSString *resolvedURLString;
@property (nonatomic, copy, nullable) NSString *videoTitle;
@property (nonatomic, strong) UIControl *dimView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIStackView *actionsStack;
@property (nonatomic, strong) UIButton *cancelButton;
@end

@implementation YTVVideoShareSheet

+ (void)ytv_presentFromHostViewController:(UIViewController *)host
                               sourceView:(UIView *)sourceView
                           shareURLString:(NSString *)shareURLString
                                  videoId:(NSString *)videoId
                               videoTitle:(NSString *)videoTitle {
    if (!host) {
        return;
    }
    NSString *resolved = YTVResolvedShareURLString(shareURLString, videoId);
    if (resolved.length == 0) {
        [MBProgressHUD showLabel:NSLocalizedString(@"YTV_share_unavailable", @"")];
        return;
    }
    UIView *container = host.view;
    if (!container) {
        return;
    }
    YTVVideoShareSheet *sheet = [[YTVVideoShareSheet alloc] initWithFrame:container.bounds];
    sheet.hostViewController = host;
    sheet.resolvedURLString = resolved;
    sheet.videoTitle = [videoTitle copy];
    sheet.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [sheet ytv_buildUI];
    [container addSubview:sheet];
    [sheet ytv_applyLayout];
    sheet.alpha = 0;
    sheet.cardView.transform = CGAffineTransformMakeTranslation(0, 320);
    [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        sheet.alpha = 1;
        sheet.cardView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)ytv_buildUI {
    self.dimView = [[UIControl alloc] init];
    self.dimView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    [self.dimView addTarget:self action:@selector(ytv_dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.dimView];
    self.cardView = [[UIView alloc] init];
    self.cardView.backgroundColor = [UIColor whiteColor];
    self.cardView.layer.cornerRadius = 14;
    self.cardView.layer.masksToBounds = YES;
    [self addSubview:self.cardView];
    [self.cardView addSubview:self.actionsStack];
    [self.cardView addSubview:self.cancelButton];
}

- (void)ytv_applyLayout {
    [self.dimView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(12);
        make.right.equalTo(self).offset(-12);
        make.bottom.equalTo(self.mas_safeAreaLayoutGuideBottom).offset(-10);
    }];
    [self.actionsStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.cardView).offset(8);
        make.left.right.equalTo(self.cardView);
    }];
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.actionsStack.mas_bottom).offset(8);
        make.left.equalTo(self.cardView).offset(12);
        make.right.equalTo(self.cardView).offset(-12);
        make.bottom.equalTo(self.cardView).offset(-12);
        make.height.mas_equalTo(48);
    }];
}

- (UIStackView *)actionsStack {
    if (!_actionsStack) {
        _actionsStack = [[UIStackView alloc] init];
        _actionsStack.axis = UILayoutConstraintAxisVertical;
        _actionsStack.spacing = 0;
        _actionsStack.alignment = UIStackViewAlignmentFill;
        _actionsStack.distribution = UIStackViewDistributionFill;
        BOOL domestic = YTVShareUseDomesticChannelOrder();
        if (domestic) {
            [self ytv_addActionRowTitle:NSLocalizedString(@"YTV_share_sheet_wechat_friend", @"") action:@selector(ytv_onWeChatFriend)];
            [self ytv_addSeparator];
            [self ytv_addActionRowTitle:NSLocalizedString(@"YTV_share_sheet_wechat_timeline", @"") action:@selector(ytv_onWeChatMoments)];
        } else {
            [self ytv_addActionRowTitle:NSLocalizedString(@"YTV_share_sheet_whatsapp", @"") action:@selector(ytv_onWhatsApp)];
            [self ytv_addSeparator];
            [self ytv_addActionRowTitle:NSLocalizedString(@"YTV_share_sheet_instagram", @"") action:@selector(ytv_onInstagram)];
        }
        [self ytv_addSeparator];
        [self ytv_addActionRowTitle:NSLocalizedString(@"YTV_share_sheet_copy_link", @"") action:@selector(ytv_onCopyLink)];
    }
    return _actionsStack;
}

- (void)ytv_addSeparator {
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [self.cardView colorWithHexString:@"#E8E8E8" alpha:1];
    [self.actionsStack addArrangedSubview:line];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(1.0 / UIScreen.mainScreen.scale);
    }];
}

- (void)ytv_addActionRowTitle:(NSString *)title action:(SEL)sel {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:17];
    [btn setTitleColor:[self.cardView colorWithHexString:@"#1F1F39" alpha:1] forState:UIControlStateNormal];
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [btn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(52);
    }];
    [self.actionsStack addArrangedSubview:btn];
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_cancelButton setTitle:NSLocalizedString(@"YTV_share_sheet_cancel", @"") forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:16];
        [_cancelButton setTitleColor:[self.cardView colorWithHexString:@"#4C9BEF" alpha:1] forState:UIControlStateNormal];
        _cancelButton.backgroundColor = [self.cardView colorWithHexString:@"#F5F9FF" alpha:1];
        _cancelButton.layer.cornerRadius = 10;
        _cancelButton.layer.masksToBounds = YES;
        [_cancelButton addTarget:self action:@selector(ytv_dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (void)ytv_pasteboardShareText {
    NSMutableString *m = [NSMutableString string];
    if (self.videoTitle.length) {
        [m appendString:self.videoTitle];
        [m appendString:@"\n"];
    }
    [m appendString:self.resolvedURLString];
    [UIPasteboard generalPasteboard].string = [m copy];
}

- (void)ytv_openURLIfPossible:(NSURL *)url fallbackMessage:(NSString *)msg {
    if (!url) {
        [MBProgressHUD showLabel:msg];
        return;
    }
    UIApplication *app = [UIApplication sharedApplication];
    if (![app canOpenURL:url]) {
        [MBProgressHUD showLabel:msg];
        return;
    }
    [app openURL:url options:@{} completionHandler:nil];
}

- (void)ytv_onWeChatFriend {
    [self ytv_pasteboardShareText];
    NSURL *wx = [NSURL URLWithString:@"weixin://"];
    if ([[UIApplication sharedApplication] canOpenURL:wx]) {
        [[UIApplication sharedApplication] openURL:wx options:@{} completionHandler:nil];
        [MBProgressHUD showLabel:NSLocalizedString(@"YTV_share_wechat_copy_hint", @"")];
    } else {
        [MBProgressHUD showLabel:NSLocalizedString(@"YTV_share_copied", @"")];
    }
    [self ytv_dismiss];
}

- (void)ytv_onWeChatMoments {
    [self ytv_pasteboardShareText];
    NSURL *wx = [NSURL URLWithString:@"weixin://"];
    if ([[UIApplication sharedApplication] canOpenURL:wx]) {
        [[UIApplication sharedApplication] openURL:wx options:@{} completionHandler:nil];
        [MBProgressHUD showLabel:NSLocalizedString(@"YTV_share_wechat_moments_hint", @"")];
    } else {
        [MBProgressHUD showLabel:NSLocalizedString(@"YTV_share_copied", @"")];
    }
    [self ytv_dismiss];
}

- (void)ytv_onWhatsApp {
    NSString *body = self.videoTitle.length
        ? [NSString stringWithFormat:@"%@\n%@", self.videoTitle, self.resolvedURLString]
        : self.resolvedURLString;
    NSURLComponents *comp = [[NSURLComponents alloc] initWithString:@"whatsapp://send"];
    comp.queryItems = @[ [NSURLQueryItem queryItemWithName:@"text" value:body] ];
    NSURL *wu = comp.URL;
    [self ytv_openURLIfPossible:wu fallbackMessage:NSLocalizedString(@"YTV_share_whatsapp_unavailable", @"")];
    [self ytv_dismiss];
}

- (void)ytv_onInstagram {
    [self ytv_pasteboardShareText];
    NSURL *ig = [NSURL URLWithString:@"instagram://app"];
    if ([[UIApplication sharedApplication] canOpenURL:ig]) {
        [[UIApplication sharedApplication] openURL:ig options:@{} completionHandler:nil];
        [MBProgressHUD showLabel:NSLocalizedString(@"YTV_share_instagram_hint", @"")];
    } else {
        [MBProgressHUD showLabel:NSLocalizedString(@"YTV_share_copied", @"")];
    }
    [self ytv_dismiss];
}

- (void)ytv_onCopyLink {
    [UIPasteboard generalPasteboard].string = self.resolvedURLString;
    [MBProgressHUD showLabel:NSLocalizedString(@"YTV_share_copied", @"")];
    [self ytv_dismiss];
}

- (void)ytv_dismiss {
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.alpha = 0;
        self.cardView.transform = CGAffineTransformMakeTranslation(0, 320);
    } completion:^(__unused BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
