//
//  BannerScrollView.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BannerScrollView : UIView <UIScrollViewDelegate>
@property (nonatomic, strong) NSArray *imageUrls; // 图片URL数组
@property (nonatomic, assign, readonly) CGFloat actualBannerHeight; // 实际banner高度
@property (nonatomic, copy) void (^didSelectItemAtIndex)(NSInteger index); // 点击回调
@property (nonatomic, copy) void (^didUpdateBannerHeight)(CGFloat height); // 高度更新回调
@property (nonatomic, assign) NSInteger currentIndex;

- (instancetype)initWithFrame:(CGRect)frame maxBannerHeight:(CGFloat)maxHeight;

@end

NS_ASSUME_NONNULL_END




