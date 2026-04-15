//
//  YTLearningFlowBootstrap.m
//  YiTongProject
//

#import "YTLearningFlowBootstrap.h"

@implementation YTLearningFlowBootstrap

- (instancetype)init {
    self = [super init];
    if (self) {
        _units = @[];
        _completedStepIndices = @[];
        _completedUnitIds = @[];
    }
    return self;
}

@end
