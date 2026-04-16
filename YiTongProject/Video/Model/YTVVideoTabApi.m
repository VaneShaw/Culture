//
//  YTVVideoTabApi.m
//  YiTongProject
//

#import "YTVVideoTabApi.h"
#import "HttpTools.h"
#import "BaseDataModel.h"
#import "LanguageHelper.h"
#import "HeaderConfig.h"

static NSString * const kYTVVideoTabPath = @"/video/tab";

@implementation YTVVideoTabApi

+ (void)ytv_fetchVideoTabsWithCompletion:(void (^)(NSArray<NSString *> * _Nullable, NSArray<NSString *> * _Nullable, NSError * _Nullable))completion {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:kYTVVideoTabPath parames:params success:^(BOOL success, BaseDataModel *response) {
        if (!success || response == nil) {
            NSInteger code = response ? (NSInteger)response.code : -1;
            NSString *msg = response.msg.length ? response.msg : NSLocalizedString(@"Request failed", @"");
            NSError *err = [NSError errorWithDomain:@"YTVVideoTabApi" code:code userInfo:@{ NSLocalizedDescriptionKey : msg }];
            if (completion) {
                completion(nil, nil, err);
            }
            return;
        }
        id data = response.data;
        if (![data isKindOfClass:[NSDictionary class]]) {
            NSError *err = [NSError errorWithDomain:@"YTVVideoTabApi" code:-2 userInfo:@{ NSLocalizedDescriptionKey : @"invalid tab data" }];
            if (completion) {
                completion(nil, nil, err);
            }
            return;
        }
        NSArray<NSString *> *keys = nil;
        NSArray<NSString *> *titles = nil;
        [self ytv_parseTabPayload:(NSDictionary *)data outKeys:&keys outTitles:&titles];
        if (keys.count == 0) {
            NSError *err = [NSError errorWithDomain:@"YTVVideoTabApi" code:-3 userInfo:@{ NSLocalizedDescriptionKey : @"empty tab keys" }];
            if (completion) {
                completion(nil, nil, err);
            }
            return;
        }
        if (completion) {
            completion(keys, titles, nil);
        }
    } failure:^(NSError *error) {
        NSLog(@"[YTVVideoTab] request failed domain=%@ code=%ld desc=%@", error.domain, (long)error.code, error.localizedDescription);
        if (completion) {
            completion(nil, nil, error);
        }
    }];
}

/// 先按约定顺序输出已知 key，再把 data 中其余 string 非空项按 key 排序追加，保证顺序稳定。
+ (void)ytv_parseTabPayload:(NSDictionary *)data outKeys:(NSArray<NSString *> * _Nonnull * _Nonnull)outKeys outTitles:(NSArray<NSString *> * _Nonnull * _Nonnull)outTitles {
    NSArray<NSString *> *canonical = @[ @"tz", @"recommend", @"idiom", @"myth", @"fengshen" ];
    NSMutableOrderedSet<NSString *> *seen = [[NSMutableOrderedSet alloc] init];
    NSMutableArray<NSString *> *kM = [NSMutableArray array];
    NSMutableArray<NSString *> *tM = [NSMutableArray array];
    for (NSString *canon in canonical) {
        id raw = data[canon];
        if (![raw isKindOfClass:[NSString class]]) {
            continue;
        }
        NSString *title = [(NSString *)raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (title.length == 0) {
            continue;
        }
        [kM addObject:canon];
        [tM addObject:title];
        [seen addObject:canon];
    }
    NSArray<NSString *> *rest = [[data allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *k in rest) {
        if ([seen containsObject:k]) {
            continue;
        }
        id raw = data[k];
        if (![raw isKindOfClass:[NSString class]]) {
            continue;
        }
        NSString *title = [(NSString *)raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (title.length == 0) {
            continue;
        }
        if (![k isKindOfClass:[NSString class]] || k.length == 0) {
            continue;
        }
        [kM addObject:k];
        [tM addObject:title];
    }
    *outKeys = [kM copy];
    *outTitles = [tM copy];
}

@end
