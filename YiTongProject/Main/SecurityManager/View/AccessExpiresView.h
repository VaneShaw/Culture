//
//  AccessExpiresView.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AccessExpiresView : UIView
//剩余天数 7天 or 1天
+ (void)showViewTitle:(NSString *)title
            dataArray:(NSArray *)dataArray
             callBack:(void(^)(NSInteger index))callBack;


@end

NS_ASSUME_NONNULL_END
