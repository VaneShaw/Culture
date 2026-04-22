//
//  YTVVideoRenderView.m
//  YiTongProject
//

#import "YTVVideoRenderView.h"
#import <AVFoundation/AVFoundation.h>

@implementation YTVVideoRenderView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)self.layer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.backgroundColor = [UIColor blackColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.backgroundColor = [UIColor blackColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)attachPlayer:(AVPlayer *)player {
    self.playerLayer.player = player;
    if (!player) {
        /// `AVPlayerLayer` 解除 player 后可能仍短暂保留上一帧，这里显式清空，避免切源时旧画面闪回。
        self.playerLayer.contents = nil;
    }
}

@end
