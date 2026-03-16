//
//  UITableView+Empty.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableView (Empty)

- (void)checkEmptyWithDataCount:(NSInteger)count;

/// 显示空页面
//- (void)showEmptyViewWithMessage:(NSString *)message image:(UIImage *)image;

/// 隐藏空页面
//- (void)hideEmptyView;

@end

NS_ASSUME_NONNULL_END
