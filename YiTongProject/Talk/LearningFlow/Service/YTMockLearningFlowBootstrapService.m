//
//  YTMockLearningFlowBootstrapService.m
//  YiTongProject
//

#import "YTMockLearningFlowBootstrapService.h"
#import "YTLearningFlowBootstrap.h"
#import "YTLearningProgressStoring.h"
#import "YTMockLearningFlowResponseBuilder.h"
#import "YTUnitMapper.h"
#import "YTTalkLearningDataService.h"

@interface YTMockLearningFlowBootstrapService ()
@property (nonatomic, strong) id<YTLearningProgressStoring> progressStore;
@end

@implementation YTMockLearningFlowBootstrapService

+ (instancetype)shared {
    static YTMockLearningFlowBootstrapService *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[YTMockLearningFlowBootstrapService alloc] init];
        s.progressStore = [YTTalkLearningDataService shared];
    });
    return s;
}

- (void)fetchBootstrapForSceneId:(NSString *)sceneId
                         levelId:(NSInteger)levelId
                      completion:(YTLearningFlowBootstrapCompletion)completion {
    if (!completion) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *mockResponse = [YTMockLearningFlowResponseBuilder buildResponseForSceneId:sceneId levelId:(YTLevelId)levelId];
        NSArray<NSDictionary *> *unitsArray = mockResponse[@"units"];
        if (![unitsArray isKindOfClass:[NSArray class]]) unitsArray = @[];
        NSArray<YTUnit *> *units = [YTUnitMapper mapUnitsFromResponse:unitsArray sceneId:sceneId levelId:(YTLevelId)levelId];

        [self.progressStore fetchLearningProgressForSceneId:sceneId levelId:levelId completion:^(YTLastPosition * _Nullable lastPosition, NSArray<NSString *> *completedUnitIds, NSError * _Nullable error) {
            if (error) {
                completion(nil, error);
                return;
            }
            YTLearningFlowBootstrap *bootstrap = [[YTLearningFlowBootstrap alloc] init];
            bootstrap.units = units ?: @[];
            bootstrap.lastPosition = lastPosition;
            bootstrap.completedUnitIds = completedUnitIds ?: @[];
            completion(bootstrap, nil);
        }];
    });
}

@end
