//
//  YTMockUnitFactory.m
//  YiTongProject
//

#import "YTMockUnitFactory.h"
#import "YTMockLearningFlowResponseBuilder.h"
#import "YTUnitMapper.h"

@implementation YTMockUnitFactory

+ (void)fetchUnitsForSceneId:(NSString *)sceneId
                      levelId:(YTLevelId)levelId
                    completion:(void (^)(NSArray<YTUnit *> * _Nonnull units))completion {
    // MVP：用固定延迟模拟接口耗时（后续接真实网络只需替换这里）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSDictionary *response = [self buildMockAPIResponseForSceneId:sceneId levelId:levelId];
        NSArray<NSDictionary *> *unitsArray = response[@"units"];
        if (![unitsArray isKindOfClass:[NSArray class]]) unitsArray = @[];
        NSArray<YTUnit *> *units = [self buildUnitsFromAPIResponse:unitsArray sceneId:sceneId levelId:levelId];
        if (completion) completion(units);
    });
}

+ (NSArray<YTUnit *> *)buildUnitsForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    NSDictionary *response = [self buildMockAPIResponseForSceneId:sceneId levelId:levelId];
    NSArray<NSDictionary *> *unitsArray = response[@"units"];
    if (![unitsArray isKindOfClass:[NSArray class]]) unitsArray = @[];
    return [self buildUnitsFromAPIResponse:unitsArray sceneId:sceneId levelId:levelId];
}

+ (NSDictionary *)buildMockAPIResponseForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    return [YTMockLearningFlowResponseBuilder buildResponseForSceneId:sceneId levelId:levelId];
}

+ (NSArray<YTUnit *> *)buildUnitsFromAPIResponse:(NSArray<NSDictionary *> *)response
                                           sceneId:(NSString *)sceneId
                                           levelId:(YTLevelId)levelId {
    return [YTUnitMapper mapUnitsFromResponse:response sceneId:sceneId levelId:levelId];
}

@end
