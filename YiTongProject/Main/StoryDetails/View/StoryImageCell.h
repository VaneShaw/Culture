//
//  StoryImageCell.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/30.
//

#import <UIKit/UIKit.h>
#import "StorySectionModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface StoryImageCell : UITableViewCell
@property (nonatomic, copy) void (^onImageLoadComplete)(void);
@property (strong, nonatomic) StorySectionModel *model;


- (void)setModel:(StorySectionModel *)model;
@end

NS_ASSUME_NONNULL_END
