//
//  UIView+ColorState.m
//
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "UIView+ColorState.h"


static const CGFloat CSToastDefaultDuration = 3.0;
static const NSString * CSToastDefaultPosition  = @"bottom";

static const CGFloat CSToastCornerRadius        = 10.0;
static const CGFloat CSToastOpacity             = 0.8;
static const CGFloat CSToastVerticalPadding     = 10.0;
static const CGFloat CSToastFontSize            = 16.0;
static const CGFloat CSToastMaxTitleLines       = 0;
//static const CGFloat CSToastMaxWidth            = 0.8;      // 80% of parent view width
static const CGFloat CSToastMaxHeight           = 0.8;      // 80% of parent view height
static const CGFloat CSToastMaxMessageLines     = 0;
static const CGFloat CSToastHorizontalPadding   = 10.0;
static const CGFloat CSToastFadeDuration        = 0.2;

@implementation UIView (ColorState)
/*
*状态提醒
*/
- (void)makeToast:(NSString *)message {
    [self makeToast:message duration:CSToastDefaultDuration position:CSToastDefaultPosition];
}

- (void)makeToastWithoutKeyboard:(NSString *)message;{
    UIView *toast = [self viewForMessage:message title:nil image:nil];
    [self showToast:toast duration:CSToastDefaultDuration position:CSToastDefaultPosition withKeyboard:NO];
}
- (void)makeToast:(NSString *)message duration:(CGFloat)interval position:(id)position {
    UIView *toast = [self viewForMessage:message title:nil image:nil];
    [self showToast:toast duration:interval position:position withKeyboard:YES];
}
- (void)showToast:(UIView *)toast duration:(CGFloat)interval position:(id)point withKeyboard:(BOOL)with{
    toast.center = [self centerPointForPosition:point withToast:toast withKeyboard:with];
    toast.alpha = 0.0;
  
    [self addSubview:toast];
    //[[UIApplication sharedApplication].keyWindow addSubview:toast]; //最外层的view
    [UIView animateWithDuration:CSToastFadeDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         toast.alpha = 1.0;
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:CSToastFadeDuration
                                               delay:interval
                                             options:UIViewAnimationOptionCurveEaseIn
                                          animations:^{
                                              toast.alpha = 0.0;
                                          } completion:^(BOOL finished) {
                                              [toast removeFromSuperview];
                                          }];
                     }];
}
#pragma mark - Private Methods
- (CGPoint)centerPointForPosition:(id)point withToast:(UIView *)toast withKeyboard:(BOOL)with{
    if([point isKindOfClass:[NSString class]]) {
        // convert string literals @"top", @"bottom", @"center", or any point wrapped in an NSValue object into a CGPoint
        //bottom
        if([point caseInsensitiveCompare:@"top"] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width/2, (toast.frame.size.height / 2) + CSToastVerticalPadding);
        } else if([point caseInsensitiveCompare:@"bottom"] == NSOrderedSame) {
            int height = 44;//往上调整0
            //if (with) {
            //height =  (int)[[NSUserDefaults standardUserDefaults] integerForKey:KEYBORD_HEIGHT];
            //}
            return CGPointMake(self.bounds.size.width/2, (self.bounds.size.height - (toast.frame.size.height / 2)) - CSToastVerticalPadding - height);
        } else if([point caseInsensitiveCompare:@"center"] == NSOrderedSame) {
            return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
        }
    } else if ([point isKindOfClass:[NSValue class]]) {
        return [point CGPointValue];
    }
    
    NSLog(@"----Warning: Invalid position for toast.-----------");
    return [self centerPointForPosition:CSToastDefaultPosition withToast:toast withKeyboard:with];
}
- (UIView *)viewForMessage:(NSString *)message title:(NSString *)title image:(UIImage *)image {
    // sanity
    if((message == nil) && (title == nil) && (image == nil)) return nil;
    
    // dynamically build a toast view with any combination of message, title, & image.
    UILabel *messageLabel = nil;
    UILabel *titleLabel = nil;
    //UIImageView *imageView = nil;
    
    // create the parent view
    UIView *wrapperView = [UIView new];
    
    wrapperView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
    wrapperView.layer.cornerRadius = CSToastCornerRadius;
    //[UIColor blackColor];
    wrapperView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:CSToastOpacity];
    //wrapperView.backgroundColor = [UIColor orangeColor];//x
    CGFloat imageWidth, imageHeight, imageLeft;
    
    imageWidth = imageHeight = imageLeft = 0.0;
    // the imageView frame values will be used to size & position the other views
    
    if (title != nil) {
        titleLabel = [UILabel new];
        titleLabel.numberOfLines = CSToastMaxTitleLines;
        titleLabel.font = [UIFont boldSystemFontOfSize:CSToastFontSize];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.alpha = 1.0;
        titleLabel.text = title;
        
        // size the title label according to the length of the text
        //改动
        //CGSize maxSizeTitle = CGSizeMake((self.bounds.size.width * CSToastMaxWidth) - imageWidth, self.bounds.size.height * CSToastMaxHeight);
        //CGSize expectedSizeTitle = [title sizeWithFont:titleLabel.font constrainedToSize:maxSizeTitle lineBreakMode:titleLabel.lineBreakMode];
        CGSize expectedSizeTitle = [titleLabel sizeThatFits:CGSizeMake(MAXFLOAT,self.bounds.size.height * CSToastMaxHeight)];
        
        titleLabel.frame = CGRectMake(0.0, 0.0, expectedSizeTitle.width, expectedSizeTitle.height);
    }
    
    if (message != nil) {
        messageLabel = [UILabel new];
        messageLabel.numberOfLines = CSToastMaxMessageLines;
        messageLabel.font = [UIFont systemFontOfSize:CSToastFontSize];
        messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        messageLabel.textColor = [UIColor whiteColor];
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.alpha = 1.0;
        messageLabel.text = message;
        
        CGSize expectedSizeMessage = [messageLabel sizeThatFits:CGSizeMake(MAXFLOAT,self.bounds.size.height * CSToastMaxHeight)];
        messageLabel.frame = CGRectMake(0.0, 0.0, expectedSizeMessage.width, expectedSizeMessage.height);
    }
    
    // titleLabel frame values
    CGFloat titleWidth, titleHeight, titleTop, titleLeft;
    if(titleLabel != nil) {
        titleWidth = titleLabel.bounds.size.width;
        titleHeight = titleLabel.bounds.size.height;
        titleTop = CSToastVerticalPadding;
        titleLeft = imageLeft + imageWidth + CSToastHorizontalPadding;
    } else {
        titleWidth = titleHeight = titleTop = titleLeft = 0.0;
    }
    
    // messageLabel frame values
    CGFloat messageWidth, messageHeight, messageLeft, messageTop;
    if(messageLabel != nil) {
        messageWidth = messageLabel.bounds.size.width;
        messageHeight = messageLabel.bounds.size.height;
        messageLeft = imageLeft + imageWidth + CSToastHorizontalPadding;
        messageTop = titleTop + titleHeight + CSToastVerticalPadding;
    } else {
        messageWidth = messageHeight = messageLeft = messageTop = 0.0;
    }
    CGFloat longerWidth = MAX(titleWidth, messageWidth);
    CGFloat longerLeft = MAX(titleLeft, messageLeft);
    
    // wrapper width uses the longerWidth or the image width, whatever is larger. same logic applies to the wrapper height
    CGFloat wrapperWidth = MAX((imageWidth + (CSToastHorizontalPadding * 2)), (longerLeft + longerWidth + CSToastHorizontalPadding));
    CGFloat wrapperHeight = MAX((messageTop + messageHeight + CSToastVerticalPadding), (imageHeight + (CSToastVerticalPadding * 2)));
    
    wrapperView.frame = CGRectMake(0.0, 0.0, wrapperWidth, wrapperHeight);
    if(titleLabel != nil) {
        titleLabel.frame = CGRectMake(titleLeft, titleTop, titleWidth, titleHeight);
        [wrapperView addSubview:titleLabel];
    }
    
    if(messageLabel != nil) {
        messageLabel.frame = CGRectMake(messageLeft, messageTop, messageWidth, messageHeight);
        [wrapperView addSubview:messageLabel];
    }
    return wrapperView;
}
//输入框输入光标右移
- (void)setTextFieldLeftPadding:(UITextField *)textField forWidth:(CGFloat)leftWidth {
    CGRect frame = textField.frame;
    frame.size.width = leftWidth;
    UIView *leftview = [[UIView alloc] initWithFrame:frame];
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.leftView = leftview;
}
//色值转换
- (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha {
    //删除字符串中的空格
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    // strip 0X if it appears
    //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"]) {
        cString = [cString substringFromIndex:2];
    }
    //如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
    if ([cString hasPrefix:@"#"]) {
        cString = [cString substringFromIndex:1];
    }
    if ([cString length] != 6) {
        return [UIColor clearColor];
    }
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:alpha];
}

