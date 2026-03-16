//
//  HanziMessageView.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HanziMessageView : UIView
+ (void)showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack;

@end

NS_ASSUME_NONNULL_END
