//
//  YTVVideoDiskCacheManager.m
//  YiTongProject
//

#import "YTVVideoDiskCacheManager.h"
#import <CommonCrypto/CommonDigest.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

// 条数/字节略放宽，减少滑到列表后部时 LRU 过早驱逐、首条仍走 network_first 的情况。
static const NSUInteger kYTVVideoDiskCacheMaxItems = 12;
static const unsigned long long kYTVVideoDiskCacheMaxBytes = 256ull * 1024ull * 1024ull;

@interface YTVVideoDiskCacheManager ()
@property (nonatomic, strong) dispatch_queue_t ioQueue;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *manifest;
@property (nonatomic, strong) NSMutableSet<NSString *> *inflightURLs;
- (void)ytv_pruneManifestRemovingMissingFilesLocked;
@end
#pragma clang diagnostic pop

@implementation YTVVideoDiskCacheManager

+ (instancetype)sharedManager {
    static YTVVideoDiskCacheManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YTVVideoDiskCacheManager alloc] initPrivate];
    });
    return manager;
}

- (instancetype)init {
    return [self initPrivate];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _ioQueue = dispatch_queue_create("com.yitong.video.diskcache", DISPATCH_QUEUE_SERIAL);
        _manifest = [NSMutableDictionary dictionaryWithDictionary:[self.class ytv_loadManifest]];
        _inflightURLs = [NSMutableSet set];
    }
    return self;
}

+ (NSURL *)ytv_cacheDirectoryURL {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *base = [fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *dir = [base URLByAppendingPathComponent:@"YTVVideoDiskCache" isDirectory:YES];
    [fm createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

+ (NSURL *)ytv_manifestURL {
    return [[self ytv_cacheDirectoryURL] URLByAppendingPathComponent:@"manifest.plist"];
}

+ (NSDictionary *)ytv_loadManifest {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:[self ytv_manifestURL]];
    return [dict isKindOfClass:[NSDictionary class]] ? dict : @{};
}

- (nullable NSURL *)cachedFileURLForRemoteURLString:(NSString *)remoteURLString {
    if (remoteURLString.length == 0) {
        return nil;
    }
    NSURL *fileURL = [self.class ytv_fileURLForRemoteURLString:remoteURLString];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        [self ytv_touchRemoteURLString:remoteURLString];
        return fileURL;
    }
    return nil;
}

- (void)cacheVideoIfNeededForRemoteURLString:(NSString *)remoteURLString {
    if (remoteURLString.length == 0) {
        return;
    }
    NSURL *remoteURL = [NSURL URLWithString:remoteURLString];
    NSString *scheme = remoteURL.scheme.lowercaseString;
    if (!remoteURL || (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"])) {
        return;
    }
    NSURL *localURL = [self.class ytv_fileURLForRemoteURLString:remoteURLString];
    if ([[NSFileManager defaultManager] fileExistsAtPath:localURL.path]) {
        [self ytv_touchRemoteURLString:remoteURLString];
        return;
    }
    dispatch_async(self.ioQueue, ^{
        if ([self.inflightURLs containsObject:remoteURLString]) {
            return;
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:localURL.path]) {
            self.manifest[remoteURLString] = @([[NSDate date] timeIntervalSince1970]);
            [self.manifest writeToURL:[self.class ytv_manifestURL] atomically:YES];
            return;
        }
        [self.inflightURLs addObject:remoteURLString];
        NSData *data = [NSData dataWithContentsOfURL:remoteURL options:NSDataReadingMappedIfSafe error:nil];
        if (data.length > 0) {
            [data writeToURL:localURL atomically:YES];
            self.manifest[remoteURLString] = @([[NSDate date] timeIntervalSince1970]);
            [self ytv_trimCacheLockedIfNeeded];
        }
        [self.inflightURLs removeObject:remoteURLString];
    });
}

- (void)trimCacheIfNeeded {
    dispatch_async(self.ioQueue, ^{
        [self ytv_trimCacheLockedIfNeeded];
    });
}


- (NSUInteger)cachedItemCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.ioQueue, ^{
        [self ytv_pruneManifestRemovingMissingFilesLocked];
        count = self.manifest.count;
    });
    return count;
}

- (unsigned long long)cachedBytes {
    __block unsigned long long bytes = 0;
    dispatch_sync(self.ioQueue, ^{
        [self ytv_pruneManifestRemovingMissingFilesLocked];
        bytes = [self ytv_totalCachedBytesLocked];
    });
    return bytes;
}

+ (NSURL *)ytv_fileURLForRemoteURLString:(NSString *)remoteURLString {
    NSString *ext = [NSURL URLWithString:remoteURLString].pathExtension;
    if (ext.length == 0) {
        ext = @"mp4";
    }
    NSString *name = [NSString stringWithFormat:@"%@.%@", [self ytv_md5:remoteURLString], ext];
    return [[self ytv_cacheDirectoryURL] URLByAppendingPathComponent:name];
}

+ (NSString *)ytv_md5:(NSString *)string {
    const char *cStr = string.UTF8String;
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x", result[i]];
    }
    return ret;
}


- (unsigned long long)ytv_fileSizeAtURLLocked:(NSURL *)fileURL {
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil];
    NSNumber *size = attrs[NSFileSize];
    return [size isKindOfClass:[NSNumber class]] ? size.unsignedLongLongValue : 0;
}

- (unsigned long long)ytv_totalCachedBytesLocked {
    unsigned long long total = 0;
    for (NSString *key in self.manifest) {
        total += [self ytv_fileSizeAtURLLocked:[self.class ytv_fileURLForRemoteURLString:key]];
    }
    return total;
}

- (void)ytv_touchRemoteURLString:(NSString *)remoteURLString {
    dispatch_async(self.ioQueue, ^{
        self.manifest[remoteURLString] = @([[NSDate date] timeIntervalSince1970]);
        [self.manifest writeToURL:[self.class ytv_manifestURL] atomically:YES];
    });
}

- (void)ytv_pruneManifestRemovingMissingFilesLocked {
    NSArray<NSString *> *keys = [self.manifest.allKeys copy];
    for (NSString *key in keys) {
        NSURL *fileURL = [self.class ytv_fileURLForRemoteURLString:key];
        if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
            [self.manifest removeObjectForKey:key];
        }
    }
}

- (void)ytv_trimCacheLockedIfNeeded {
    [self ytv_pruneManifestRemovingMissingFilesLocked];
    unsigned long long totalBytes = [self ytv_totalCachedBytesLocked];
    while (self.manifest.count > kYTVVideoDiskCacheMaxItems || totalBytes > kYTVVideoDiskCacheMaxBytes) {
        NSString *oldestKey = nil;
        NSTimeInterval oldestValue = DBL_MAX;
        for (NSString *key in self.manifest) {
            NSTimeInterval value = [self.manifest[key] doubleValue];
            if (value < oldestValue) {
                oldestValue = value;
                oldestKey = key;
            }
        }
        if (oldestKey.length == 0) {
            break;
        }
        NSURL *fileURL = [self.class ytv_fileURLForRemoteURLString:oldestKey];
        unsigned long long fileBytes = [self ytv_fileSizeAtURLLocked:fileURL];
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
        [self.manifest removeObjectForKey:oldestKey];
        totalBytes = (fileBytes >= totalBytes) ? 0 : (totalBytes - fileBytes);
    }
    [self.manifest writeToURL:[self.class ytv_manifestURL] atomically:YES];
}

@end
