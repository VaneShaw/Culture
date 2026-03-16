//
//  CardBaseView.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, TipsLayoutStyle) {
    TipsLayoutStyleListen,
    TipsLayoutStyleRead,
    TipsLayoutStyleWrite
};
@interface CardBaseView : UIView
@property (nonatomic, assign) TipsLayoutStyle style;
@property (strong, nonatomic) UILabel *lblCardTitle;//顶部标题
@property (strong, nonatomic) UILabel *lblCardSubtitle;  //底部 
@property (strong, nonatomic) UIPlayButton *btnPlay;
@property (strong, nonatomic) UIButton *btnNext;

@property (nonatomic, strong) UIView *toneView;
@property (strong, nonatomic) UILabel *lblTone;
@property (nonatomic, strong) UIImageView *hanziView;
@property (strong, nonatomic) UILabel *lblPinyin;         //顶部 拼音
//@property (strong, nonatomic) UILabel *lblCardTitle;       //顶部字母标题
//@property (strong, nonatomic) UILabel *lblCardSubtitle;  //顶部 拼音
@property (strong, nonatomic) SDAnimatedImageView *gifViewTemp;
@property (nonatomic, assign) TipsLayoutStyle layoutStyle;

// 子类必须实现的方法
//- (instancetype)initWithLayoutStyle:(TipsLayoutStyle)style;

- (instancetype)initWithTypeStyle:(TipsLayoutStyle)style;
- (void)btnflipCardActionNo;
- (void)loadGIFWithURLString:(NSString *)urlString;
- (void)updateMeaningViewWithText:(NSDictionary *)formWords;
@end

NS_ASSUME_NONNULL_END
