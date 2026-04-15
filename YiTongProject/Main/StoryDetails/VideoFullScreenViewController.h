//
//  VideoFullScreenViewController.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/2.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface VideoFullScreenViewController : BaseViewController
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
@property (nonatomic, strong) AVPlayer *player;
/// 全屏被关闭时回调（modal dismiss / 手势下滑关闭等）；用于外层恢复列表滚动位置等
@property (nonatomic, copy, nullable) void (^onWillDismiss)(void);
@end

NS_ASSUME_NONNULL_END
