//
//  KeyboardAvoidingManager.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyboardAvoidingManager : NSObject
+ (instancetype)sharedManager;
- (void)registerView:(UIView *)view containerView:(UIView *)containerView;
- (void)unregisterView;
- (void)setPadding:(CGFloat)padding; // 可选：设置键盘与输入框之间的间距
@end

NS_ASSUME_NONNULL_END
