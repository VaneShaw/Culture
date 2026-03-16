//
//  AccountDeletionView.h
//  YiTongProject
//
//  Created by ios01 on 2025/8/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AccountDeletionView : UIView
+ (void)showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack;

@end

NS_ASSUME_NONNULL_END
