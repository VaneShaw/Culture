//
//  YTVVideoCategoryKeys.m
//  YiTongProject
//

#import "YTVVideoCategoryKeys.h"

static NSArray<NSString *> *YTVVideoCategoryKeysArray(void) {
    static NSArray<NSString *> *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = @[ @"recommend", @"idiom", @"myth", @"fengshen" ];
    });
    return keys;
}

NSUInteger YTVVideoCategoryCount(void) {
    return YTVVideoCategoryKeysArray().count;
}

NSString *YTVVideoCategoryKeyAtIndex(NSUInteger index) {
    NSArray<NSString *> *k = YTVVideoCategoryKeysArray();
    if (index >= k.count) {
        return @"";
    }
    return k[index];
}

NSInteger YTVVideoCategoryIndexForKey(NSString *categoryKey) {
    if (categoryKey.length == 0) {
        return NSNotFound;
    }
    NSArray<NSString *> *k = YTVVideoCategoryKeysArray();
    NSUInteger i = [k indexOfObjectPassingTest:^BOOL(NSString *obj, NSUInteger idx, BOOL *stop) {
        return [obj isEqualToString:categoryKey];
    }];
    if (i == NSNotFound) {
        return NSNotFound;
    }
    return (NSInteger)i;
}
