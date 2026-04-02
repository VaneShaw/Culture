//
//  YTVVideoPreloadManager.m
//  YiTongProject
//

#import "YTVVideoPreloadManager.h"
#import "YTVVideoFeedItem.h"
#import "HeaderConfig.h"
#import <AVFoundation/AVFoundation.h>

static const NSUInteger kYTVMediaWarmMaxItems = 4;

@interface YTVVideoPreloadManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, AVPlayerItem *> *warmByVideoId;
@property (nonatomic, strong) NSMutableOrderedSet<NSString *> *warmAccessOrder;
@end

@implementation YTVVideoPreloadManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _warmByVideoId = [NSMutableDictionary dictionary];
        _warmAccessOrder = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)warmAroundDisplayIndex:(NSInteger)displayIndex items:(NSArray<YTVVideoFeedItem *> *)items {
    if (items.count == 0) {
        return;
    }
    NSMutableArray<NSURL *> *coverURLs = [NSMutableArray array];
    NSMutableIndexSet *warmIndices = [NSMutableIndexSet indexSet];
    NSInteger n = (NSInteger)items.count;
    if (displayIndex > 0) {
        [warmIndices addIndex:(NSUInteger)(displayIndex - 1)];
    }
    for (NSInteger k = 1; k <= 3; k++) {
        NSInteger j = displayIndex + k;
        if (j < n) {
            [warmIndices addIndex:(NSUInteger)j];
        }
    }
    [warmIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        YTVVideoFeedItem *it = items[idx];
        if (it.coverURL.length > 0) {
            NSURL *u = [NSURL URLWithString:it.coverURL];
            if (u) {
                [coverURLs addObject:u];
            }
        }
        [self ytv_enqueueMediaWarmForItem:it];
    }];
    if (coverURLs.count > 0) {
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:coverURLs];
    }
}

- (void)ytv_enqueueMediaWarmForItem:(YTVVideoFeedItem *)item {
    if (item.videoId.length == 0 || item.playURL.length == 0) {
        return;
    }
    if (self.warmByVideoId[item.videoId] != nil) {
        [self.warmAccessOrder removeObject:item.videoId];
        [self.warmAccessOrder addObject:item.videoId];
        return;
    }
    NSURL *url = [NSURL URLWithString:item.playURL];
    if (!url || (![url.scheme.lowercaseString isEqualToString:@"http"] && ![url.scheme.lowercaseString isEqualToString:@"https"])) {
        return;
    }
    while (self.warmAccessOrder.count >= kYTVMediaWarmMaxItems) {
        NSString *evict = self.warmAccessOrder.firstObject;
        if (!evict) {
            break;
        }
        [self.warmAccessOrder removeObjectAtIndex:0];
        [self.warmByVideoId removeObjectForKey:evict];
    }
    AVPlayerItem *pi = [AVPlayerItem playerItemWithURL:url];
    pi.preferredForwardBufferDuration = 2.0;
    self.warmByVideoId[item.videoId] = pi;
    [self.warmAccessOrder addObject:item.videoId];
}

- (AVPlayerItem *)takePrewarmedItemForVideoId:(NSString *)videoId playURL:(NSString *)playURL {
    if (videoId.length == 0) {
        return nil;
    }
    AVPlayerItem *pi = self.warmByVideoId[videoId];
    if (!pi) {
        return nil;
    }
    NSURL *assetURL = [(AVURLAsset *)pi.asset URL];
    if (!assetURL || playURL.length == 0) {
        return nil;
    }
    if (![assetURL.absoluteString isEqualToString:playURL]) {
        return nil;
    }
    [self.warmByVideoId removeObjectForKey:videoId];
    [self.warmAccessOrder removeObject:videoId];
    return pi;
}

- (void)invalidateAllWarmItems {
    [self.warmByVideoId removeAllObjects];
    [self.warmAccessOrder removeAllObjects];
}

@end
