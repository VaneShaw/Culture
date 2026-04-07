//
//  YTVShortVideoFeedViewModel.m
//  YiTongProject
//

#import "YTVShortVideoFeedViewModel.h"
#import "YTVFeedRepository.h"
#import "YTVFeedPageResult.h"
#import "YTVVideoFeedItem.h"
#import "YTVFeedSnapshotCache.h"
#import "YTVFeedResumeCache.h"
#import "YTVVideoFavoritesRepository.h"

static const NSInteger kYTVFeedPageSize = 10;
static const NSInteger kYTVFeedLowWaterMark = 5;
static const NSInteger kYTVNextDedupeMaxExtraFetches = 3;

@interface YTVShortVideoFeedViewModel ()
@property (nonatomic, copy, readwrite) NSString *categoryKey;
@property (nonatomic, assign, readwrite) YTVShortVideoFeedSource feedSource;
@property (nonatomic, assign, readwrite) YTVShortVideoFeedState state;
@property (nonatomic, strong) NSMutableArray<YTVVideoFeedItem *> *mutableItems;
@property (nonatomic, copy, readwrite, nullable) NSString *lastErrorMessage;
@property (nonatomic, copy, nullable) NSString *nextCursor;
@property (nonatomic, assign, readwrite) BOOL hasMore;
@property (nonatomic, assign) BOOL isLoadingNext;
@property (nonatomic, strong) YTVFeedRepository *repository;
@property (nonatomic, strong) YTVVideoFavoritesRepository *favoritesRepository;
@property (nonatomic, copy, nullable) NSArray<YTVVideoFeedItem *> *favoritesSeedItems;
@property (nonatomic, copy, nullable) NSString *favoritesEntryVideoId;
@property (nonatomic, assign, readwrite) BOOL ytv_categoryBootstrapNetworkFinished;
@property (nonatomic, assign, readwrite) BOOL ytv_bootstrapLoadedFromSnapshot;
@property (nonatomic, copy, readwrite, nullable) NSString *ytv_initialVideoSourceLabel;
@property (nonatomic, assign) NSInteger ytv_resumeInitialDisplayIndex;
@end

@implementation YTVShortVideoFeedViewModel

+ (NSString *)ytv_userFacingMessageForFeedError:(NSError *)error {
    if (error == nil) {
        return @"";
    }
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        return error.localizedDescription.length > 0 ? error.localizedDescription : NSLocalizedString(@"YTV_feed_error_network", @"");
    }
    if ([error.domain isEqualToString:@"YTVFeedRepository"] || [error.domain isEqualToString:@"YTVVideoFavoritesRepository"]) {
        long c = (long)error.code;
        if (c >= 400 && c < 500) {
            return error.localizedDescription.length > 0 ? error.localizedDescription : NSLocalizedString(@"YTV_feed_error_4xx", @"");
        }
        if (c >= 500 && c < 600) {
            return error.localizedDescription.length > 0 ? error.localizedDescription : NSLocalizedString(@"YTV_feed_error_5xx", @"");
        }
    }
    return error.localizedDescription.length > 0 ? error.localizedDescription : NSLocalizedString(@"Request failed", @"");
}

/// 从磁盘恢复列表与游标；有合法文件即返回 YES（含空列表快照）
- (BOOL)ytv_applySnapshotIfAvailable {
    NSDictionary *snap = [YTVFeedSnapshotCache loadSnapshotDictionaryForCategoryKey:self.categoryKey];
    if (!snap) {
        return NO;
    }
    id rawItems = snap[@"items"];
    if (![rawItems isKindOfClass:[NSArray class]]) {
        return NO;
    }
    [self.mutableItems removeAllObjects];
    for (id o in (NSArray *)rawItems) {
        if ([o isKindOfClass:[NSDictionary class]]) {
            YTVVideoFeedItem *it = [YTVVideoFeedItem itemWithDictionary:o];
            if (it) {
                [self.mutableItems addObject:it];
            }
        }
    }
    id nc = snap[@"nextCursor"];
    self.nextCursor = [nc isKindOfClass:[NSString class]] ? (NSString *)nc : @"";
    id hm = snap[@"hasMore"];
    self.hasMore = [hm isKindOfClass:[NSNumber class]] ? [(NSNumber *)hm boolValue] : YES;
    if (self.mutableItems.count == 0) {
        self.state = YTVShortVideoFeedStateEmpty;
    } else {
        self.state = YTVShortVideoFeedStateReady;
    }
    [self ytv_refreshInitialDisplayIndexFromResumeCache];
    return YES;
}

