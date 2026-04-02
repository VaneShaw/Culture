//
//  YTVFeedSnapshotCache.m
//  YiTongProject
//

#import "YTVFeedSnapshotCache.h"
#import "YTVVideoFeedItem.h"

static NSString *YTVFeedSnapshotSafeFileComponent(NSString *categoryKey) {
    NSString *base = categoryKey.length > 0 ? categoryKey : @"default";
    NSCharacterSet *bad = [NSCharacterSet characterSetWithCharactersInString:@"/\\:?%*|\"<>\n\r"];
    return [[base componentsSeparatedByCharactersInSet:bad] componentsJoinedByString:@"_"];
}

@implementation YTVFeedSnapshotCache

+ (NSURL *)ytv_snapshotDirectoryURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *base = [fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *dir = [base URLByAppendingPathComponent:@"YTVFeedSnapshots" isDirectory:YES];
    [fm createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

+ (NSURL *)ytv_fileURLForCategoryKey:(NSString *)categoryKey {
    NSString *name = [NSString stringWithFormat:@"%@.json", YTVFeedSnapshotSafeFileComponent(categoryKey ?: @"")];
    return [[self ytv_snapshotDirectoryURL] URLByAppendingPathComponent:name];
}

+ (void)saveCategoryKey:(NSString *)categoryKey
                  items:(NSArray<YTVVideoFeedItem *> *)items
             nextCursor:(NSString *)nextCursor
                hasMore:(BOOL)hasMore {
    NSMutableArray *raw = [NSMutableArray array];
    for (YTVVideoFeedItem *it in items) {
        if (![it isKindOfClass:[YTVVideoFeedItem class]]) {
            continue;
        }
        [raw addObject:[it ytv_toSnapshotDictionary]];
    }
    NSDictionary *payload = @{
        @"version": @(1),
        @"category": categoryKey ?: @"",
        @"nextCursor": nextCursor ?: @"",
        @"hasMore": @(hasMore),
        @"savedAt": @([[NSDate date] timeIntervalSince1970]),
        @"items": raw,
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    if (!data.length) {
        return;
    }
    [data writeToURL:[self ytv_fileURLForCategoryKey:categoryKey] atomically:YES];
}

+ (NSDictionary *)loadSnapshotDictionaryForCategoryKey:(NSString *)categoryKey {
    NSURL *url = [self ytv_fileURLForCategoryKey:categoryKey];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data.length == 0) {
        return nil;
    }
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![obj isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return (NSDictionary *)obj;
}

@end
