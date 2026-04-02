//
//  YTTalkSceneItem.h
//  YiTongProject
//
//  /talk/scene 返回 data[] 中单条场景
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTTalkSceneItem : NSObject

@property (nonatomic, assign) NSInteger sceneId;
@property (nonatomic, copy) NSString *sceneCode;
@property (nonatomic, assign) NSInteger sort;
@property (nonatomic, assign) NSInteger hot;
@property (nonatomic, copy, nullable) NSString *createTime;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy, nullable) NSString *coverImagePath;
@property (nonatomic, assign) NSInteger sceneProgressPercent;

/// 解析 `data` 数组
+ (NSArray<YTTalkSceneItem *> *)itemsByParsingAPIData:(id)data;

@end

NS_ASSUME_NONNULL_END
