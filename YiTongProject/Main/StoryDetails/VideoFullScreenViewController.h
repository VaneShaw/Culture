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
@end

NS_ASSUME_NONNULL_END
