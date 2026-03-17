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

@end

NS_ASSUME_NONNULL_END

