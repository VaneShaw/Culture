//
//  TalkTopicHomeViewController.h
//  YiTongProject
//
//  Created by ios01 on 2026/3/17.
//

#import <UIKit/UIKit.h>
#import "YTUnit.h"

NS_ASSUME_NONNULL_BEGIN

@interface TalkTopicHomeViewController : BaseViewController

/// 列表 `/talk/scene` 的场景 id（与 `talkLearningSceneId` 数值一致）；>0 时请求 `POST /talk/level`
@property (nonatomic, assign) NSInteger talkSceneNumericId;
/// 与列表项 `id` 相同，即 scene_id 的字符串形式（如 `@"3"`），供学习流 key、`fetchBootstrapForSceneId:` 等使用
@property (nonatomic, copy, nullable) NSString *talkLearningSceneId;
/// 页头标题/副标题：来自列表场景文案，原样展示
@property (nonatomic, copy, nullable) NSString *scenePageTitle;
@property (nonatomic, copy, nullable) NSString *scenePageSubtitle;
/// 列表 `/talk/scene` 项的 `cover_image` 拼成的完整 URL，用于话题页顶部背景；若 `/talk/level` 返回 `background_url` / `backgroundUrl` 则优先覆盖
@property (nonatomic, copy, nullable) NSString *sceneListCoverImageURLString;

/// 与难度卡片 `progressPercent` 一致（0～1）；列表进入学习流与「完成页进下一难度」应使用同一来源，避免进度条不一致
- (CGFloat)progressRatioForDisplayLevel:(YTLevelId)levelId;

@end

NS_ASSUME_NONNULL_END

