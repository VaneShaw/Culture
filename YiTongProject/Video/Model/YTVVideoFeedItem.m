//
//  YTVVideoFeedItem.m
//  YiTongProject
//

#import "YTVVideoFeedItem.h"

@implementation YTVVideoFeedItem

+ (instancetype)itemWithDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]] || dict.count == 0) {
        return nil;
    }
    YTVVideoFeedItem *item = [[YTVVideoFeedItem alloc] init];
    // /video/feed/*: video_id, url, summary, category
    // /video/list: tale_id, video_url, content, type
    item.videoId = [self ytv_string:(dict[@"video_id"] ?: dict[@"tale_id"] ?: dict[@"id"])];
    item.title = [self ytv_string:dict[@"title"]];
    item.category = [self ytv_string:(dict[@"category"] ?: dict[@"type"] ?: dict[@"tab"])];
    item.summary = [self ytv_string:(dict[@"summary"] ?: dict[@"content"] ?: dict[@"desc"])];
    item.playURL = [self ytv_string:(dict[@"url"] ?: dict[@"video_url"] ?: dict[@"videoUrl"])];
    item.fullTextURL = [self ytv_string:dict[@"full_text_url"]];
    item.coverURL = [self ytv_string:(dict[@"cover_url"] ?: dict[@"head_image"] ?: dict[@"cover"] ?: dict[@"headImage"])];
    item.shareURL = [self ytv_string:dict[@"share_url"]];
    id fav = dict[@"is_favorite"];
    if ([fav isKindOfClass:[NSNumber class]]) {
        item.isFavorite = [fav boolValue];
    }
    id fc = dict[@"favorites_count"];
    if ([fc isKindOfClass:[NSNumber class]]) {
        item.favoritesCount = [fc integerValue];
    } else {
        item.favoritesCount = -1;
    }
    id sc = dict[@"share_count"] ?: dict[@"shares_count"] ?: dict[@"shareCount"];
    if ([sc isKindOfClass:[NSNumber class]]) {
        item.shareCount = [sc integerValue];
    } else {
        item.shareCount = -1;
    }
    id dur = dict[@"duration_ms"];
    if ([dur isKindOfClass:[NSNumber class]]) {
        item.durationMs = [dur integerValue];
    }
    item.cursorToken = [self ytv_string:dict[@"cursor_token"]];
    id fam = dict[@"favorited_at_ms"] ?: dict[@"favoritedAtMs"] ?: dict[@"favorited_at"];
    if ([fam isKindOfClass:[NSNumber class]]) {
        item.favoritedAtMs = [(NSNumber *)fam longLongValue];
    }
    id vwObj = dict[@"video_width"] ?: dict[@"width"];
    id vhObj = dict[@"video_height"] ?: dict[@"height"];
    double vw = 0;
    double vh = 0;
    if ([vwObj isKindOfClass:[NSNumber class]]) {
        vw = [(NSNumber *)vwObj doubleValue];
    } else if ([vwObj isKindOfClass:[NSString class]]) {
        vw = [(NSString *)vwObj doubleValue];
    }
    if ([vhObj isKindOfClass:[NSNumber class]]) {
        vh = [(NSNumber *)vhObj doubleValue];
    } else if ([vhObj isKindOfClass:[NSString class]]) {
        vh = [(NSString *)vhObj doubleValue];
    }
    if (vw > 0.5 && vh > 0.5) {
        item.ytv_naturalVideoWidth = (CGFloat)vw;
        item.ytv_naturalVideoHeight = (CGFloat)vh;
        item.ytv_hasNaturalVideoSize = YES;
    }
    if (item.videoId.length == 0) {
        return nil;
    }
    return item;
}

+ (NSString *)ytv_string:(id)obj {
    if ([obj isKindOfClass:[NSString class]]) {
        return (NSString *)obj;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj stringValue];
    }
    return @"";
}

- (NSDictionary *)ytv_toSnapshotDictionary {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    if (self.videoId.length) {
        d[@"video_id"] = self.videoId;
    }
    if (self.title.length) {
        d[@"title"] = self.title;
    }
    if (self.category.length) {
        d[@"category"] = self.category;
    }
    if (self.summary.length) {
        d[@"summary"] = self.summary;
    }
    if (self.playURL.length) {
        d[@"url"] = self.playURL;
    }
    if (self.fullTextURL.length) {
        d[@"full_text_url"] = self.fullTextURL;
    }
    if (self.coverURL.length) {
        d[@"cover_url"] = self.coverURL;
    }
    if (self.shareURL.length) {
        d[@"share_url"] = self.shareURL;
    }
    d[@"is_favorite"] = @(self.isFavorite);
    if (self.favoritesCount >= 0) {
        d[@"favorites_count"] = @(self.favoritesCount);
    }
    if (self.shareCount >= 0) {
        d[@"share_count"] = @(self.shareCount);
    }
    d[@"duration_ms"] = @(self.durationMs);
    if (self.cursorToken.length) {
        d[@"cursor_token"] = self.cursorToken;
    }
    if (self.favoritedAtMs > 0) {
        d[@"favorited_at_ms"] = @(self.favoritedAtMs);
    }
    return [d copy];
}

- (BOOL)ytv_isLandscapeNaturalVideo {
    if (!self.ytv_hasNaturalVideoSize) {
        return NO;
    }
    CGFloat W = self.ytv_naturalVideoWidth;
    CGFloat H = self.ytv_naturalVideoHeight;
    if (W < 1.0 || H < 1.0) {
        return NO;
    }
    return W > H + 0.5;
}

@end
