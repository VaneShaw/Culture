//
//  YTTabBarController.m
//  YiTongProject
//

#import "YTTabBarController.h"
#import "AppDelegate.h"

@implementation YTTabBarController

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    [super setSelectedIndex:selectedIndex];
    [self ytb_notifyAppDelegateApplyTabBarStyle];
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController {
    [super setSelectedViewController:selectedViewController];
    [self ytb_notifyAppDelegateApplyTabBarStyle];
}

- (void)ytb_notifyAppDelegateApplyTabBarStyle {
    id delegate = [UIApplication sharedApplication].delegate;
    if ([delegate isKindOfClass:[AppDelegate class]]) {
        [(AppDelegate *)delegate ytb_applyTabBarAppearanceForTabBarController:self];
    }
}

@end
