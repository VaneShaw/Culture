//
//  GradientLabel.h
//  YiTongProject
//
//  Created by ios01 on 2025/11/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GradientLabel : UILabel

/// 设置三色渐变（colors 数组长度应为 3）；locations 可选，默认 @[@0.0,@0.5,@1.0]
- (void)setGradientColors:(NSArray<UIColor *> *)colors locations:(nullable NSArray<NSNumber *> *)locations;

@end

NS_ASSUME_NONNULL_END
