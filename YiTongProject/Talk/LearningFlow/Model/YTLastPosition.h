//
//  YTLastPosition.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTUnit.h"

NS_ASSUME_NONNULL_BEGIN

@interface YTLastPosition : NSObject

/// 场景 id（例如：scene_school）。用于区分不同场景的续学数据。
@property (nonatomic, copy) NSString *sceneId;
/// 难度（Beginner/Intermediate/Advanced）。同一场景不同难度单独存档。
@property (nonatomic, assign) YTLevelId levelId;

/// 上次停留的 unit 类型（用于兼容未来不同类型的续学策略）
@property (nonatomic, assign) YTUnitType unitType;
/// 上次停留的 unitId（优先用于恢复定位）
@property (nonatomic, copy) NSString *unitId;
/// 在该难度内的 stepIndex（unitId 找不到时的兜底定位）
@property (nonatomic, assign) NSInteger stepIndex;
/// 存档时间戳（可用于未来做“过期/清理”策略）
@property (nonatomic, assign) NSTimeInterval timestamp;

/// 序列化：写入 NSUserDefaults 的轻量字典
- (NSDictionary *)toDictionary;
/// 反序列化：容错处理（dict 非法则返回 nil）
+ (nullable instancetype)fromDictionary:(id)dict;

@end

NS_ASSUME_NONNULL_END