- (void)ytv_persistSnapshot {
    [YTVFeedSnapshotCache saveCategoryKey:self.categoryKey
                                    items:self.mutableItems
                               nextCursor:self.nextCursor ?: @""
                                  hasMore:self.hasMore];
}

- (instancetype)initWithCategoryKey:(NSString *)categoryKey {
    self = [super init];
    if (self) {
        _categoryKey = [categoryKey copy] ?: @"";
        _feedSource = YTVShortVideoFeedSourceCategory;
        _state = YTVShortVideoFeedStateIdle;
        _mutableItems = [NSMutableArray array];
        _hasMore = YES;
        _repository = [[YTVFeedRepository alloc] init];
        _favoritesRepository = [[YTVVideoFavoritesRepository alloc] init];
        _ytv_categoryBootstrapNetworkFinished = NO;
        _ytv_bootstrapLoadedFromSnapshot = NO;
        _ytv_resumeInitialDisplayIndex = 0;
    }
    return self;
}

+ (instancetype)favoritesFeedViewModelWithSeedItems:(NSArray<YTVVideoFeedItem *> *)seedItems
                                       entryVideoId:(NSString *)entryVideoId {
    YTVShortVideoFeedViewModel *vm = [[YTVShortVideoFeedViewModel alloc] initWithCategoryKey:@"__favorites__"];
    vm.feedSource = YTVShortVideoFeedSourceFavorites;
    vm.favoritesSeedItems = seedItems ? [seedItems copy] : @[];
    vm.favoritesEntryVideoId = [entryVideoId copy];
    vm.ytv_categoryBootstrapNetworkFinished = YES;
    return vm;
}

- (NSInteger)ytv_initialDisplayIndex {
    if (self.feedSource == YTVShortVideoFeedSourceFavorites) {
        NSString *vid = self.favoritesEntryVideoId;
        if (vid.length == 0) {
            return 0;
        }
        NSUInteger i = 0;
        for (YTVVideoFeedItem *it in self.mutableItems) {
            if ([it.videoId isEqualToString:vid]) {
                return (NSInteger)i;
            }
            i++;
        }
        return 0;
    }
    return MAX(self.ytv_resumeInitialDisplayIndex, 0);
}

- (void)ytv_recordLastViewedVideoId:(NSString *)videoId
                         playURL:(NSString *)playURL
                       indexHint:(NSInteger)indexHint {
    if (self.feedSource != YTVShortVideoFeedSourceCategory) {
        return;
    }
    [YTVFeedResumeCache saveCategoryKey:self.categoryKey
                        lastViewedVideoId:videoId
                         lastViewedPlayURL:playURL
                       lastViewedIndexHint:indexHint];
}

