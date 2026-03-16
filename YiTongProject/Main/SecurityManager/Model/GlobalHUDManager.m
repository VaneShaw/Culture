//
//  GlobalHUDManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/19.
//

#import "GlobalHUDManager.h"


#import <MBProgressHUD/MBProgressHUD.h>
#import <UIKit/UIKit.h>

@interface GlobalHUDManager ()

@property (nonatomic, strong) NSMutableSet<MBProgressHUD *> *hudSet;
@property (nonatomic, strong) dispatch_source_t timeoutTimer;

@end

@implementation GlobalHUDManager

+ (instancetype)shared {
    static GlobalHUDManager *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        m = [[GlobalHUDManager alloc] init];
    });
    return m;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hudSet = [NSMutableSet set];
        [self setupObservers];
    }
    return self;
}
- (UIWindow *)stableWindow {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    }
    return UIApplication.sharedApplication.keyWindow;
}
- (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [self stableWindow];
        if (!window) return;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.userInteractionEnabled = NO; // 不锁死交互

        [self.hudSet addObject:hud];
        [self startTimeout];
    });
}
- (void)hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cancelTimeout];
        for (MBProgressHUD *hud in self.hudSet) {
            [hud hideAnimated:YES];
        }
        [self.hudSet removeAllObjects];
    });
}
- (void)forceHideAll {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self cancelTimeout];
        // 1️⃣ 干掉管理的
        for (MBProgressHUD *hud in self.hudSet) {
            [hud hideAnimated:YES];
        }
        [self.hudSet removeAllObjects];
        // 2️⃣ 扫所有 window（兜底）
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            [MBProgressHUD hideHUDForView:window animated:YES];
        }
    });
    
}
- (void)startTimeout {
    
    [self cancelTimeout];
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.timeoutTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(self.timeoutTimer,
                              dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC),
                              DISPATCH_TIME_FOREVER,
                              1 * NSEC_PER_SEC);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.timeoutTimer, ^{
        [weakSelf onTimeout];
    });
    dispatch_resume(self.timeoutTimer);
    
}

- (void)showOrUpdateMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.hudSet.count > 0) {
            // 已有 HUD → 更新文案
            for (MBProgressHUD *hud in self.hudSet) {
                hud.label.text = NSLocalizedString(message, @"");
            }
            return;
        }

        // 没有 HUD → 新建
        UIWindow *window = [self stableWindow];
        if (!window) return;

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.userInteractionEnabled = NO;
        hud.label.text = NSLocalizedString(message ?: @"处理中...", @"");
        [self.hudSet addObject:hud];
        [self startTimeout];
    });
}
- (void)cancelTimeout {
    if (self.timeoutTimer) {
        dispatch_source_cancel(self.timeoutTimer);
        self.timeoutTimer = nil;
    }
}
- (void)onTimeout {
    [self forceHideAll];
}
- (void)setupObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(forceHideAll)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}
@end
