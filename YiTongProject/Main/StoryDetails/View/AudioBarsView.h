//
//  AudioBarsView.h
//  YiTongProject
//
//  Created by ios01 on 2025/11/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioBarsView : UIView
// 设置柱子颜色
@property (nonatomic, strong) UIColor *barColor;

// 开始动画
- (void)startAnimating;

// 停止动画并固定形状
- (void)stopAnimatingWithHeights:(NSArray *)heights ;

// 更改柱子颜色
- (void)changeBarColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