//画虚线
- (void)drawDashLine:(UIView *)lineView lineLength:(int)lineLength lineSpacing:(int)lineSpacing lineColor:(UIColor *)lineColor
{
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    [shapeLayer setBounds:lineView.bounds];
    [shapeLayer setPosition:CGPointMake(CGRectGetWidth(lineView.frame) / 2, CGRectGetHeight(lineView.frame))];
    [shapeLayer setFillColor:[UIColor clearColor].CGColor];
    //  设置虚线颜色为blackColor
    [shapeLayer setStrokeColor:lineColor.CGColor];
    //  设置虚线宽度
    [shapeLayer setLineWidth:CGRectGetHeight(lineView.frame)];
    [shapeLayer setLineJoin:kCALineJoinRound];
    //  设置线宽，线间距
    [shapeLayer setLineDashPattern:[NSArray arrayWithObjects:[NSNumber numberWithInt:lineLength], [NSNumber numberWithInt:lineSpacing], nil]];
    //  设置路径
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, 0);
    CGPathAddLineToPoint(path, NULL, CGRectGetWidth(lineView.frame), 0);
    [shapeLayer setPath:path];
    CGPathRelease(path);
    //  把绘制好的虚线添加上来
    [lineView.layer addSublayer:shapeLayer];
}

