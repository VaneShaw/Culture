//
//  CardScrollView.h
//  YiTongProject
//
//  Created by ios01 on 2025/12/29.
//

#import <UIKit/UIKit.h>
#import "CardView.h"
NS_ASSUME_NONNULL_BEGIN

@interface CardScrollView : UIView<UIScrollViewDelegate>
@property (nonatomic, assign) BOOL isVoice;
@property (nonatomic, strong) CardView *currentCardView;
@property (nonatomic, assign) NSInteger lastVisibleIndex;

@property (nonatomic, strong) NSArray *cardLetters;
@property (nonatomic, assign) int currentPage;
@property (nonatomic, assign) int footerIndex;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIViewController *uvc;
// 点击卡片的回调
@property (nonatomic, copy) void (^didSelectCardBlock33)(NSInteger index);
// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame letters:(NSArray<NSString *> *)letters;
// 刷新卡片数据
- (void)reloadWithLetters:(NSArray *)letters strSymbol:(NSString *)strSymbol;
// 刷新卡片数据
- (void)reloadCardWithLettersFooterIndex:(int)footerIndex;
- (void)updateCardLayouts;
- (void)reloadCardViewTypeView:(CardView *)cardView ;
- (void)cardDidAppearData:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
