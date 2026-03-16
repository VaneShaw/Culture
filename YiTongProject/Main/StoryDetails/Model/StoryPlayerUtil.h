//
//  StoryPlayerUtil.h
//  YiTongProject
//
//  Created by ios01 on 2026/1/6.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface StoryPlayerUtil : NSObject
+ (void)updateNowPlayingWithStoryInfo:(NSDictionary *)dicStory
                            isFairy:(BOOL)isFairy
                         languageKey:(NSString *)languageKey
                              player:(AVPlayer *)player
                          playerItem:(AVPlayerItem *)playerItem;

@end

NS_ASSUME_NONNULL_END
