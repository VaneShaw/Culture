//
//  AnimatedImageView.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/22.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
NS_ASSUME_NONNULL_BEGIN

@interface AnimatedImageView : UIImageView
// 开启旋转动画
- (void)startAnimation;

// 停止旋转动画
- (void)stopAnimation;
// 设置音频级别 (0.0 - 1.0)
- (void)setAudioLevel:(CGFloat)level;
@end

NS_ASSUME_NONNULL_END
