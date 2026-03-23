//
//  YTUnitMapper.h
//  YiTongProject
//

#import <Foundation/Foundation.h>
#import "YTUnit.h"

NS_ASSUME_NONNULL_BEGIN

/// 仅负责把接口响应里的 unit payload 映射成前端业务模型 YTUnit
@interface YTUnitMapper : NSObject

+ (NSArray<YTUnit *> *)mapUnitsFromResponse:(NSArray<NSDictionary *> *)response
                                    sceneId:(NSString *)sceneId
                                    levelId:(YTLevelId)levelId;

@end

NS_ASSUME_NONNULL_END
