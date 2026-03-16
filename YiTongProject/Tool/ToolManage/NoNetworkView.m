//
//  NoNetworkView.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/18.
//

#import "NoNetworkView.h"
//无网络或者首次 用户不授权使用网络的 展示的页面
@implementation NoNetworkView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
        // 图标
        UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"wifi.slash"]];
        iconView.tintColor = [UIColor lightGrayColor];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:iconView];

        // 提示语
        UILabel *label = [[UILabel alloc] init];
        //label.text = NSLocalizedString(@"网络未开启，请检查Wi-Fi或蜂窝数据设置",@"")
        label.text = NSLocalizedString(@"Network is unavailable. Please check your Wi-Fi or cellular data settings.",@"");

        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor darkGrayColor];
        label.font = [UIFont systemFontOfSize:14];
        label.numberOfLines = 0;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:label];

        // 刷新按钮
        UIButton *refreshBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [refreshBtn setTitle:NSLocalizedString(@"Refresh",@"") forState:UIControlStateNormal];
        refreshBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        refreshBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [refreshBtn addTarget:self action:@selector(didTapRefresh) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:refreshBtn];

        // 去设置按钮
        UIButton *settingsBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [settingsBtn setTitle:NSLocalizedString(@"Go to Settings",@"") forState:UIControlStateNormal];
        settingsBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        settingsBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [settingsBtn addTarget:self action:@selector(didTapSettings) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:settingsBtn];
        self.settingsBtn = settingsBtn;
    
       
        // 自动布局
        [NSLayoutConstraint activateConstraints:@[
            [iconView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:-90],
            [iconView.widthAnchor constraintEqualToConstant:60],
            [iconView.heightAnchor constraintEqualToConstant:60],

            [label.topAnchor constraintEqualToAnchor:iconView.bottomAnchor constant:20],
            [label.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [label.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:0.8],

            [refreshBtn.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:20],
            [refreshBtn.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],

            [settingsBtn.topAnchor constraintEqualToAnchor:refreshBtn.bottomAnchor constant:15],
            [settingsBtn.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        ]];
    }
    return self;
}

- (void)didTapRefresh {
    if (self.refreshHandler) {
        self.refreshHandler();
    }
}

- (void)didTapSettings {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
