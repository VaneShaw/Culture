//
//  YTLearningFlowProgressUtils.m
//  YiTongProject
//

#import "YTLearningFlowProgressUtils.h"
#import "YTUnit.h"

@implementation YTLearningFlowProgressUtils

+ (CGFloat)progressRatioForUnits:(NSArray<YTUnit *> *)units completedUnitIdentifiers:(NSSet<NSString *> *)completedIds {
    NSInteger total = 0;
    NSInteger done = 0;
    NSSet<NSString *> *doneSet = completedIds ?: [NSSet set];
    for (YTUnit *u in units) {
        if (![u countsTowardProgress]) continue;
        total += 1;
        NSString *uid = u.unitId;
        if (uid.length > 0 && [doneSet containsObject:uid]) {
            done += 1;
        }
    }
    if (total <= 0) return 0;
    return (CGFloat)done / (CGFloat)total;
}

@end
