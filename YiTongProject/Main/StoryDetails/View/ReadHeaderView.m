//
//  ReadHeaderView.m
//  YiTongProject
//
//  Created by ios01 on 2025/11/4.
//

#import "ReadHeaderView.h"

#import "VideoFullScreenViewController.h"
@interface ReadHeaderView(){
    VideoPlayerView *_videoPlayerView;
}


@end
@implementation ReadHeaderView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.clipsToBounds = YES;
        [self setupViews];
        [self setupVideoPlayer];   //
    }
    return self;
}
- (void)setupViews {
    self.headerImageView = [[UIImageView alloc] init];
    self.headerImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.headerImageView.clipsToBounds = YES;
    [self addSubview:self.headerImageView];
    [self.headerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(200); // 初始占位高度
    }];
}
- (void)setupVideoPlayer {
    _videoPlayerView = [[VideoPlayerView alloc] init];
    [self addSubview:_videoPlayerView];

    CGFloat height = SCREEN_WIDTH * (168.0 / 298.0);
    [_videoPlayerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerImageView.mas_bottom);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(height);
    }];

    __weak typeof(self) weakSelf = self;
    _videoPlayerView.enterFullScreenBlock = ^(AVPlayer *player) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;

        [KUSER_DEFAULT setObject:@"Video" forKey:Card_Type];
        VideoFullScreenViewController *vc = [[VideoFullScreenViewController alloc] init];
        vc.player = player;
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.uvc presentViewController:vc animated:YES completion:nil];
    };
}
- (VideoPlayerView *)setupVideoIfVideoUrl:(NSString *)videoUrl {
    if (videoUrl.length == 0) {
        [_videoPlayerView stopVideo];
        _videoPlayerView.hidden = YES;
        return nil;
    }
    NSLog(@"videoUrl--------[%@]---------------",videoUrl); //https://testoss.shiyi-yitong.com/story/myth/videos/nvwa.mp4
    _videoPlayerView.hidden = NO;
    [_videoPlayerView setVideoURL:[NSURL URLWithString:videoUrl]];
    return _videoPlayerView;
}
/*- (VideoPlayerView *)setupVideoIfVideoUrl:(NSString *)videoUrl {
    VideoPlayerView *playerView = [[VideoPlayerView alloc] init];
    [self addSubview:playerView];

    CGFloat height = SCREEN_WIDTH * (168.0/298.0);//宽高等比例
    BOOL hasVideo = YES;
    [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerImageView.mas_bottom);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(height * hasVideo);
    }];
    [playerView setVideoURL:[NSURL URLWithString:videoUrl]];
    // 点击播放视频

    // 全屏回调
    playerView.enterFullScreenBlock = ^(AVPlayer *player) {
        [KUSER_DEFAULT setObject:@"Video" forKey:Card_Type];
        VideoFullScreenViewController *vc = [[VideoFullScreenViewController alloc] init];
        vc.player = player;
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.uvc presentViewController:vc animated:YES completion:nil];
    };
    // 监听关闭音频的通知
    return playerView;
}*/

- (void)loadTopImageWithURL:(NSString *)urlString hasVideo:(BOOL)hasVideo {//header image 加载图片
    __weak typeof(self) weakSelf = self;
    UIViewController *vc = [self parentViewController];
    if (vc) {
        [MBProgressHUD showHUDAddedTo:vc.view animated:YES];
    }
    // 额外高度（比如视频区域高度）
    CGFloat height = SCREEN_WIDTH * (168.0/298.0) * hasVideo;
    if (urlString.length == 0) {
        if (vc) {
            [MBProgressHUD hideHUDForView:vc.view animated:YES];
        }
          // headerView 高度至少为 1，防止 tableHeaderView 塌陷
        CGFloat tempHeight = (CGRectGetHeight(self.bounds) == 108.0) ? 108.0 : 1.0;
        [weakSelf mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(SCREEN_WIDTH);
            make.height.mas_equalTo((tempHeight + height));
        }];
        // 更新 headerImageView 高度
        [weakSelf.headerImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.equalTo(weakSelf);
            make.height.mas_equalTo(tempHeight);
        }];
        
        self.headerImageView.alpha = 0.0;
        [self layoutIfNeeded];
        UITableView *tableView = [self parentTableView];
        tableView.tableHeaderView = self; // 重新赋值刷新 header 高度
        return;
      }
    //===========================================
    [self.headerImageView sd_setImageWithURL:[NSURL URLWithString:urlString]
                            placeholderImage:nil
                                     options:0
                                   completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (vc) {
            [MBProgressHUD hideHUDForView:vc.view animated:YES];
        }
        if (image) {
            weakSelf.headerImageView.alpha = 1.0;
            CGFloat screenWidth = SCREEN_WIDTH;
            CGFloat ratio = image.size.height / image.size.width; // 图片宽高比
            CGFloat imageHeight = screenWidth * ratio; // 按屏幕宽等比例计算图片高度
            // 更新 headerView 高度
            [weakSelf mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.mas_equalTo(SCREEN_WIDTH);
                make.height.mas_equalTo((imageHeight + height));
            }];
            // 更新 headerImageView 高度
            [weakSelf.headerImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.left.right.equalTo(weakSelf);
                make.height.mas_equalTo(imageHeight);
            }];
            // 如果 headerView 在 UITableView 里，刷新 headerView
            [weakSelf layoutIfNeeded]; // 强制布局更新
            UITableView *tableView = [self parentTableView];
            tableView.tableHeaderView = self; // 重新赋值以更新高度
        }
    }];
}
- (UITableView *)parentTableView {
    UIView *view = self.superview;
    while (view && ![view isKindOfClass:[UITableView class]]) {
        view = view.superview;
    }
    return (UITableView *)view;
}
- (UIViewController *)parentViewController {
    UIResponder *responder = self;
    while (responder) {
        responder = responder.nextResponder;
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
