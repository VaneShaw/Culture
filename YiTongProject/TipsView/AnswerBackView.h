//
//  AnswerBackView.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/31.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AnswerBackView : UIView
+ (void)showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack;
@end

NS_ASSUME_NONNULL_END
