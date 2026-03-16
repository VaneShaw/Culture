//
//  VideoManager.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoManager : NSObject
@property (nonatomic, strong) AVPlayer *sharedPlayer;
@property (nonatomic, strong) NSMutableDictionary<NSString*, AVPlayerItem*> *itemCache;
+ (instancetype)shared;
- (AVPlayerItem *)playerItemForURL:(NSURL *)url;
@end

NS_ASSUME_NONNULL_END
