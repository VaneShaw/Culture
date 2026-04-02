//
//  YTTalkHomeBannerData.h
//  YiTongProject
//
//  /talk/banner 响应中 data 对象（仅在此处解析字典字段）
//

#import <Foundation/Foundation.h>

@class YTTalkHomeBannerImageItem;
@class YTTalkHomeSceneTabItem;

NS_ASSUME_NONNULL_BEGIN

@interface YTTalkHomeBannerData : NSObject

@property (nonatomic, copy) NSArray<YTTalkHomeBannerImageItem *> *bannerImages;
@property (nonatomic, copy) NSArray<YTTalkHomeSceneTabItem *> *sceneTabs;

/// 将接口 data 字典转为模型；非法或 nil 时返回「仅 all + 无 banner」
+ (instancetype)dataByParsingAPIDictionary:(nullable id)payload;

/// 请求失败或未登录等：仅 all、无 banner
+ (instancetype)emptyDefaultAllTabOnly;

@end

NS_ASSUME_NONNULL_END
