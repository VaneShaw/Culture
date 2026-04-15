//
//  NSDictionary+YTSafe.m
//  YiTongProject
//

#import "NSDictionary+YTSafe.h"

@implementation NSDictionary (YTSafe)

static inline id YTSafeRawValue(id self_, id<NSCopying> key) {
    if (![(id)self_ isKindOfClass:[NSDictionary class]]) return nil;
    id v = [(NSDictionary *)self_ objectForKey:key];
    if (v == nil || v == (id)kCFNull) return nil;
    return v;
}

- (NSDictionary *)yt_dictionaryForKey:(id<NSCopying>)key {
    id v = YTSafeRawValue(self, key);
    return [v isKindOfClass:[NSDictionary class]] ? (NSDictionary *)v : @{};
}

- (NSArray *)yt_arrayForKey:(id<NSCopying>)key {
    id v = YTSafeRawValue(self, key);
    return [v isKindOfClass:[NSArray class]] ? (NSArray *)v : @[];
}

- (NSString *)yt_stringForKey:(id<NSCopying>)key {
    id v = YTSafeRawValue(self, key);
    if ([v isKindOfClass:[NSString class]]) return (NSString *)v;
    if ([v isKindOfClass:[NSNumber class]]) return [NSString stringWithFormat:@"%@", v];
    return @"";
}

- (nullable NSNumber *)yt_numberForKey:(id<NSCopying>)key {
    id v = YTSafeRawValue(self, key);
    if ([v isKindOfClass:[NSNumber class]]) return (NSNumber *)v;
    if ([v isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) return nil;
        static NSNumberFormatter *formatter;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            formatter = [[NSNumberFormatter alloc] init];
            formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.numberStyle = NSNumberFormatterDecimalStyle;
        });
        return [formatter numberFromString:s];
    }
    return nil;
}

- (NSInteger)yt_integerForKey:(id<NSCopying>)key defaultValue:(NSInteger)defaultValue {
    id v = YTSafeRawValue(self, key);
    if ([v isKindOfClass:[NSNumber class]]) return [(NSNumber *)v integerValue];
    if ([v isKindOfClass:[NSString class]]) {
        NSString *s = [(NSString *)v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (s.length == 0) return defaultValue;
        return (NSInteger)[s integerValue];
    }
    return defaultValue;
}

- (nullable id)yt_objectForKey:(id<NSCopying>)key class:(Class)cls {
    if (!cls) return nil;
    id v = YTSafeRawValue(self, key);
    return [v isKindOfClass:cls] ? v : nil;
}

@end
