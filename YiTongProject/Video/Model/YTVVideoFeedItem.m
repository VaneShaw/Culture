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
    item.videoId = [self ytv_string:dict[@"video_id"]];
    item.title = [self ytv_string:dict[@"title"]];
    item.category = [self ytv_string:dict[@"category"]];
    item.summary = [self ytv_string:dict[@"summary"]];
    item.playURL = [self ytv_string:dict[@"url"]];
    item.fullTextURL = [self ytv_string:dict[@"full_text_url"]];
    item.coverURL = [self ytv_string:dict[@"cover_url"]];
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
    id dur = dict[@"duration_ms"];
    if ([dur isKindOfClass:[NSNumber class]]) {
        item.durationMs = [dur integerValue];
    }
    item.cursorToken = [self ytv_string:dict[@"cursor_token"]];
    id fam = dict[@"favorited_at_ms"] ?: dict[@"favoritedAtMs"] ?: dict[@"favorited_at"];
    if ([fam isKindOfClass:[NSNumber class]]) {
        item.favoritedAtMs = [(NSNumber *)fam longLongValue];
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
    d[@"duration_ms"] = @(self.durationMs);
    if (self.cursorToken.length) {
        d[@"cursor_token"] = self.cursorToken;
    }
    if (self.favoritedAtMs > 0) {
        d[@"favorited_at_ms"] = @(self.favoritedAtMs);
    }
    return [d copy];
}

@end
