//
//  TalkLearningFlowViewController.h
//  YiTongProject
//

#import <UIKit/UIKit.h>
#import "YTUnit.h"

NS_ASSUME_NONNULL_BEGIN

@interface TalkLearningFlowViewController : BaseViewController

/**
 场景对话 - 学习流容器初始化方法
 
 @param sceneId  场景标识（例如：scene_school）
 @param levelId  难度（Beginner/Intermediate/Advanced）
 
 说明：
 - 该 VC 是“核心页”，会直接开始学习流，不存在二级目录页
 - 数据目前来自 `YTMockUnitFactory`，后续接接口可替换为网络请求
 */
- (instancetype)initWithSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId;

/**
 *  预加载 units（用于模拟接口拉取完成后再进入学习流）
 *  @param preloadedUnits 若传入非空，则进入后直接使用，不再重复构建 mock 数据
 */
- (instancetype)initWithSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId preloadedUnits:(NSArray<YTUnit *> * _Nullable)preloadedUnits;

@end

NS_ASSUME_NONNULL_END

