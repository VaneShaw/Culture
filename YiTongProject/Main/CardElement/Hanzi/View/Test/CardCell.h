//
//  CardCell.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/22.
//

#import <UIKit/UIKit.h>
#import "CardModel.h"
NS_ASSUME_NONNULL_BEGIN


@interface CardCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
- (void)configureWithCard:(CardModel *)card
                   atIndex:(NSInteger)index
               currentIndex:(NSInteger)currentIndex
                  mainWidth:(CGFloat)mainWidth
                totalHeight:(CGFloat)totalHeight;
@end

NS_ASSUME_NONNULL_END

