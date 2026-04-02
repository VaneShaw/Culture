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
        /* 已在 CI 网络用 curl -I -L 抽检：Apple 示例流 + 若干公网 MP4 返回 200 且类型合理。
         * GCS gtv-videos-bucket 在该环境超时；techslides 500；radiantmediaplayer 403。 */
        urls = @[
            @"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
            @"https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8",
            @"https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8",
            @"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8",
            @"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8",
            @"https://www.w3schools.com/html/mov_bbb.mp4",
            @"https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4",
            @"https://filesamples.com/samples/video/mp4/sample_640x360.mp4",
            @"https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4",
            @"https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4",
            @"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
            @"https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8",
            @"https://www.w3schools.com/html/mov_bbb.mp4",
            @"https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4",
            @"https://filesamples.com/samples/video/mp4/sample_640x360.mp4",
            @"https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4",
            @"https://www.learningcontainer.com/wp-content/uploads/2020/05/sample-mp4-file.mp4",
            @"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8",
            @"https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8",
            @"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8",
        ];
    });
    return urls;
}

+ (NSArray<YTVVideoFeedItem *> *)allSampleItems {
    NSArray<NSString *> *urls = [self ytv_sampleVideoURLs];
    NSMutableArray<YTVVideoFeedItem *> *out = [NSMutableArray array];
    [urls enumerateObjectsUsingBlock:^(NSString *url, NSUInteger idx, BOOL *stop) {
        YTVVideoFeedItem *it = [[YTVVideoFeedItem alloc] init];
        it.videoId = [NSString stringWithFormat:@"debug_sample_%lu", (unsigned long)idx];
        it.title = [NSString stringWithFormat:@"Debug #%lu", (unsigned long)(idx + 1)];
        it.category = @"debug";
        it.summary = @"本地调试样例";
        it.playURL = url;
        it.coverURL = @"https://peach.blender.org/wp-content/uploads/bbb-splash.png";
        it.isFavorite = NO;
        it.favoritesCount = -1;
        it.shareURL = [NSString stringWithFormat:@"https://shiyi.yitong.com/app/video?id=%@&from=share", it.videoId];
        [out addObject:it];
    }];
    return [out copy];
}

+ (NSArray<YTVVideoFeedItem *> *)ytv_filteredItemsForCategory:(NSString *)categoryKey {
    NSArray<YTVVideoFeedItem *> *all = [self allSampleItems];
    if (categoryKey.length == 0 || [categoryKey isEqualToString:@"recommend"]) {
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
