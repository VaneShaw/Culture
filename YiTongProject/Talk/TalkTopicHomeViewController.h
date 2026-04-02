//
//  TalkTopicHomeViewController.h
//  YiTongProject
//
//  Created by ios01 on 2026/3/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TalkTopicHomeViewController : BaseViewController

/// 列表 `/talk/scene` 的场景 id；>0 时请求 `POST /talk/level`
@property (nonatomic, assign) NSInteger talkSceneNumericId;
/// 学习流与本地进度用的 scene 标识（如 `scene_school`）
@property (nonatomic, copy, nullable) NSString *talkLearningSceneId;
/// 页头标题/副标题：来自列表场景文案，原样展示
@property (nonatomic, copy, nullable) NSString *scenePageTitle;
@property (nonatomic, copy, nullable) NSString *scenePageSubtitle;

@end

NS_ASSUME_NONNULL_END

