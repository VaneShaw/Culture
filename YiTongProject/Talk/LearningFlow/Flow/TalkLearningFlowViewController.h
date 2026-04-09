//
//  TalkLearningFlowViewController.h
//  YiTongProject
//

#import <UIKit/UIKit.h>
#import "YTUnit.h"

NS_ASSUME_NONNULL_BEGIN

@class YTLearningFlowBootstrap;

@interface TalkLearningFlowViewController : BaseViewController

/// 与 `/talk/scene` 列表项 `id` 一致；>0 时拉取 `POST /talk/unit`；须与 `sceneId` 或本属性一致以保证能请求
@property (nonatomic, assign) NSInteger talkSceneNumericId;
/// 与话题页 `didApplyTalkLevelAPI` 一致：为 YES 时请求使用 `talkBeginner/Intermediate/AdvancedLevelRecordId`
@property (nonatomic, assign) BOOL talkDidApplyLevelAPI;
@property (nonatomic, assign) NSInteger talkBeginnerLevelRecordId;
@property (nonatomic, assign) NSInteger talkIntermediateLevelRecordId;
@property (nonatomic, assign) NSInteger talkAdvancedLevelRecordId;

/**
 场景对话 - 学习流容器初始化方法

 @param sceneId  场景标识（例如：scene_school）
 @param levelId  难度（Beginner/Intermediate/Advanced）

 说明：须配置有效 `talkSceneNumericId`（或由话题页 push 时注入），否则仅 `init` 会走网络并失败。
 */
- (instancetype)initWithSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId;

/// 预加载 bootstrap（内容 + 进度），用于入口页先拿完整启动快照后再进入学习流
- (instancetype)initWithSceneId:(NSString *)sceneId
                        levelId:(YTLevelId)levelId
             preloadedBootstrap:(YTLearningFlowBootstrap * _Nullable)preloadedBootstrap;

/// 与话题页卡片 `progressPercent` 一致：0～100 时顶部条进入即显示该进度；`-1` 表示未注入（顶部条先显示 0%，不以本地估算顶替）
- (instancetype)initWithSceneId:(NSString *)sceneId
                        levelId:(YTLevelId)levelId
             preloadedBootstrap:(YTLearningFlowBootstrap * _Nullable)preloadedBootstrap
        initialProgressPercent:(NSInteger)initialProgressPercent;

@end

NS_ASSUME_NONNULL_END
