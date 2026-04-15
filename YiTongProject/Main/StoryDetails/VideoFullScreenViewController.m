//
//  VideoFullScreenViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/2.
//

#import "VideoFullScreenViewController.h"

@interface VideoFullScreenViewController ()
@property (nonatomic, strong) AVPlayerViewController *playerVC;

@end

@implementation VideoFullScreenViewController
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.player) {
        [self.player play];   // 进入全屏后立即播放
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isBeingDismissed) {
        [KUSER_DEFAULT setBool:NO forKey:@"isFullScreen"];
        void (^cb)(void) = self.onWillDismiss;
        if (cb) {
            // 下一帧再滚外层 ScrollView，避免与转场动画抢同一帧布局
            dispatch_async(dispatch_get_main_queue(), ^{
                cb();
            });
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.pageId = @"video_full_screen"; //1神话 0 成语
    self.view.backgroundColor = [UIColor blackColor];
    [KUSER_DEFAULT setBool:YES forKey:@"isFullScreen"];

    // 用 AVPlayerViewController 来全屏
    self.playerVC = [[AVPlayerViewController alloc] init];
    self.playerVC.player = self.player;
    self.playerVC.view.frame = self.view.bounds;
    self.playerVC.showsPlaybackControls = YES;
    [self addChildViewController:self.playerVC];
    [self.view addSubview:self.playerVC.view];
    [self.playerVC didMoveToParentViewController:self];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.playerVC.view.frame = self.view.bounds;
}

- (void)exitFullScreen {
    [self.player pause];  // 停止播放
    [self dismissViewControllerAnimated:YES completion:nil];
    //self.selectedTypeIndex(101);
}
#pragma mark - 横屏控制
- (BOOL)shouldAutorotate {
    return YES;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape; // 只允许横屏
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