- (NSString *)getDate:(NSString *)dateString {
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init] ;
    [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [inputFormatter dateFromString:dateString];
    
    NSDateFormatter *format1=[[NSDateFormatter alloc] init];
    [format1 setDateFormat:@"yyyy-MM-dd"];
    NSString *dateStr =[format1 stringFromDate:date];
    return dateStr;
}
- (NSString *)getDateAndTime:(NSString *)dateString {
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init] ;
    [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [inputFormatter dateFromString:dateString];
    
    NSDateFormatter *format1=[[NSDateFormatter alloc] init];
    [format1 setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSString *dateStr =[format1 stringFromDate:date];
    return dateStr;
}
- (NSString *)getTime:(NSString *)dateString {
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init] ;
    [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [inputFormatter dateFromString:dateString];
    
    NSDateFormatter *format1=[[NSDateFormatter alloc] init];
    [format1 setDateFormat:@"HH:mm"];
    NSString *dateStr =[format1 stringFromDate:date];
    return dateStr;
}

//base64加密
- (NSString *)base64String:(NSString*)sourceString {
    if (sourceString.length <=0) {//判断字符串的长度是否小于等于0如果是，就返回空
        return nil;
    }
    //把字符串转化为二进制流
    NSData * sourceData = [[NSData alloc] initWithData:[sourceString dataUsingEncoding:NSUTF8StringEncoding]];
    //把二进制流转化为base64字符串
    NSString * baseString = [sourceData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    return baseString;
}
//base64解密
- (NSString*)encodeBase64String:(NSString*)baseString {
    if (baseString.length <= 0) {
        return  nil;
    }
    NSData * data = [[NSData alloc] initWithBase64EncodedString:baseString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

//无数据时空图
- (UIView *)addEmptyDataViewFrame:(CGRect)frame title:(NSString *)title viewY:(int)y{
    UIView *emptyDataView = [[UIView alloc]initWithFrame:frame];
    emptyDataView.backgroundColor = [UIColor clearColor];
    UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH - 180)/2, y, 180, 150)];
    imgView.image = [UIImage imageNamed:@"no_data.png"];
    [emptyDataView addSubview:imgView];
    
    UILabel *lblEmptyData = [[UILabel alloc]initWithFrame:CGRectMake(0,y + 150 + 10, SCREEN_WIDTH, 20)];
    lblEmptyData.textAlignment = NSTextAlignmentCenter;
    lblEmptyData.font = [UIFont fontWithName:FONT_NAME_Semibold size:14];
    lblEmptyData.textColor = [self colorWithHexString:@"#D4D4D4" alpha:1];
    lblEmptyData.text = title;
    [emptyDataView addSubview:lblEmptyData];
    
    return emptyDataView;
}
//深色模式 or 浅色模式
- (UIColor *)colorWithDarkModeColor:(UIColor *)darkColor normalColor:(UIColor *)color {
    if (@available(iOS 13.0,*)) {
        UIColor *dyColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull trainCollection) {
            if ([trainCollection userInterfaceStyle] == UIUserInterfaceStyleDark) {
                return darkColor;
            }
            else {
                return color;
            }
        }];
        return dyColor;
    }
    return color;
}
/*
 *改变图标颜色
*/
/*- (UIImage *)imageWithImageName:(NSString *)name imageColor:(UIColor *)imageColor {
        UIImage *image = [UIImage imageNamed:name];;
        UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
        [imageColor setFill];

        CGRect bounds = CGRectMake(0, 0, image.size.width, image.size.height);
        UIRectFill(bounds);

        [image drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
        UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return tintedImage;
}*/

