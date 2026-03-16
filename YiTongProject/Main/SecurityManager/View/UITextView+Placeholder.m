//
//  UITextView+Placeholder.m
//  YiTongProject
//
//  Created by ios01 on 2025/12/1.
//

#import "UITextView+Placeholder.h"
#import <objc/runtime.h>
static const void *kPlaceholderLabelKey = &kPlaceholderLabelKey;

@implementation UITextView (Placeholder)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method original = class_getInstanceMethod(self, @selector(layoutSubviews));
        Method swizzled = class_getInstanceMethod(self, @selector(ph_layoutSubviews));
        method_exchangeImplementations(original, swizzled);
    });
}

- (void)ph_layoutSubviews {
    [self ph_layoutSubviews];   // 调用原 layoutSubviews
    UILabel *label = [self placeholderLabel];
    label.numberOfLines = 0;
    UIEdgeInsets inset = self.textContainerInset;
    CGFloat x = inset.left + 7;
    CGFloat y = inset.top;
    CGFloat width = self.bounds.size.width - inset.left - inset.right - 7;
    CGSize size = [label sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    label.frame = CGRectMake(x, y, width, size.height);
}
- (UILabel *)placeholderLabel {
    UILabel *label = objc_getAssociatedObject(self, kPlaceholderLabelKey);
    if (!label) {
        label = [[UILabel alloc] init];
        label.textColor = [UIColor lightGrayColor];
        label.numberOfLines = 0;
        label.font = self.font ? self.font : [UIFont fontWithName:FONT_NAME_Regular size:14];
        label.userInteractionEnabled = NO;
        [self addSubview:label];
        [self sendSubviewToBack:label]; // 确保不挡住输入光标

        objc_setAssociatedObject(self, kPlaceholderLabelKey, label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        // 输入变化监听
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textDidChange)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:self];
    }
    return label;
}

#pragma mark - Setter

- (void)setPlaceholder:(NSString *)placeholder {
    UILabel *label = [self placeholderLabel];
    label.text = placeholder;

    [self setNeedsLayout]; // 等 layoutSubviews 布局
    [self textDidChange];  // 初始隐藏逻辑
}

- (NSString *)placeholder {
    return self.placeholderLabel.text;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    self.placeholderLabel.textColor = placeholderColor;
}

- (UIColor *)placeholderColor {
    return self.placeholderLabel.textColor;
}

#pragma mark - Layout

// AutoLayout 或 frame 改变时都会重新布局

#pragma mark - Text Change

- (void)textDidChange {
    self.placeholderLabel.hidden = self.text.length > 0;
}

#pragma mark - Remove Observer

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
