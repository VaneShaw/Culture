//
//  YTVFavoritesListCell.h
//  YiTongProject
//

#import <UIKit/UIKit.h>

@class YTVVideoFeedItem;

NS_ASSUME_NONNULL_BEGIN

@interface YTVFavoritesListCell : UITableViewCell

- (void)ytv_configureWithItem:(YTVVideoFeedItem *)item;

@end

NS_ASSUME_NONNULL_END