- (UIImage *)generateQRCodeWithString:(NSString *)string Size:(CGFloat)size
{
    //创建过滤器
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    //过滤器恢复默认
    [filter setDefaults];
    //给过滤器添加数据<字符串长度893>
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    [filter setValue:data forKey:@"inputMessage"];
    //获取二维码过滤器生成二维码
    CIImage *image = [filter outputImage];
    UIImage *img = [self createNonInterpolatedUIImageFromCIImage:image WithSize:size];
    return img;
}
- (UIImage *)createNonInterpolatedUIImageFromCIImage:(CIImage *)image WithSize:(CGFloat)size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    //创建bitmap
    size_t width = CGRectGetWidth(extent)*scale;
    size_t height = CGRectGetHeight(extent)*scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    //保存图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}
//获取当前日期年月日
- (NSDateComponents *) getCurrentData {
    NSCalendar *gregorian = [[NSCalendar alloc]
     initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    // 获取当前日期
    NSDate* dt = [NSDate date];
    // 定义一个时间字段的旗标，指定将会获取指定年、月、日、时、分、秒的信息
    unsigned unitFlags = NSCalendarUnitYear |
     NSCalendarUnitMonth |  NSCalendarUnitDay |
     NSCalendarUnitHour |  NSCalendarUnitMinute |
     NSCalendarUnitSecond | NSCalendarUnitWeekday;
    // 获取不同时间字段的信息
    NSDateComponents* comp = [gregorian components: unitFlags
     fromDate:dt];
    // 获取各时间字段的数值

    NSLog(@"现在是%ld年" , comp.year);
    NSLog(@"现在是%ld月 " , comp.month);
    NSLog(@"现在是%ld日" , comp.day);
    NSLog(@"现在是%ld时" , comp.hour);
    NSLog(@"现在是%ld分" , comp.minute);
    NSLog(@"现在是%ld秒" , comp.second);
    NSLog(@"现在是星期%ld" , comp.weekday);
    
    return comp;
}
- (UIImage *)imageFromColor:(UIColor *)color {
    
    CGRect rect = CGRectMake(0, 0, 3, 3);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (NSString *)setKeyboardTypeDecimalPad:(NSString *)txtField {
    if([txtField containsString:@","]) {
        txtField = [txtField stringByReplacingOccurrencesOfString:@"," withString:@"."];
    }
    return txtField;
}

/*
 *渐进色
 */
-(CAGradientLayer *)setChangColorWithView:(UIView *)view andColorStart:(UIColor *)startColor andEndColor:(UIColor *)endColor {
    CAGradientLayer *gradLayer = [CAGradientLayer layer];
    gradLayer.frame = view.bounds;
    gradLayer.colors = @[(__bridge id)startColor.CGColor,(__bridge id)endColor.CGColor];
    gradLayer.startPoint = CGPointMake(0.0, 0.0);
    gradLayer.endPoint = CGPointMake(1.0, 0.0);
    return gradLayer;
    return nil;
}

//颜色渐变
- (UIColor *)gradientColorWithSize:(CGSize)size colors:(NSArray<UIColor *> *)colors {
    // 使用更大的固定尺寸以确保图案质量
    CGSize patternSize = CGSizeMake(MAX(size.width, 100), MAX(size.height, 100));
    
    UIGraphicsBeginImageContextWithOptions(patternSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in colors) {
        [cgColors addObject:(id)color.CGColor];
    }
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)cgColors, NULL);
    CGPoint startPoint = CGPointMake(0, 0);
    CGPoint endPoint = CGPointMake(patternSize.width, patternSize.height);
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsEndImageContext();
    
    // 使用 resizableImage 避免平铺时的接缝问题
    UIImage *resizableImage = [image resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeTile];
    
    return [UIColor colorWithPatternImage:resizableImage];
}
- (UIImage *)gradientImageWithSize:(CGSize)size colors:(NSArray<UIColor *> *)colors {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in colors) {
        [cgColors addObject:(id)color.CGColor];
    }
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)cgColors, NULL);
    CGPoint startPoint = CGPointMake(0, 0);
    CGPoint endPoint = CGPointMake(size.width, size.height);
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsEndImageContext();
    
    return image;
}
/*
- (UIColor *)gradientColorWithSize:(CGSize)size colors:(NSArray<UIColor *> *)colors {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGGradientRef gradient;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in colors) {
        [cgColors addObject:(id)color.CGColor];
    }
    
    gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)cgColors, NULL);
    CGPoint startPoint = CGPointMake(0, 0);
    CGPoint endPoint = CGPointMake(size.width, size.height);
    
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CFRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    return [UIColor colorWithPatternImage:image];
}
*/
/*
 *6-16位 随机字符串
 */
