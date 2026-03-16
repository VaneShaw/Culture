//
//  StoryLockCoverView.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StoryLockCoverView : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *btnLogin;
@property (nonatomic, copy) void (^subscribeHandler)(void);

/// 👆 向上滑（下一页）
//@property (nonatomic, copy) void (^swipeUpBlock)(void);

/// 👇 向下滑（上一页）
//@property (nonatomic, copy) void (^swipeDownBlock)(void);

@end

NS_ASSUME_NONNULL_END
