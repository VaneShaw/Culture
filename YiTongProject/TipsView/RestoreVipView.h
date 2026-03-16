//
//  RestoreVipView.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RestoreVipView : UIView
+ (void)showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack;
+ (void)hiddenAll;
@end

NS_ASSUME_NONNULL_END
