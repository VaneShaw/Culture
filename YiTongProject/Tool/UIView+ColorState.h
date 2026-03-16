//
//  UIView+ColorState.h
//  
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import <UIKit/UIKit.h>

@interface UIView (ColorState)

/*
 *状态提醒
 */
- (void)makeToast:(NSString *)message;
- (void)makeToastWithoutKeyboard:(NSString *)message;

/*
 *色值转换
 */
- (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha ;
/*
 *输入框输入光标右移
 */
- (void)setTextFieldLeftPadding:(UITextField *)textField forWidth:(CGFloat)leftWidth;
/*
 *渐变色
 */
- (UIColor *)gradientColorWithSize:(CGSize)size colors:(NSArray<UIColor *> *)colors;
/*
 *画虚线
 */
- (void)drawDashLine:(UIView *)lineView lineLength:(int)lineLength lineSpacing:(int)lineSpacing lineColor:(UIColor *)lineColor;
/*
 *获取的字符串格式日期时间。只截取日期
 */
//年月日
- (NSString *)getDate:(NSString *)dateString;
//年月日 时分
- (NSString *)getDateAndTime:(NSString *)dateString;
//时分
- (NSString *)getTime:(NSString *)dateString;
/*
 *base64加密
 */
- (NSString *)base64String:(NSString*)sourceString;
/*
 *base64解密
 */
- (NSString*)encodeBase64String:(NSString*)baseString;

//无数据时空图
- (UIView *)addEmptyDataViewFrame:(CGRect)frame title:(NSString *)title viewY:(int)y;
//深色模式or浅色模式
- (UIColor *)colorWithDarkModeColor:(UIColor *)darkColor normalColor:(UIColor *)color;
//改变图标的颜色
//- (UIImage *)imageWithImageName:(NSString *)name imageColor:(UIColor *)imageColor;

//转化成二维码
- (UIImage *)generateQRCodeWithString:(NSString *)string Size:(CGFloat)size;

//获取当前日期年月日
- (NSDateComponents *) getCurrentData ;

- (UIImage *)imageFromColor:(UIColor *)color;

- (NSString *)setKeyboardTypeDecimalPad:(NSString *)txtField;

-(CAGradientLayer *)setChangColorWithView:(UIView *)view andColorStart:(UIColor *)startColor andEndColor:(UIColor *)endColor;

/*
 *6-16位 随机字符串
 */
- (NSString *)randomString;

//图片改颜色
- (UIImage *)imageWithImageName:(NSString *)name tintColor:(UIColor *)tintColor;//

- (UIView *)addBackgroundWithColor:(UIColor *)color
                           view:( UIView *)backgroundView
                           padding:(CGFloat)padding
                      cornerRadius:(CGFloat)cornerRadius;
//让view 有 弹性动画效果
- (void)addElasticAnimationWithDuration:(NSTimeInterval)duration;
//圆形边框有播放动画效果
- (void)setupMultiPulseAnimationForView:(UIView *)view;
- (UIImage *)gradientImageWithSize:(CGSize)size colors:(NSArray<UIColor *> *)colors;

@end
