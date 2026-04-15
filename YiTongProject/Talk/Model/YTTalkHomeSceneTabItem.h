//
//  YTTalkHomeSceneTabItem.h
//  YiTongProject
//
//  /talk/banner → data.scene_tab_list：key 为列表请求 tab_type；value 为 Tab 展示文案
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTTalkHomeSceneTabItem : NSObject

/// 与 `/talk/scene` 请求体 `tab_type` 一致（取 scene_tab_list 的 key；兜底时为 @"all"）
@property (nonatomic, copy) NSString *typeIdentifier;

/// 有值时作 Tab 标题（接口 scene_tab_list 的 value）；本地兜底 all 时用国际化
@property (nonatomic, copy, nullable) NSString *overrideDisplayTitle;

/// segment 上展示的标题
- (NSString *)displayTitle;

+ (instancetype)itemWithTypeIdentifier:(NSString *)typeIdentifier;

/// 无 tab 数据时：列表仍用 all，标题走 `Talk_Home_Tab_AllScenes` 国际化
+ (instancetype)defaultAllTabItem;

@end

NS_ASSUME_NONNULL_END
