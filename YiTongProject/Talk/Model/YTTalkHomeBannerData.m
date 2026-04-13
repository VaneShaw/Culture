//
//  YTTalkHomeBannerData.m
//  YiTongProject
//

#import "YTTalkHomeBannerData.h"
#import "YTTalkHomeBannerImageItem.h"
#import "YTTalkHomeSceneTabItem.h"

@implementation YTTalkHomeBannerData

+ (NSArray<NSString *> *)yt_sortedStringValuesFromKeyedObject:(NSDictionary *)dict keyPrefix:(NSString *)prefix {
    if (![dict isKindOfClass:[NSDictionary class]] || prefix.length == 0) return @[];

    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    for (NSString *k in dict) {
        if (![k isKindOfClass:[NSString class]]) continue;
        if ([k hasPrefix:prefix]) [keys addObject:k];
    }
    [keys sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        NSString *sa = [a substringFromIndex:prefix.length];
        NSString *sb = [b substringFromIndex:prefix.length];
        NSInteger na = sa.integerValue;
        NSInteger nb = sb.integerValue;
        if (na != nb) {
            return na < nb ? NSOrderedAscending : NSOrderedDescending;
        }
        return [a compare:b];
    }];

    NSMutableArray<NSString *> *out = [NSMutableArray array];
    for (NSString *k in keys) {
        id v = dict[k];
        if (![v isKindOfClass:[NSString class]]) continue;
        NSString *s = [(NSString *)v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) continue;
        [out addObject:s];
    }
    return [out copy];
}

/// scene_tab_list：key → tab_type，value → 展示文案；顺序与接口 JSON 中键顺序一致（依赖 NSJSONReadingOrderedCollections，见 NetWorkTool）
+ (NSArray<YTTalkHomeSceneTabItem *> *)yt_sceneTabItemsFromSceneTabListDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return @[];
    }
    NSMutableArray<YTTalkHomeSceneTabItem *> *tabs = [NSMutableArray array];
    for (id k in dict) {
        if (![k isKindOfClass:[NSString class]]) {
            continue;
        }
        NSString *key = [(NSString *)k stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (key.length == 0) {
            continue;
        }
        id rawVal = dict[k];
        NSString *display = nil;
        if ([rawVal isKindOfClass:[NSString class]]) {
            display = [(NSString *)rawVal stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        } else if ([rawVal isKindOfClass:[NSNumber class]]) {
            display = [(NSNumber *)rawVal stringValue];
        }
        YTTalkHomeSceneTabItem *item = [YTTalkHomeSceneTabItem itemWithTypeIdentifier:key];
        if (display.length > 0) {
            item.overrideDisplayTitle = display;
        }
        [tabs addObject:item];
    }
    return [tabs copy];
}

+ (instancetype)dataByParsingAPIDictionary:(id)payload {
    YTTalkHomeBannerData *model = [[YTTalkHomeBannerData alloc] init];
    if (![payload isKindOfClass:[NSDictionary class]]) {
        model.sceneTabs = @[ [YTTalkHomeSceneTabItem defaultAllTabItem] ];
        model.bannerImages = @[];
        return model;
    }
    NSDictionary *root = (NSDictionary *)payload;

    id bannerRaw = root[@"banner_imgs"];
    id tabRaw = root[@"scene_tab_list"];

    NSArray<NSString *> *urls = [self yt_sortedStringValuesFromKeyedObject:[bannerRaw isKindOfClass:[NSDictionary class]] ? (NSDictionary *)bannerRaw : nil
                                                                 keyPrefix:@"img_"];

    NSMutableArray<YTTalkHomeBannerImageItem *> *images = [NSMutableArray array];
    for (NSString *url in urls) {
        YTTalkHomeBannerImageItem *one = [[YTTalkHomeBannerImageItem alloc] init];
        one.imageURLString = url;
        one.title = @"";
        one.subtitle = @"";
        one.tagText = @"";
        [images addObject:one];
    }
    model.bannerImages = [images copy];

    NSArray<YTTalkHomeSceneTabItem *> *tabItems = [self yt_sceneTabItemsFromSceneTabListDictionary:[tabRaw isKindOfClass:[NSDictionary class]] ? (NSDictionary *)tabRaw : nil];
    if (tabItems.count == 0) {
        model.sceneTabs = @[ [YTTalkHomeSceneTabItem defaultAllTabItem] ];
    } else {
        model.sceneTabs = tabItems;
    }

    return model;
}

+ (instancetype)emptyDefaultAllTabOnly {
    YTTalkHomeBannerData *model = [[YTTalkHomeBannerData alloc] init];
    model.sceneTabs = @[ [YTTalkHomeSceneTabItem defaultAllTabItem] ];
    model.bannerImages = @[];
    return model;
}

@end
