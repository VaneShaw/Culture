//
//  TalkTableViewCell.h
//  YiTongProject
//
//  Created by ios01 on 2026/3/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTTalkSceneCellStatus) {
    // 底部纯色：#E3C89D
    YTTalkSceneCellStatusNotStarted = 0,
    // 底部纯色：#C9DFA2
    YTTalkSceneCellStatusInProgress,
    // 底部纯色：#DBE5F8
    YTTalkSceneCellStatusCompleted
};

@interface TalkTableViewCell : UITableViewCell
// 按场景卡片 UI 需求配置内容与进度状态
- (void)configureWithTitle:(NSString *)title
                  subtitle:(NSString *)subtitle
                  imageUrl:(NSString *)imageUrl
           progressPercent:(NSInteger)progressPercent;
@end

NS_ASSUME_NONNULL_END
