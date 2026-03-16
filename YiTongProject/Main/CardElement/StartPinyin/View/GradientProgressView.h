//
//  GradientProgressView.h
//  YiTongProject
//
//  Created by ios01 on 2025/7/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GradientProgressView : UIView
@property (nonatomic, assign) CGFloat progress;
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated color:(NSArray *)colors;
- (void)setColorProgress:(CGFloat)progress color:(NSString *)color alpha:(float)alpha animated:(BOOL)animated;

- (void)addDashedBorderWithColor:(UIColor *)color
                       lineWidth:(CGFloat)lineWidth
                     dashPattern:(NSArray<NSNumber *> *)dashPattern
                     cornerRadius:(CGFloat)cornerRadius;

@end

NS_ASSUME_NONNULL_END
