//
//  MembershipTransferView.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MembershipTransferView : UIView
+ (void)showViewTitle:(NSString *)title buttonArrayTitle:(NSArray *)titlArray callBack:(void(^)(NSInteger index))callBack;
@end

NS_ASSUME_NONNULL_END