- (void)ytv_refreshInitialDisplayIndexFromResumeCache {
    self.ytv_resumeInitialDisplayIndex = 0;
    self.ytv_initialVideoSourceLabel = @"snapshot_first";
    NSDictionary *resume = [YTVFeedResumeCache loadResumeDictionaryForCategoryKey:self.categoryKey];
    if (![resume isKindOfClass:[NSDictionary class]] || self.mutableItems.count == 0) {
        return;
    }
    NSString *videoId = [resume[@"lastViewedVideoId"] isKindOfClass:[NSString class]] ? resume[@"lastViewedVideoId"] : @"";
    NSNumber *indexHint = [resume[@"lastViewedIndexHint"] isKindOfClass:[NSNumber class]] ? resume[@"lastViewedIndexHint"] : nil;
    if (videoId.length > 0) {
        NSUInteger i = 0;
        for (YTVVideoFeedItem *it in self.mutableItems) {
            if ([it.videoId isEqualToString:videoId]) {
                self.ytv_resumeInitialDisplayIndex = (NSInteger)i;
                self.ytv_initialVideoSourceLabel = @"resume_last_viewed";
                return;
            }
            i++;
        }
    }
    if (indexHint != nil) {
        NSInteger idx = MAX(indexHint.integerValue, 0);
        idx = MIN(idx, (NSInteger)self.mutableItems.count - 1);
        self.ytv_resumeInitialDisplayIndex = idx;
        self.ytv_initialVideoSourceLabel = @"resume_index_hint";
    }
}

- (NSArray<YTVVideoFeedItem *> *)items {
    return [_mutableItems copy];
}

- (BOOL)ytv_isLoadingNext {
    return _isLoadingNext;
}

- (void)loadBootstrapWithCompletion:(void (^)(void))completion {
    if (self.feedSource == YTVShortVideoFeedSourceFavorites) {
        [self ytv_loadBootstrapFavoritesWithCompletion:completion];
        return;
    }
    self.ytv_categoryBootstrapNetworkFinished = NO;
    self.ytv_bootstrapLoadedFromSnapshot = NO;
    self.ytv_initialVideoSourceLabel = @"network_first";
    BOOL hadDisk = [self ytv_applySnapshotIfAvailable];
    self.ytv_bootstrapLoadedFromSnapshot = hadDisk;
    if (!hadDisk) {
        self.state = YTVShortVideoFeedStateLoading;
    } else if (completion) {
        completion();
    }
    self.lastErrorMessage = nil;
    __weak typeof(self) weakSelf = self;
    [self.repository fetchBootstrapWithCategoryKey:self.categoryKey
                                            cursor:nil
                                          pageSize:kYTVFeedPageSize
                                     lastVideoId:nil
                                          completion:^(YTVFeedPageResult * _Nullable result, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            void (^done)(void) = ^{
                if (completion) {
                    completion();
                }
            };
            if (error) {
                self.ytv_categoryBootstrapNetworkFinished = YES;
                if (self.mutableItems.count > 0) {
                    self.state = YTVShortVideoFeedStateReady;
                    done();
                    return;
                }
                self.state = YTVShortVideoFeedStateError;
                self.lastErrorMessage = [[self class] ytv_userFacingMessageForFeedError:error];
                done();
                return;
            }
            [self.mutableItems removeAllObjects];
            if (result.items.count > 0) {
                NSMutableSet<NSString *> *seen = [NSMutableSet set];
                for (YTVVideoFeedItem *it in result.items) {
                    if (it.videoId.length > 0) {
                        if ([seen containsObject:it.videoId]) {
                            continue;
                        }
                        [seen addObject:it.videoId];
                    }
                    [self.mutableItems addObject:it];
                }
            }
            self.nextCursor = result.nextCursor ?: @"";
            self.hasMore = [self.class ytv_hasMoreAfterPage:result];
            if (self.mutableItems.count == 0) {
                self.state = YTVShortVideoFeedStateEmpty;
            } else {
                self.state = YTVShortVideoFeedStateReady;
            }
            self.ytv_resumeInitialDisplayIndex = 0;
            self.ytv_initialVideoSourceLabel = @"network_first";
            [self ytv_persistSnapshot];
            self.ytv_categoryBootstrapNetworkFinished = YES;
            done();
        });
    }];
}

