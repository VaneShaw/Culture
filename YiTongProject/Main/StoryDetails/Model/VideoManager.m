//
//  VideoManager.m
//  YiTongProject
//
//  Created by ios01 on 2025/10/16.
//

#import "VideoManager.h"

@implementation VideoManager
+ (instancetype)shared {
    static VideoManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [VideoManager new];
        manager.sharedPlayer = [AVPlayer playerWithPlayerItem:nil];
        manager.itemCache = [NSMutableDictionary dictionary];
    });
    return manager;
}

- (AVPlayerItem *)playerItemForURL:(NSURL *)url {
    NSString *key = url.absoluteString;
    AVPlayerItem *item = self.itemCache[key];
    if (!item) {
        item = [AVPlayerItem playerItemWithURL:url];
        self.itemCache[key] = item;
    }
    return item;
}

@end
