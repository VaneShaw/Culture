//
//  CardCell.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/22.
//

#import "CardCell.h"

@implementation CardCell
- (void)configureWithCard:(CardModel *)card
                   atIndex:(NSInteger)index
               currentIndex:(NSInteger)currentIndex
                  mainWidth:(CGFloat)mainWidth
                totalHeight:(CGFloat)totalHeight {
    self.layer.cornerRadius = 8;
    self.clipsToBounds = NO;
    CGFloat smallWidth = 27;
    CGFloat verticalInset = 35;
    
    if (index == currentIndex) {
        self.imageView.frame = CGRectMake(0, 0, mainWidth, totalHeight);
    } else if (index == currentIndex - 1 || index == currentIndex + 1) {
        self.imageView.frame = CGRectMake(0, verticalInset, smallWidth, totalHeight - 2*verticalInset);
    } else {
        self.imageView.frame = CGRectZero;
    }
    
    self.imageView.image = card.image;
    self.imageView.backgroundColor = UIColor.blueColor; // 测试可见
}

@end
