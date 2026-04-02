//
//  YTVFeedPageResult.m
//  YiTongProject
//

#import "YTVFeedPageResult.h"
#import "YTVVideoFeedItem.h"

@implementation YTVFeedPageResult

+ (instancetype)resultWithDataObject:(id)dataObject {
    if (![dataObject isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *dict = (NSDictionary *)dataObject;
    NSMutableArray<YTVVideoFeedItem *> *items = [NSMutableArray array];
    id rawItems = dict[@"items"];
    if ([rawItems isKindOfClass:[NSArray class]]) {
        for (id obj in (NSArray *)rawItems) {
            if ([obj isKindOfClass:[NSDictionary class]]) {
                YTVVideoFeedItem *it = [YTVVideoFeedItem itemWithDictionary:obj];
                if (it) {
                    [items addObject:it];
                }
            }
        }
    }
    YTVFeedPageResult *r = [[YTVFeedPageResult alloc] init];
    r.items = [items copy];
    id nc = dict[@"next_cursor"] ?: dict[@"nextCursor"];
    r.nextCursor = [nc isKindOfClass:[NSString class]] ? (NSString *)nc : @"";
    id hm = dict[@"has_more"] ?: dict[@"hasMore"];
    if ([hm isKindOfClass:[NSNumber class]]) {
        r.hasMore = [hm boolValue];
    } else {
        r.hasMore = YES;
    }
    id ttl = dict[@"ttl_sec"] ?: dict[@"ttlSec"];
    if ([ttl isKindOfClass:[NSNumber class]]) {
        r.ttlSec = [ttl integerValue];
    } else {
        r.ttlSec = 0;
    }
    return r;
}

@end
