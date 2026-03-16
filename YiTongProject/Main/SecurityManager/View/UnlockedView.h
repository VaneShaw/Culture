//
//  UnlockedView.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UnlockedView : UIView
//会员解锁成功 验签成功弹窗
+ (void)showViewTitle:(NSString *)title
            dataArray:(NSArray *)dataArray
             callBack:(void(^)(NSInteger index))callBack;


@end

NS_ASSUME_NONNULL_END
