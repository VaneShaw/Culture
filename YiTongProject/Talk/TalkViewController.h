//
//  TalkViewController.h
//  YiTongProject
//
//  Created by ios01 on 2026/2/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TalkViewController : BaseViewController

@end

NS_ASSUME_NONNULL_END


/*
 初步架构
 UIViewController
  ├─ header（标题）
  ├─ 横滑卡片 （Explore Scenes） 需要点击事件 回调 跳转页面，
  ├─ segment/tab（All / Trending / New） 需要点击事件 回调切换不同tableview，切换的时候不影响不跳动页面）
  └─ 横向分页容器（每页一个 tableView）
 目前想要实现的功能：
  整页是一个大滚动
  滚动下面的tableview 上面的 标题 横滑卡片 segment 都会 跟着上下滚动，

 */


/*
 初步架构 UIViewController 每个区域上下间距 为0
 ├─ header（标题） 高度 73
 ├─ 横滑卡片 （Explore Scenes） 需要点击事件 回调 跳转页面， 每个卡片 宽 260, 高208 间距16
 ├─ segment/tab（All Scenes / Trending / New）高度68 需要点击事件 回调切换不同tableview，切换的时候不影响不跳动页面）（每个按钮下有一个 黑色小横线 宽22 高2。跟着切换左右滚动 然后底下对应的tableview 左右滑动 左右滚，这个横线要跟着动）
 └─ 横向分页容器（每页一个 tableView）
 目前想要实现的功能： 整页是一个大滚动 滚动下面的tableview 上面的 标题 横滑卡片 segment 都会 跟着上下滚动， 可以往上滚，上面的跟着往上推，往下滚 跟着往下滚。 给出完整的 oc语言代码 要求严谨 高效 全部写在 TalkViewController 里面，
 */



/*
 初步架构 UIViewController 每个区域上下间距 为0
  CGFloat statusBarH = [PublicTool getStatusBarHeight]; 这是状态栏的高度 y轴从这里开始
  ├─ header（标题） 高度 73
  ├─ 横滑卡片 （Explore Scenes） 需要点击事件 回调 跳转页面， 每个卡片 宽 260, 高208 间距16
  ├─ segment/tab（All Scenes / Trending / New）高度68 需要点击事件 回调切换不同tableview，切换的时候不影响不跳动页面）（每个按钮下有一个 黑色小横线 宽22 高2。跟着切换左右滚动 然后底下对应的tableview 左右滑动 左右滚，这个横线要跟着动）
  └─ 横向分页容器（每页一个 tableView）
  目前想要实现的功能： 整页是一个大滚动 滚动下面的tableview 上面的 标题 横滑卡片 segment 都会 跟着上下滚动， 可以往上滚，上面的跟着往上推，往下滚 跟着往下滚。 给出完整的 oc语言代码 要求严谨 高效 全部写在 TalkViewController 里面，
 
 CGFloat tabBarHeight = self.tabBarController.tabBar.bounds.size.height; 底部有这个 对应的高要减掉吧
 - (void)viewWillAppear:(BOOL)animated {  这样隐藏
     [super viewWillAppear:animated];
     [self.navigationController setNavigationBarHidden:YES animated:animated];
 }
 - (void)viewWillDisappear:(BOOL)animated {
     [super viewWillDisappear:animated];
     [self.navigationController setNavigationBarHidden:NO animated:animated];
 }
 */