- (NSString *)randomString {
    int number = 6 +  arc4random() % 11;
    
    NSString *ramdom;
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 1; i ; i ++) {
        int a = (arc4random() % 122);
        if (a > 96) {
            char c = (char)a;
            [array addObject:[NSString stringWithFormat:@"%c",c]];
            if (array.count == number) {
                break;
            }
        } else continue;
    }
    ramdom = [array componentsJoinedByString:@""];
    return ramdom;
}

- (UIImage *)imageWithImageName:(NSString *)name tintColor:(UIColor *)tintColor
{
    UIImage *image = [UIImage imageNamed:name];;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, image.size.width, image.size.height);
    UIRectFill(bounds);
    [image drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

/*
 // 获取已存在的背景视图
 UIView *oldBackgroundView = objc_getAssociatedObject(self, &kAssociatedBackgroundViewKey);
 // 移除旧背景视图
   if (oldBackgroundView) {
       [oldBackgroundView removeFromSuperview];
   }
 // 存储新背景视图的引用
 objc_setAssociatedObject(self, &kAssociatedBackgroundViewKey, backgroundView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
 
 */
- (UIView *)addBackgroundWithColor:(UIColor *)color
                           view:( UIView *)backgroundView
                           padding:(CGFloat)padding
                      cornerRadius:(CGFloat)cornerRadius {
    
    // 创建背景视图
    //backgroundView = [[UIView alloc] init];
    if (!backgroundView) {
        backgroundView = [[UIView alloc] init];
        
    }
    backgroundView.backgroundColor = color;
    backgroundView.layer.cornerRadius = cornerRadius;
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    
    backgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
    backgroundView.layer.shadowOffset = CGSizeMake(0, 2);
    backgroundView.layer.shadowOpacity = 0.2;
    backgroundView.layer.shadowRadius = 5;
    
    // 确保当前视图有父视图
    if (!self.superview) {
        NSLog(@"错误：视图必须添加到父视图后才能添加背景");
        return nil;
    }
    
    // 将背景视图插入到当前视图下方
    [self.superview insertSubview:backgroundView belowSubview:self];
    if (backgroundView.backgroundColor == [UIColor clearColor]) {
        //[backgroundView removeAllConstraintsForView:self.superview];
        //[backgroundView removeFromSuperview];
        //backgroundView.hidden = YES;
    } else {
        //backgroundView.hidden = NO;
        // 设置约束
        [NSLayoutConstraint activateConstraints:@[
            // 背景视图与当前视图中心对齐
            [backgroundView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [backgroundView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            
            // 背景视图尺寸比当前视图大 (padding * 2)
            //[backgroundView.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:padding * 2]
            [backgroundView.widthAnchor constraintEqualToConstant:SCREEN_WIDTH],
            [backgroundView.heightAnchor constraintEqualToAnchor:self.heightAnchor constant:padding * 2]
        ]];
    }
  
    return backgroundView;
}

- (void)addElasticAnimationWithDuration:(NSTimeInterval)duration {
    // 创建关键帧动画
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    // 设置动画时间
    animation.duration = duration;
    
    animation.values = @[
        @(1.0),    // 初始状态
        @(0.85),    // 缩小
        @(0.65),    // 放大
        @(0.80),    // 缩小
        @(0.90),   // 放大
        @(1.0)     // 恢复原状
    ];
    
    // 设置关键帧的时间点
    animation.keyTimes = @[
        @(0.0),    // 0.0s
        @(0.2),    // 0.1s
        @(0.4),    // 0.2s
        @(0.6),    // 0.3s
        @(0.8),    // 0.4s
        @(1.0)     // 0.5s
    ];
    
    // 设置关键帧的缩放值（弹性效果）
    /*animation.values = @[
        @(1.0),    // 初始状态
        @(0.8),    // 缩小
        @(1.1),    // 放大
        @(0.9),    // 缩小
        @(1.05),   // 放大
        @(1.0)     // 恢复原状
    ];
    
    // 设置关键帧的时间点
    animation.keyTimes = @[
        @(0.0),    // 0.0s
        @(0.2),    // 0.1s
        @(0.4),    // 0.2s
        @(0.6),    // 0.3s
        @(0.8),    // 0.4s
        @(1.0)     // 0.5s
    ];*/
    
    // 设置动画的缓冲函数（使动画更平滑）
    animation.timingFunctions = @[
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
    ];
    
    // 添加动画到图层
    [self.layer addAnimation:animation forKey:@"elasticAnimation"];
}

- (void)setupMultiPulseAnimationForView:(UIView *)view {
    // 确保视图是圆形
    view.layer.cornerRadius = 44;
    view.backgroundColor = [UIColor clearColor];
    UIColor *blueColor = [self colorWithHexString:@"#1181FF" alpha:1];

    // 创建3个扩散圈层
    for (int i = 0; i < 3; i++) {
        CALayer *pulseLayer = [CALayer layer];
        pulseLayer.bounds = CGRectMake(0, 0, 88, 88);
        pulseLayer.position = CGPointMake(view.bounds.size.width/2, view.bounds.size.height/2);
        pulseLayer.cornerRadius = 44;
        pulseLayer.borderWidth = 2;
        pulseLayer.borderColor = blueColor.CGColor;
        pulseLayer.opacity = 0;
        [view.layer addSublayer:pulseLayer];
        
        // 每个圈层的动画延迟
        CGFloat delay = i * 0.5;
        
        // 缩放动画
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        scaleAnimation.fromValue = @1.0;
        scaleAnimation.toValue = @(140.0/88.0);
        
        // 透明度动画
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        opacityAnimation.fromValue = @0.8;
        opacityAnimation.toValue = @0.0;
        
        // 组合动画
        CAAnimationGroup *groupAnimation = [CAAnimationGroup animation];
        groupAnimation.animations = @[scaleAnimation, opacityAnimation];
        groupAnimation.duration = 2.0;
        groupAnimation.beginTime = CACurrentMediaTime() + delay;
        groupAnimation.repeatCount = INFINITY;
        groupAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        [pulseLayer addAnimation:groupAnimation forKey:@"pulseAnimation"];
    }
}

@end
