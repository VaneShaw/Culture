//
//  ReadFooterView.h
//  YiTongProject
//
//  Created by ios01 on 2025/11/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReadFooterView : UIView
@property (strong, nonatomic) UIButton *nextButton;

@property (strong, nonatomic) SDAnimatedImageView *gifImageView;
- (void)loadGIFWithURLString:(NSString *)gifUrlString;
- (void)loadImageWithURLString:(NSString *)imageUrlString;

- (void)setFooterArrowState:(int )state;
- (void)startArrowAnimation;
- (void)stopArrowAnimation;
@end

NS_ASSUME_NONNULL_END
