//
//  UIViewController+UMTrack.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/14.
//

#import "UIViewController+UMTrack.h"
#import <objc/runtime.h>
#import "UMAnalyticsManager.h"
@implementation UIViewController (UMTrack)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 交换 viewWillAppear:
        Method originalAppear = class_getInstanceMethod(self, @selector(viewWillAppear:));
        Method swizzledAppear = class_getInstanceMethod(self, @selector(um_viewWillAppear:));
        method_exchangeImplementations(originalAppear, swizzledAppear);
        
        // 交换 viewWillDisappear:
        Method originalDisappear = class_getInstanceMethod(self, @selector(viewWillDisappear:));
        Method swizzledDisappear = class_getInstanceMethod(self, @selector(um_viewWillDisappear:));
        method_exchangeImplementations(originalDisappear, swizzledDisappear);
    });
}

#pragma mark - Swizzled Methods

- (void)um_viewWillAppear:(BOOL)animated {
    [self um_viewWillAppear:animated]; // 调用原来的方法
    NSString *pageName = NSStringFromClass([self class]);
    [[UMAnalyticsManager sharedManager] trackPageBegin:pageName];
}

- (void)um_viewWillDisappear:(BOOL)animated {
    [self um_viewWillDisappear:animated]; // 调用原来的方法
    NSString *pageName = NSStringFromClass([self class]);
    [[UMAnalyticsManager sharedManager] trackPageEnd:pageName];

    /*NSString *pageName2 = NSStringFromClass([self class]);
    if ([self isKindOfClass:[UINavigationController class]] ||
        [self isKindOfClass:[UITabBarController class]] ||
        [self isKindOfClass:[UIAlertController class]]) {
        return;
    }
    [[UMAnalyticsManager sharedManager] trackPageBegin:pageName2];*/
}

@end
