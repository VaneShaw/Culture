//
//  YTVFeedCoordinator.m
//  YiTongProject
//

#import "YTVFeedCoordinator.h"
#import "YTVVideoDeepLinkRouter.h"
#import "VideoTabViewController.h"
#import "HeaderConfig.h"

@implementation YTVFeedCoordinator

+ (instancetype)sharedCoordinator {
    static YTVFeedCoordinator *inst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[YTVFeedCoordinator alloc] init];
    });
    return inst;
}

- (void)routeVideoDeepLinkFromURL:(NSURL *)url {
    YTVVideoDeepLinkRouter *router = [YTVVideoDeepLinkRouter ytv_routerParsingURL:url];
    if (router.videoId.length == 0) {
        return;
    }
    void (^work)(void) = ^{
        UITabBarController *tab = theAppDelegate.tabBarController_startApp;
        if (![tab isKindOfClass:[UITabBarController class]]) {
            return;
        }
        NSInteger n = (NSInteger)tab.viewControllers.count;
        if (kYTVVideoTabBarIndex < 0 || kYTVVideoTabBarIndex >= n) {
            return;
        }
        tab.selectedIndex = kYTVVideoTabBarIndex;
        UIViewController *selected = tab.selectedViewController;
        if (![selected isKindOfClass:[UINavigationController class]]) {
            return;
        }
        UINavigationController *nc = (UINavigationController *)selected;
        [nc popToRootViewControllerAnimated:NO];
        UIViewController *root = nc.viewControllers.firstObject;
        if (![root isKindOfClass:[VideoTabViewController class]]) {
            return;
        }
        [(VideoTabViewController *)root ytv_openDeepLinkWithVideoId:router.videoId categoryKey:router.categoryKey];
    };
    if ([NSThread isMainThread]) {
        work();
    } else {
        dispatch_async(dispatch_get_main_queue(), work);
    }
}

@end
