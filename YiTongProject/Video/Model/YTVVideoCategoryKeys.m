//
//  YTVVideoCategoryKeys.m
//  YiTongProject
//

#import "YTVVideoCategoryKeys.h"

static NSArray<NSString *> *s_keys;
static NSArray<NSString *> *s_titles;

/// `tz` 与 `recommend` 均表示推荐位，深链与旧快照兼容。
static BOOL YTVVideoCategoryKeyMatches(NSString *a, NSString *b) {
    if (a.length == 0 || b.length == 0) {
        return NO;
    }
    if ([a isEqualToString:b]) {
        return YES;
    }
    BOOL aRec = [a isEqualToString:@"recommend"] || [a isEqualToString:@"tz"];
    BOOL bRec = [b isEqualToString:@"recommend"] || [b isEqualToString:@"tz"];
    return aRec && bRec;
}

void YTVVideoCategorySetFeedTabConfiguration(NSArray<NSString *> *keys, NSArray<NSString *> *titles) {
    if (keys.count == 0) {
        return;
    }
    NSMutableArray<NSString *> *kCopy = [NSMutableArray arrayWithCapacity:keys.count];
    for (id o in keys) {
        if ([o isKindOfClass:[NSString class]] && [(NSString *)o length] > 0) {
            [kCopy addObject:[(NSString *)o copy]];
        }
    }
    if (kCopy.count == 0) {
        return;
    }
    NSMutableArray<NSString *> *tCopy = [NSMutableArray arrayWithCapacity:kCopy.count];
    for (NSUInteger i = 0; i < kCopy.count; i++) {
        NSString *t = nil;
        if (titles != nil && i < titles.count) {
            id o = titles[i];
            if ([o isKindOfClass:[NSString class]]) {
                t = [(NSString *)o stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        if (t.length == 0) {
            t = kCopy[i];
        }
        [tCopy addObject:t];
    }
    s_keys = [kCopy copy];
    s_titles = [tCopy copy];
}

BOOL YTVVideoCategoryConfigurationMatchesKeys(NSArray<NSString *> *keys) {
    if (keys == nil) {
        keys = @[];
    }
    if (s_keys == nil || s_keys.count == 0) {
        return keys.count == 0;
    }
    if (keys.count != s_keys.count) {
        return NO;
    }
    for (NSUInteger i = 0; i < s_keys.count; i++) {
        if (![s_keys[i] isEqualToString:keys[i]]) {
            return NO;
        }
    }
    return YES;
}

NSUInteger YTVVideoCategoryCount(void) {
    return s_keys.count;
}

NSString *YTVVideoCategoryKeyAtIndex(NSUInteger index) {
    if (s_keys == nil || index >= s_keys.count) {
        return @"";
    }
    return s_keys[index];
}

NSString *YTVVideoCategoryTitleAtIndex(NSUInteger index) {
    if (s_titles == nil || index >= s_titles.count) {
        return @"";
    }
    return s_titles[index];
}

NSInteger YTVVideoCategoryIndexForKey(NSString *categoryKey) {
    if (categoryKey.length == 0) {
        return NSNotFound;
    }
    if (s_keys == nil || s_keys.count == 0) {
        return NSNotFound;
    }
    NSUInteger i = [s_keys indexOfObjectPassingTest:^BOOL(NSString *obj, NSUInteger idx, BOOL *stop) {
        return YTVVideoCategoryKeyMatches(obj, categoryKey);
    }];
    if (i == NSNotFound) {
        return NSNotFound;
    }
    return (NSInteger)i;
}
