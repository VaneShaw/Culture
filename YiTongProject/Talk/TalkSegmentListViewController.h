//
//  TalkSegmentListViewController.h
//  YiTongProject
//
//  Created for 情景对话 Tab 分页列表
//

#import <UIKit/UIKit.h>
#import <JXPagingView/JXPagerView.h>

NS_ASSUME_NONNULL_BEGIN

@interface TalkSegmentListViewController : BaseViewController<JXPagerViewListViewDelegate, UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithType:(NSString *)type;

/// 重新请求 `/talk/scene` 并刷新列表（与 MJRefresh 下拉刷新相同逻辑）
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END

