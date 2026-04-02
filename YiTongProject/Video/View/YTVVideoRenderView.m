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
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)attachPlayer:(AVPlayer *)player {
    self.playerLayer.player = player;
}

@end
