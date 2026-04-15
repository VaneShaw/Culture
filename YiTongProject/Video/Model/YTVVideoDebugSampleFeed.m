//
//  YTVVideoDebugSampleFeed.m
//  YiTongProject
//

#import "YTVVideoDebugSampleFeed.h"
#import "YTVFeedPageResult.h"
#import "YTVVideoFeedItem.h"

static NSString * const kYTVUDSampleFeed = @"YTVDebugVideoSampleFeed";

@implementation YTVVideoDebugSampleFeed

+ (BOOL)isSampleFeedEnabled {
#if DEBUG
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([d objectForKey:kYTVUDSampleFeed] == nil) {
        return YES;
    }
    return [d boolForKey:kYTVUDSampleFeed];
#else
    return NO;
#endif
}

+ (void)setSampleFeedEnabled:(BOOL)enabled {
#if DEBUG
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kYTVUDSampleFeed];
#endif
}

+ (NSArray<NSString *> *)ytv_sampleVideoURLs {
    static NSArray<NSString *> *urls;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        /* DEBUG 样例流：测试环境汉字视频 MP4（与真实接口路径一致，便于联调）。 */
        NSString *host = @"https://testoss.shiyi-yitong.com";
        NSArray<NSString *> *paths = @[
            @"/hanzi/videos/jiu3_9.mp4",
            @"/hanzi/videos/shi2_10.mp4",
            @"/hanzi/videos/shang4_11.mp4",
            @"/hanzi/videos/xia4_12.mp4",
            @"/hanzi/videos/zuo3_13.mp4",
            @"/hanzi/videos/you4_14.mp4",
            @"/hanzi/videos/zhong1_15.mp4",
            @"/hanzi/videos/shi2_16.mp4",
            @"/hanzi/videos/fen1_17.mp4",
            @"/hanzi/videos/miao3_18.mp4",
            @"/hanzi/videos/ri4_19.mp4",
            @"/hanzi/videos/yue4_20.mp4",
            @"/hanzi/videos/wo3_21.mp4",
            @"/hanzi/videos/ni3_22.mp4",
            @"/hanzi/videos/ta1_23.mp4",
            @"/hanzi/videos/ta1_24.mp4",
        ];
        NSMutableArray<NSString *> *built = [NSMutableArray arrayWithCapacity:paths.count];
        for (NSString *p in paths) {
            NSString *trim = [p stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
            if (trim.length == 0) {
                continue;
            }
            [built addObject:[NSString stringWithFormat:@"%@/%@", host, trim]];
        }
        urls = [built copy];
    });
    return urls;
}

/// 测试 OSS 上汉字视频与同目录 GIF 封面同名（与字卡 `hanzi/videos/*.gif` 约定一致），供跟手滑动时 SD 预取与 Cell 占位
+ (NSString *)ytv_debugCoverURLForPlayURL:(NSString *)playURL {
    if (playURL.length == 0) {
        return @"";
    }
    NSRange r = [playURL rangeOfString:@".mp4" options:NSCaseInsensitiveSearch];
    if (r.location == NSNotFound) {
        return playURL;
    }
    return [playURL stringByReplacingCharactersInRange:r withString:@".gif"];
}

+ (NSArray<YTVVideoFeedItem *> *)allSampleItems {
    NSArray<NSString *> *urls = [self ytv_sampleVideoURLs];
    NSMutableArray<YTVVideoFeedItem *> *out = [NSMutableArray array];
    [urls enumerateObjectsUsingBlock:^(NSString *url, NSUInteger idx, BOOL *stop) {
        YTVVideoFeedItem *it = [[YTVVideoFeedItem alloc] init];
        it.videoId = [NSString stringWithFormat:@"debug_sample_%lu", (unsigned long)idx];
        it.title = @"";
        it.category = @"debug";
        it.summary = @"";
        it.playURL = url;
        it.coverURL = [self ytv_debugCoverURLForPlayURL:url];
        it.isFavorite = NO;
        it.favoritesCount = 275 + (NSInteger)idx;
        it.shareCount = 302 + (NSInteger)idx;
        it.shareURL = [NSString stringWithFormat:@"https://shiyi.yitong.com/app/video?id=%@&from=share", it.videoId];
        [out addObject:it];
    }];
    return [out copy];
}

