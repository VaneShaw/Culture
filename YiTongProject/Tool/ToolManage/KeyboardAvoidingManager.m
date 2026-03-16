//
//  KeyboardAvoidingManager.m
//  YiTongProject
//
//  Created by Vincent on 2025/8/12.
//

#import "KeyboardAvoidingManager.h"
@interface KeyboardAvoidingManager ()
@property (weak, nonatomic) UIView *viewToAdjust;
@property (weak, nonatomic) UIView *containerView;
@property (weak, nonatomic) UIView *activeField;
@property (assign, nonatomic) CGRect originalFrame;
@property (assign, nonatomic) CGFloat keyboardHeight;
@property (assign, nonatomic) CGFloat padding; // 键盘与输入框之间的间距
@end
@implementation KeyboardAvoidingManager
+ (instancetype)sharedManager {
    static KeyboardAvoidingManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        sharedInstance.padding = 10.0; // 默认间距
    });
    return sharedInstance;
}
- (void)setupObservers {
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    // 使用更可靠的文本输入开始通知
    [center addObserver:self selector:@selector(textInputDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [center addObserver:self selector:@selector(textInputDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
}
- (void)registerView:(UIView *)view containerView:(UIView *)containerView {
    [self unregisterView];
    self.viewToAdjust = view;
    self.containerView = containerView;
    self.originalFrame = view.frame;
    [self setupObservers];
}
- (void)unregisterView {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.viewToAdjust = nil;
    self.containerView = nil;
    self.activeField = nil;
    self.keyboardHeight = 0;
}
- (void)setPadding:(CGFloat)padding {
    _padding = MAX(0, padding);
}
#pragma mark - Notification Handling

- (void)textInputDidBeginEditing:(NSNotification *)notification {
    UIView *textInput = notification.object;
    if ([textInput isKindOfClass:[UIResponder class]]) {
        self.activeField = textInput;
        [self adjustViewForActiveField];
    }
}
- (void)keyboardWillShow:(NSNotification *)notification {
    [self updateKeyboardHeightFromNotification:notification];
    [self adjustViewForActiveField];
}
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    [self updateKeyboardHeightFromNotification:notification];
    [self adjustViewForActiveField];
}
- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardHeight = 0;
    [self restoreViewPositionWithNotification:notification];
}

#pragma mark - Helper Methods

- (void)updateKeyboardHeightFromNotification:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.keyboardHeight = [self.containerView convertRect:keyboardFrame fromView:nil].size.height;
}
- (void)adjustViewForActiveField {
    if (!self.activeField || !self.viewToAdjust || self.keyboardHeight <= 0) return;
    
    // 计算输入框在容器视图中的位置
    CGRect fieldFrame = [self.containerView convertRect:self.activeField.bounds fromView:self.activeField];
    CGFloat fieldBottom = CGRectGetMaxY(fieldFrame);
    
    // 计算可见区域高度
    CGFloat visibleHeight = CGRectGetHeight(self.containerView.bounds) - self.keyboardHeight;
    // 计算需要偏移的距离
    CGFloat offset = fieldBottom - visibleHeight + self.padding;
    
    if (offset > 0) {
        CGRect newFrame = self.viewToAdjust.frame;
        newFrame.origin.y = self.originalFrame.origin.y - offset;
        
        [UIView animateWithDuration:0.25 animations:^{
            self.viewToAdjust.frame = newFrame;
        }];
    } else {
        // 如果不需要偏移，确保视图在原始位置
        [self restoreViewPositionAnimated:YES];
    }
}

- (void)restoreViewPositionWithNotification:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        [self restoreViewPositionAnimated:NO];
    }];
}
- (void)restoreViewPositionAnimated:(BOOL)animated {
    void (^animationBlock)(void) = ^{
        self.viewToAdjust.frame = self.originalFrame;
    };
    if (animated) {
        [UIView animateWithDuration:0.25 animations:animationBlock];
    } else {
        animationBlock();
    }
}

@end