- (void)ytv_loadBootstrapFavoritesWithCompletion:(void (^)(void))completion {
    self.lastErrorMessage = nil;
    if (self.favoritesSeedItems.count > 0) {
        [self.mutableItems removeAllObjects];
        for (YTVVideoFeedItem *it in self.favoritesSeedItems) {
            if ([it isKindOfClass:[YTVVideoFeedItem class]]) {
                it.isFavorite = YES;
                [self.mutableItems addObject:it];
            }
        }
        self.nextCursor = @"";
        self.hasMore = YES;
        self.state = self.mutableItems.count > 0 ? YTVShortVideoFeedStateReady : YTVShortVideoFeedStateEmpty;
        [self ytv_persistSnapshot];
        if (completion) {
            completion();
        }
        return;
    }
    BOOL hadDisk = [self ytv_applySnapshotIfAvailable];
    if (!hadDisk) {
        self.state = YTVShortVideoFeedStateLoading;
    } else if (completion) {
        completion();
    }
    __weak typeof(self) weakSelf = self;
    [self.favoritesRepository fetchListWithCursor:nil
                                         pageSize:kYTVFeedPageSize
                                    lastVideoId:nil
                                       completion:^(YTVFeedPageResult * _Nullable result, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            void (^done)(void) = ^{
                if (completion) {
                    completion();
                }
            };
            if (error) {
                if (self.mutableItems.count > 0) {
                    self.state = YTVShortVideoFeedStateReady;
                    done();
                    return;
                }
                self.state = YTVShortVideoFeedStateError;
                self.lastErrorMessage = [[self class] ytv_userFacingMessageForFeedError:error];
                done();
                return;
            }
            [self.mutableItems removeAllObjects];
            if (result.items.count > 0) {
                NSMutableSet<NSString *> *seen = [NSMutableSet set];
                for (YTVVideoFeedItem *it in result.items) {
                    if (it.videoId.length > 0) {
                        if ([seen containsObject:it.videoId]) {
                            continue;
                        }
                        [seen addObject:it.videoId];
                    }
                    it.isFavorite = YES;
                    [self.mutableItems addObject:it];
                }
            }
            self.nextCursor = result.nextCursor ?: @"";
            self.hasMore = [self.class ytv_hasMoreAfterPage:result];
            if (self.mutableItems.count == 0) {
                self.state = YTVShortVideoFeedStateEmpty;
            } else {
                self.state = YTVShortVideoFeedStateReady;
            }
            self.ytv_resumeInitialDisplayIndex = 0;
            self.ytv_initialVideoSourceLabel = @"network_first";
            [self ytv_persistSnapshot];
            done();
        });
    }];
}

+ (BOOL)ytv_hasMoreAfterPage:(YTVFeedPageResult *)result {
    if (result == nil || result.items.count == 0) {
        return NO;
    }
    if ((NSInteger)result.items.count >= kYTVFeedPageSize) {
        return YES;
    }
    return result.hasMore;
}

- (NSUInteger)ytv_appendUniqueItemsFromPageResult:(YTVFeedPageResult *)result {
    if (result.items.count == 0) {
        return 0;
    }
    NSMutableSet<NSString *> *existing = [NSMutableSet set];
    for (YTVVideoFeedItem *it in self.mutableItems) {
        if (it.videoId.length > 0) {
            [existing addObject:it.videoId];
        }
    }
    NSUInteger added = 0;
    for (YTVVideoFeedItem *it in result.items) {
        if (it.videoId.length > 0 && [existing containsObject:it.videoId]) {
            continue;
        }
        if (self.feedSource == YTVShortVideoFeedSourceFavorites) {
            it.isFavorite = YES;
        }
        if (it.videoId.length > 0) {
            [existing addObject:it.videoId];
        }
        [self.mutableItems addObject:it];
        added++;
    }
    return added;
}

