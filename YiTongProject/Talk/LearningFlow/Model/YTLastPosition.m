//
//  YTLastPosition.m
//  YiTongProject
//

#import "YTLastPosition.h"

@implementation YTLastPosition

- (NSDictionary *)toDictionary {
    // 注意：这里只存“基础标识信息”，不存复杂对象，确保 NSUserDefaults 可安全落地
    return @{
        @"sceneId": self.sceneId ?: @"",
        @"levelId": @(self.levelId),
        @"unitType": @(self.unitType),
        @"unitId": self.unitId ?: @"",
        @"stepIndex": @(self.stepIndex),
        @"timestamp": @(self.timestamp),
    };
}

+ (instancetype)fromDictionary:(id)dict {
    // 容错：数据结构变化/被污染时直接返回 nil，让上层按“从头开始”兜底
    if (![dict isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *d = (NSDictionary *)dict;

    NSString *sceneId = [d[@"sceneId"] isKindOfClass:[NSString class]] ? d[@"sceneId"] : @"";
    NSString *unitId = [d[@"unitId"] isKindOfClass:[NSString class]] ? d[@"unitId"] : @"";
    if (sceneId.length == 0 || unitId.length == 0) return nil;

    YTLastPosition *pos = [[YTLastPosition alloc] init];
    pos.sceneId = sceneId;
    pos.unitId = unitId;
    pos.levelId = (YTLevelId)[d[@"levelId"] integerValue];
    pos.unitType = (YTUnitType)[d[@"unitType"] integerValue];
    pos.stepIndex = [d[@"stepIndex"] integerValue];
    pos.timestamp = [d[@"timestamp"] doubleValue];
    return pos;
}

@end

