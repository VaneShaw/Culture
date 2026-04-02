//
//  YTTalkHomeSceneTabItem.h
//  YiTongProject
//
//  /talk/banner → data.scene_tab_list：tab_* 的 value 原样用于展示，并作为列表请求的 type
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTTalkHomeSceneTabItem : NSObject

/// 列表请求与 `initWithType:` 使用的类型（接口 tab_* 原值；兜底时为 @"all"）
@property (nonatomic, copy) NSString *typeIdentifier;

/// 有值时优先作 segment 展示（仅本地兜底用）；接口下发的 tab 不设置，展示即 `typeIdentifier`
@property (nonatomic, copy, nullable) NSString *overrideDisplayTitle;

/// segment 上展示的标题
- (NSString *)displayTitle;

+ (instancetype)itemWithTypeIdentifier:(NSString *)typeIdentifier;

/// 无 tab 数据时：列表仍用 all，标题走 `Talk_Home_Tab_AllScenes` 国际化
+ (instancetype)defaultAllTabItem;

@end

NS_ASSUME_NONNULL_END
