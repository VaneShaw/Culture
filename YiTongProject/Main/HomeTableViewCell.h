//
//  HomeTableViewCell.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/3.
//

#import <UIKit/UIKit.h>
#import "BannerScrollView.h"
NS_ASSUME_NONNULL_BEGIN

@interface HomeTableViewCell : UITableViewCell
@property (strong, nonatomic) UIImageView *lockView;
@property (strong, nonatomic) UIImageView *backView;

@property (strong, nonatomic) BannerScrollView *bannerScrollView;
@property (strong, nonatomic) NSArray *imagesArray;
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);
- (void)setCell:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
