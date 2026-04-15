//
//  YTTalkHomeBannerImageItem.h
//  YiTongProject
//
//  /talk/banner → data.banner_imgs 单条
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTTalkHomeBannerImageItem : NSObject

@property (nonatomic, copy) NSString *imageURLString;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *tagText;

@end

NS_ASSUME_NONNULL_END
