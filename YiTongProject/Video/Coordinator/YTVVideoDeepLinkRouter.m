//
//  YTVVideoDeepLinkRouter.m
//  YiTongProject
//

#import "YTVVideoDeepLinkRouter.h"

@interface YTVVideoDeepLinkRouter ()
@property (nonatomic, copy, readwrite, nullable) NSString *videoId;
@property (nonatomic, copy, readwrite, nullable) NSString *categoryKey;
@property (nonatomic, copy, readwrite, nullable) NSString *fromSource;
@end

@implementation YTVVideoDeepLinkRouter

+ (BOOL)ytv_isVideoDeepLinkURL:(NSURL *)url {
    if (url == nil || url.absoluteString.length == 0) {
        return NO;
    }
    NSString *scheme = url.scheme.lowercaseString;
    if ([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"]) {
        NSString *host = url.host.lowercaseString ?: @"";
        if (![host containsString:@"yitong.com"]) {
            return NO;
        }
        NSString *path = url.path.lowercaseString ?: @"";
        return [path containsString:@"/app/video"];
    }
    if ([scheme isEqualToString:@"ytongvideo"]) {
        NSString *host = url.host.lowercaseString ?: @"";
        return [host isEqualToString:@"video"];
    }
    return NO;
}

+ (instancetype)ytv_routerParsingURL:(NSURL *)url {
    if (![self ytv_isVideoDeepLinkURL:url]) {
        return nil;
    }
    YTVVideoDeepLinkRouter *r = [[YTVVideoDeepLinkRouter alloc] init];
    NSURLComponents *comp = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *vid = nil;
    NSString *cat = nil;
    NSString *from = nil;
    for (NSURLQueryItem *q in comp.queryItems) {
        NSString *name = q.name.lowercaseString;
        if ([name isEqualToString:@"id"] || [name isEqualToString:@"video_id"]) {
            if (q.value.length > 0) {
                vid = q.value;
            }
        } else if ([name isEqualToString:@"category"]) {
            if (q.value.length > 0) {
                cat = q.value;
            }
        } else if ([name isEqualToString:@"from"]) {
            if (q.value.length > 0) {
                from = q.value;
            }
        }
    }
    if (vid.length == 0 && comp.path.length > 0) {
        NSString *path = comp.path;
        NSArray<NSString *> *parts = [path componentsSeparatedByString:@"/"];
        for (NSInteger i = (NSInteger)parts.count - 1; i >= 0; i--) {
            NSString *p = parts[(NSUInteger)i];
            if (p.length > 0 && ![p isEqualToString:@"video"] && ![p isEqualToString:@"app"]) {
                vid = p;
                break;
            }
        }
    }
    r.videoId = vid;
    r.categoryKey = cat;
    r.fromSource = from;
    return r;
}

@end
