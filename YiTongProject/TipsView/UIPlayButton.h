//
//  UIPlayButton.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIPlayButton : UIControl

@property (nonatomic, strong) UIImage *normalImage;
@property (nonatomic, strong) UIImage *playingImage;

- (instancetype)initWithFrame:(CGRect)frame
                 backgroundImage:(UIImage *)bgImage
                     normalImage:(UIImage *)normalImage
                    playingImage:(UIImage *)playingImage;

// 外部控制播放状态
- (void)startPlaying;
- (void)stopPlaying;

- (void)startCellPlaying;
- (void)stopCellPlaying;

// 当前是否在播放
@property (nonatomic, assign, readonly) BOOL isPlaying;

// 动画速度（数值越大越慢，默认 0.8 秒）
@property (nonatomic, assign) CGFloat animationDuration;

@end

NS_ASSUME_NONNULL_END