- (void)ytv_fetchNextDedupingAttempt:(NSInteger)attempt
                          anyAppended:(BOOL *)anyAppendedPtr
                           completion:(void (^)(NSError *_Nullable))completion {
    YTVVideoFeedItem *last = self.mutableItems.lastObject;
    NSString *cursor = self.nextCursor ?: @"";
    __weak typeof(self) weakSelf = self;
    void (^handleResult)(YTVFeedPageResult * _Nullable, NSError * _Nullable) = ^(YTVFeedPageResult * _Nullable result, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                if (completion) {
                    completion(error);
                }
                return;
            }
            if (error) {
                if (completion) {
                    completion(error);
                }
                return;
            }
            NSUInteger added = [self ytv_appendUniqueItemsFromPageResult:result];
            if (added > 0 && anyAppendedPtr != NULL) {
                *anyAppendedPtr = YES;
            }
            self.nextCursor = result.nextCursor ?: self.nextCursor;
            if (result.items.count == 0) {
                self.hasMore = NO;
            } else {
                self.hasMore = [self.class ytv_hasMoreAfterPage:result];
            }
            [self ytv_persistSnapshot];
            BOOL dupPage = (added == 0 && result.items.count > 0);
            if (dupPage && self.hasMore && attempt < kYTVNextDedupeMaxExtraFetches) {
                [self ytv_fetchNextDedupingAttempt:attempt + 1 anyAppended:anyAppendedPtr completion:completion];
            } else {
                if (dupPage && added == 0) {
                    self.hasMore = NO;
                    [self ytv_persistSnapshot];
                }
                if (completion) {
                    completion(nil);
                }
            }
        });
    };
    if (self.feedSource == YTVShortVideoFeedSourceFavorites) {
        [self.favoritesRepository fetchListWithCursor:cursor
                                             pageSize:kYTVFeedPageSize
                                        lastVideoId:last.videoId
                                           completion:handleResult];
    } else {
        [self.repository fetchNextWithCategoryKey:self.categoryKey
                                           cursor:cursor
                                         pageSize:kYTVFeedPageSize
                                    lastVideoId:last.videoId
                                       completion:handleResult];
    }
}

- (void)loadNextPageIfNeededForDisplayIndex:(NSInteger)displayIndex completion:(YTVFeedLoadNextCompletion)completion {
    if (!self.hasMore || self.isLoadingNext || self.mutableItems.count == 0) {
        if (completion) {
            completion(NO, 0, nil);
        }
        return;
    }
    NSInteger remainingAfter = (NSInteger)self.mutableItems.count - 1 - displayIndex;
    if (remainingAfter > kYTVFeedLowWaterMark) {
        if (completion) {
            completion(NO, 0, nil);
        }
        return;
    }
    self.isLoadingNext = YES;
    NSUInteger oldCount = self.mutableItems.count;
    __block BOOL anyAppended = NO;
    __weak typeof(self) weakSelf = self;
    [self ytv_fetchNextDedupingAttempt:0 anyAppended:&anyAppended completion:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        BOOL appended = anyAppended;
        if (self) {
            self.isLoadingNext = NO;
        }
        if (completion) {
            NSUInteger appendedCount = 0;
            if (self.mutableItems.count >= oldCount) {
                appendedCount = self.mutableItems.count - oldCount;
            }
            completion(appended, appendedCount, error);
        }
    }];
}

- (NSUInteger)numberOfItems {
    return self.mutableItems.count;
}

- (YTVVideoFeedItem *)itemAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.mutableItems.count) {
        return nil;
    }
    return self.mutableItems[(NSUInteger)index];
}