+ (NSArray<YTVVideoFeedItem *> *)ytv_filteredItemsForCategory:(NSString *)categoryKey {
    NSArray<YTVVideoFeedItem *> *all = [self allSampleItems];
    if (categoryKey.length == 0 || [categoryKey isEqualToString:@"recommend"] || [categoryKey isEqualToString:@"tz"]) {
        return all;
    }
    NSMutableArray *m = [NSMutableArray array];
    for (YTVVideoFeedItem *it in all) {
        YTVVideoFeedItem *copy = [[YTVVideoFeedItem alloc] init];
        copy.videoId = it.videoId;
        copy.title = [NSString stringWithFormat:@"[%@] %@", categoryKey, it.title];
        copy.category = categoryKey;
        copy.summary = it.summary;
        copy.playURL = it.playURL;
        copy.coverURL = it.coverURL;
        copy.isFavorite = it.isFavorite;
        copy.favoritesCount = it.favoritesCount;
        copy.shareURL = it.shareURL;
        [m addObject:copy];
    }
    return [m copy];
}

+ (NSInteger)ytv_indexOfVideoId:(NSString *)vid inItems:(NSArray<YTVVideoFeedItem *> *)items {
    if (vid.length == 0) {
        return NSNotFound;
    }
    NSUInteger i = 0;
    for (YTVVideoFeedItem *it in items) {
        if ([it.videoId isEqualToString:vid]) {
            return (NSInteger)i;
        }
        i++;
    }
    return NSNotFound;
}

+ (YTVFeedPageResult *)bootstrapPageForCategoryKey:(NSString *)categoryKey pageSize:(NSInteger)pageSize {
    NSArray<YTVVideoFeedItem *> *all = [self ytv_filteredItemsForCategory:categoryKey];
    NSInteger n = MIN(MAX(1, pageSize), (NSInteger)all.count);
    YTVFeedPageResult *r = [[YTVFeedPageResult alloc] init];
    r.items = n > 0 ? [all subarrayWithRange:NSMakeRange(0, (NSUInteger)n)] : @[];
    r.nextCursor = (NSInteger)all.count > n ? @"dbg_more" : @"";
    r.hasMore = (NSInteger)all.count > n;
    r.ttlSec = 0;
    return r;
}

+ (YTVFeedPageResult *)nextPageForCategoryKey:(NSString *)categoryKey
                                 lastVideoId:(NSString *)lastVideoId
                                    pageSize:(NSInteger)pageSize {
    NSArray<YTVVideoFeedItem *> *all = [self ytv_filteredItemsForCategory:categoryKey];
    NSInteger start = 0;
    if (lastVideoId.length > 0) {
        NSInteger idx = [self ytv_indexOfVideoId:lastVideoId inItems:all];
        if (idx != NSNotFound) {
            start = idx + 1;
        }
    }
    NSInteger remain = (NSInteger)all.count - start;
    if (remain <= 0) {
        YTVFeedPageResult *r = [[YTVFeedPageResult alloc] init];
        r.items = @[];
        r.nextCursor = @"";
        r.hasMore = NO;
        return r;
    }
    NSInteger n = MIN(MAX(1, pageSize), remain);
    YTVFeedPageResult *r = [[YTVFeedPageResult alloc] init];
    r.items = [all subarrayWithRange:NSMakeRange((NSUInteger)start, (NSUInteger)n)];
    r.nextCursor = (start + n) < (NSInteger)all.count ? @"dbg_more" : @"";
    r.hasMore = (start + n) < (NSInteger)all.count;
    return r;
}

@end
