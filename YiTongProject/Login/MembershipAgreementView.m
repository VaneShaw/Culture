//
//  MembershipAgreementView.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/2.
//

#import "MembershipAgreementView.h"

@interface MembershipAgreementView () <UITextViewDelegate>
@property (nonatomic, strong) UIButton *checkboxButton;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) NSURL *agreementURL;
@property (nonatomic, strong) NSURL *privacyURL;
@end

@implementation MembershipAgreementView

- (instancetype)initWithAgreementURL:(NSURL *)agreementURL privacyURL:(NSURL *)privacyURL {
    
    if (self = [super initWithFrame:CGRectZero]) {
        agreementURL = [NSURL URLWithString:@"https://yourdomain.com/terms"];      // 用户协议链接
        privacyURL = [NSURL URLWithString:@"https://yourdomain.com/privacy"];    // 隐私政策链接
        _agreementURL = agreementURL;
        _privacyURL = privacyURL;
        [self commonInit];
        [self rebuildText];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
        [self rebuildText];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = UIColor.clearColor;

    // 1) 小圆圈勾选按钮
    self.checkboxButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *offImg = [UIImage imageNamed:@"img_select_gray"];
    UIImage *onImg = [UIImage imageNamed:@"img_select_blue"];
    [self.checkboxButton setImage:offImg forState:UIControlStateNormal];
    [self.checkboxButton setImage:onImg forState:UIControlStateSelected];
    self.checkboxButton.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    self.checkboxButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5); // 调整图片边距
    [self.checkboxButton addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventTouchUpInside];
    self.checkboxButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.checkboxButton];
    
    // Auto Layout
    [NSLayoutConstraint activateConstraints:@[
    [self.checkboxButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
    [self.checkboxButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.checkboxButton.widthAnchor constraintEqualToConstant:40],
    [self.checkboxButton.heightAnchor constraintEqualToConstant:40],
    ]];

    // 2) 文本（可点击链接）
    self.textView = [[UITextView alloc] initWithFrame:CGRectZero textContainer:nil];
    self.textView.delegate = self;
    self.textView.scrollEnabled = NO;
    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.backgroundColor = UIColor.clearColor;
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;

    //NSMutableDictionary *linkAttrs = [NSMutableDictionary dictionary];
    //linkAttrs[NSForegroundColorAttributeName] = [UIColor systemBlueColor];
    //linkAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleNone);
    //self.textView.linkTextAttributes = linkAttrs.copy;
    self.textView.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
    self.textView.textColor = [self colorWithHexString:@"#9DABC2" alpha:1];
    // 链接文本颜色 + 下划线 
    NSMutableDictionary *linkAttrs = [NSMutableDictionary dictionary];
    //linkAttrs[NSForegroundColorAttributeName] = [UIColor systemBlueColor];
    linkAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
    self.textView.linkTextAttributes = linkAttrs;
    
    [self addSubview:self.textView];
    [NSLayoutConstraint activateConstraints:@[
    [self.textView.leadingAnchor constraintEqualToAnchor:self.checkboxButton.trailingAnchor constant:0],
    [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [self.textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];
}
- (void)updateAgreementURL:(NSURL *)agreementURL privacyURL:(NSURL *)privacyURL {
    self.agreementURL = agreementURL;
    self.privacyURL = privacyURL;
    [self rebuildText];
}

- (void)setChecked:(BOOL)checked {
    _checked = checked;
    self.checkboxButton.selected = checked;
}

- (void)toggle:(UIButton *)sender {
    self.checked = !self.isChecked;
    if (self.onToggle) self.onToggle(self.isChecked);
}

#pragma mark - Build Text

- (void)rebuildText {
    // 文案可按需本地化
    //NSString *prefix = NSLocalizedString(@"我已阅读并同意", @"");
    //NSString *agreement = NSLocalizedString(@"《用户协议》", @"");
    //NSString *mid = NSLocalizedString(@"和", @"");
    //NSString *privacy = NSLocalizedString(@"《隐私政策》", @"");

    //"" = "点击即表示你已阅读并同意《会员服务协议》 《隐私政策》";
    //"Membership Service Terms" = "《会员服务协议》";
    //"[Privacy Policy]" = "《隐私政策》";
    //NSString *agreement = NSLocalizedString(@"Membership Service Terms", @"");
    //NSString *privacy = NSLocalizedString(@"[Privacy Policy]", @"");
    NSString *agreement = NSLocalizedString(@"Membership Terms", @"");
    NSString *privacy = NSLocalizedString(@"Privacy Policy", @"");
    
    NSString *full = NSLocalizedString(@"By checking this box, you agree to the Membership Terms and Privacy Policy.", @"");
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:full];
    UIColor *gray = [self colorWithHexString:@"#9DABC2" alpha:1];
    [attr addAttribute:NSForegroundColorAttributeName value:gray range:NSMakeRange(0, full.length)];
    self.textView.font= [UIFont fontWithName:FONT_NAME_Regular size:14];
    // 为关键词添加链接属性
    NSRange agreementRange = [full rangeOfString:agreement];
    NSRange privacyRange = [full rangeOfString:privacy options:NSBackwardsSearch];

    if (agreementRange.location != NSNotFound && self.agreementURL) {
        [attr addAttribute:NSLinkAttributeName value:self.agreementURL range:agreementRange];
    }
    if (privacyRange.location != NSNotFound && self.privacyURL) {
        [attr addAttribute:NSLinkAttributeName value:self.privacyURL range:privacyRange];
    }

    self.textView.attributedText = attr.copy;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction API_AVAILABLE(ios(10.0)) {
    /*if (self.onTapLink) {
        self.onTapLink(URL);
        return NO; // 交给外部处理
    }
    // 默认：直接打开外链
    if (@available(iOS 10.0, *)) {
        [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:URL];
    }
    return NO;*/
    
    NSString *linkName = nil;
       if ([URL.absoluteString isEqualToString:self.agreementURL.absoluteString]) {
           linkName = @"会员服务协议";
       } else if ([URL.absoluteString isEqualToString:self.privacyURL.absoluteString]) {
           linkName = @"隐私政策";
       }
       if (linkName) {
           self.onTapLinkName(linkName);
       }
       return NO;
}
- (void)markAsChecked {
    self.checked = YES;
    if (self.onToggle) {
        self.onToggle(self.checked);
    }
}
- (void)markAsUnchecked {
    self.checked = NO;
    if (self.onToggle) {
        self.onToggle(self.checked);
    }
}

// 新增方法：隐藏勾选按钮，并让文字左右边距各 28
- (void)hideCheckboxAndAdjustTextMargins {
    self.checkboxButton.hidden = YES;
    [NSLayoutConstraint deactivateConstraints:self.textView.constraints];
    [NSLayoutConstraint activateConstraints:@[
        [self.textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:28],
        [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-28],
    ]];
}
@end
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