- (void)toggleFavoriteAtDisplayIndex:(NSInteger)index
                          completion:(void (^)(BOOL success, NSString * _Nullable message))completion {
    if (index < 0 || index >= (NSInteger)self.mutableItems.count) {
        if (completion) {
            completion(NO, nil);
        }
        return;
    }
    YTVVideoFeedItem *item = self.mutableItems[(NSUInteger)index];
    if (item.videoId.length == 0) {
        if (completion) {
            completion(NO, nil);
        }
        return;
    }
    NSString *videoId = [item.videoId copy];
    BOOL previousFavorite = item.isFavorite;
    item.isFavorite = !previousFavorite;
    [self ytv_persistSnapshot];
    __weak typeof(self) weakSelf = self;
    [self.favoritesRepository toggleFavoriteWithVideoId:videoId completion:^(BOOL success, BOOL isFavorite, NSInteger favoritesCount, NSString *message) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            if (completion) {
                completion(NO, nil);
            }
            return;
        }
        YTVVideoFeedItem *live = [self itemAtIndex:index];
        if (!live || ![live.videoId isEqualToString:videoId]) {
            if (completion) {
                completion(success, message);
            }
            return;
        }
        if (success) {
            live.isFavorite = isFavorite;
            if (favoritesCount >= 0) {
                live.favoritesCount = favoritesCount;
            }
            if (self.feedSource == YTVShortVideoFeedSourceFavorites && !isFavorite) {
                NSInteger rm = index;
                if (rm >= 0 && rm < (NSInteger)self.mutableItems.count
                    && [self.mutableItems[(NSUInteger)rm].videoId isEqualToString:videoId]) {
                    [self.mutableItems removeObjectAtIndex:(NSUInteger)rm];
                }
            }
            [self ytv_persistSnapshot];
            if (completion) {
                completion(YES, nil);
            }
        } else {
            live.isFavorite = previousFavorite;
            [self ytv_persistSnapshot];
            if (completion) {
                completion(NO, message.length ? message : NSLocalizedString(@"YTV_favorite_failed", @""));
            }
        }
    }];
}

- (NSInteger)ytv_indexOfVideoId:(NSString *)videoId {
    if (videoId.length == 0) {
        return -1;
    }
    NSUInteger i = 0;
    for (YTVVideoFeedItem *it in self.mutableItems) {
        if ([it.videoId isEqualToString:videoId]) {
            return (NSInteger)i;
        }
        i++;
    }
    return -1;
}

- (void)ytv_insertItemAtHeadDeduping:(YTVVideoFeedItem *)item {
    if (self.feedSource != YTVShortVideoFeedSourceCategory || !item || item.videoId.length == 0) {
        return;
    }
    NSString *vid = item.videoId;
    for (NSInteger i = (NSInteger)self.mutableItems.count - 1; i >= 0; i--) {
        if ([self.mutableItems[(NSUInteger)i].videoId isEqualToString:vid]) {
            [self.mutableItems removeObjectAtIndex:(NSUInteger)i];
        }
    }
    [self.mutableItems insertObject:item atIndex:0];
    self.state = YTVShortVideoFeedStateReady;
    self.lastErrorMessage = nil;
    [self ytv_persistSnapshot];
}

- (void)ytv_fetchInsertVideoAtHeadIfMissing:(NSString *)videoId
                                 completion:(void (^)(BOOL, NSString * _Nullable))completion {
    if (self.feedSource != YTVShortVideoFeedSourceCategory) {
        if (completion) {
            completion(NO, nil);
        }
        return;
    }
    if ([self ytv_indexOfVideoId:videoId] >= 0) {
        if (completion) {
            completion(NO, nil);
        }
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.repository fetchVideoItemById:videoId completion:^(YTVVideoFeedItem * _Nullable item, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                if (completion) {
                    completion(NO, nil);
                }
                return;
            }
            if (!item) {
                NSString *msg = error.localizedDescription.length ? error.localizedDescription
                                                                   : NSLocalizedString(@"YTV_deep_link_load_item_failed", @"");
                if (completion) {
                    completion(NO, msg);
                }
                return;
            }
            [self ytv_insertItemAtHeadDeduping:item];
            if (completion) {
                completion(YES, nil);
            }
        });
    }];
}

@end
