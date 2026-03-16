//
//  MemberRetentionView.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MemberRetentionView : UIView

//一天之内只出现一次 不重复弹窗    用户取消支付 弹窗 会员已保留
+ (void)showViewTitle:(NSString *)title
            dataArray:(NSArray *)dataArray
             callBack:(void(^)(NSInteger index))callBack;
@end

NS_ASSUME_NONNULL_END
