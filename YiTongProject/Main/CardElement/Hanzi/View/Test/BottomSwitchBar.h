//
//  BottomSwitchBar.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BottomSwitchBar : UIView
/// 当前选中的下标
@property (nonatomic, assign, readonly) NSInteger selectedIndex;


/// 初始化方法
/// @param y Y坐标
/// @param titles 按钮标题数组（2~4个）
/// @param action 点击回调，返回选中下标
/*- (instancetype)initWithY:(CGFloat)y
                   titles:(NSArray<NSString *> *)titles
                   action:(void(^)(NSInteger index))action;*/
- (void)configureWithY:(CGFloat)y
                titles:(NSArray<NSString *> *)titles
                action:(void(^)(NSInteger index))action;

// 新增方法
- (void)switchToIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END


/*
- (instancetype)initWithY:(CGFloat)y
                   titles:(NSArray<NSString *> *)titles
                   action:(void(^)(NSInteger index))action {


    NSDictionary *marginMap = @{
        @2 : @79,
        @3 : @39,
        @4 : @28
    };

    CGFloat leftMargin = [marginMap[@(titles.count)] floatValue] ?: 0;
    CGFloat width = SCREEN_WIDTH - 2 * leftMargin;
    CGRect frame = CGRectMake((SCREEN_WIDTH - width)/2, y, width, 54);  // 左右边距各 28
    self = [super initWithFrame:frame];
    if (self) {
        
        self.layer.cornerRadius = 8;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor whiteColor];
        _buttons = [NSMutableArray array];
        _actionBlock = action;
        
        NSInteger count = titles.count;
        CGFloat btnWidth = (width - (count + 1) * 4) / count; // 左右边距+中间间距=4
        CGFloat btnHeight = frame.size.height - 8; // 上下各4
        CGFloat btnY = 4;
        
        for (NSInteger i = 0; i < count; i++) {
            CGFloat btnX = 4 + i * (btnWidth + 4);
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.tag = 100 + i;
            btn.frame = CGRectMake(btnX, btnY, btnWidth, btnHeight);
            NSString *title = NSLocalizedString(titles[i],@"");
            [btn setTitle:title forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Medium size:18];
            btn.layer.cornerRadius = 8;
            btn.clipsToBounds = YES;
            
            [btn setTitleColor:[self normalTextColor] forState:UIControlStateNormal];
            btn.backgroundColor = [UIColor whiteColor];
            btn.tag = i;//UIControlEventTouchUpInsider
            [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:btn];
            [_buttons addObject:btn];
            
        }
        // 默认选中第一个
        [self updateSelectedIndex:0];

    }
    return self;
}*/
