//
//  AgreementConsentView.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AgreementConsentView : UIView
/// 当前是否已勾选
@property (nonatomic, assign, getter=isChecked) BOOL checked;
@property (nonatomic, copy, nullable) void (^onTapLinkName)(NSString *name);
/// 勾选状态变化回调
@property (nonatomic, copy, nullable) void (^onToggle)(BOOL checked);

/// 点击文本内链接回调（若不设置，将默认用 UIApplication 打开链接）
@property (nonatomic, copy, nullable) void (^onTapLink)(NSURL *url);

/// 指定初始化：传入两个链接
- (instancetype)initWithAgreementURL:(NSURL *)agreementURL
                           privacyURL:(NSURL *)privacyURL;

/// 更新链接与显示（可在多语言时重复调用）
- (void)updateAgreementURL:(NSURL *)agreementURL
                privacyURL:(NSURL *)privacyURL;

/// 主动设置为勾选状态
- (void)markAsChecked;
/// 主动取消勾选
- (void)markAsUnchecked;

- (void)hideCheckboxAndAdjustTextMargins;

@end

NS_ASSUME_NONNULL_END
/*
 // 可选：自己处理链接点击（比如 push 到 WebView 控制器）
 agree.onTapLink = ^(NSURL * _Nonnull url) {
     HelpRulesViewController *rulesVC = [HelpRulesViewController new];
     //rulesVC.title = @"《用户协议》";
     //rulesVC.title = NSLocalizedString(@"Terms of Service",@"");
     rulesVC.rule_type = @"agreement";
     [self.navigationController pushViewController:rulesVC animated:YES];
 };
 */
