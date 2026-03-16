//
//  BottomSwitchBar.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/22.
//

#import "BottomSwitchBar.h"

@implementation BottomSwitchBar {
    NSMutableArray<UIButton *> *_buttons;
    void(^_actionBlock)(NSInteger index);
}
- (void)switchToIndex:(NSInteger)index {
    [self updateSelectedIndex:index];
}
- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.layer.cornerRadius = 8;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor whiteColor];
        _buttons = [NSMutableArray array];
    }
    return self;
}


/// 配置UI（在接口返回后调用）
- (void)configureWithY:(CGFloat)y
                titles:(NSArray<NSString *> *)titles
                action:(void(^)(NSInteger index))action {
    
    _actionBlock = action;
    NSDictionary *marginMap = @{
        @2 : @79,
        @3 : @39,
        @4 : @28
    };

    CGFloat leftMargin = [marginMap[@(titles.count)] floatValue] ?: 0;
    CGFloat width = SCREEN_WIDTH - 2 * leftMargin;
    CGRect frame = CGRectMake((SCREEN_WIDTH - width)/2, y, width, 54);
    self.frame = frame;
    
    NSInteger count = titles.count;
    CGFloat btnWidth = (width - (count + 1) * 4) / count; // 左右 + 间距
    CGFloat btnHeight = frame.size.height - 8;            // 上下留4
    CGFloat btnY = 4;
    
    // 清理旧按钮（如果重复调用）
    for (UIButton *btn in _buttons) {
        [btn removeFromSuperview];
    }
    [_buttons removeAllObjects];
    
    for (NSInteger i = 0; i < count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 155 + i;
        [self addSubview:btn];
        [_buttons addObject:btn];
    }
    // 创建按钮
    for (NSInteger i = 0; i < count; i++) {
        CGFloat btnX = 4 + i * (btnWidth + 4);
        //UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIButton *btn = (UIButton *)[self viewWithTag:155 + i];
        btn.frame = CGRectMake(btnX, btnY, btnWidth, btnHeight);
        btn.tag = i;
        
        NSString *title = NSLocalizedString(titles[i], @"");
        [btn setTitle:title forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:FONT_NAME_Medium size:18];
        btn.layer.cornerRadius = 8;
        btn.clipsToBounds = YES;
        
        [btn setTitleColor:[self normalTextColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor whiteColor];
        [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self updateSelectedIndex:0]; // 默认选中第一个
}
- (void)btnClicked:(UIButton *)sender {
    [self updateSelectedIndex:sender.tag];
    if (_actionBlock) {
        _actionBlock(sender.tag);
    }
}
- (void)updateSelectedIndex:(NSInteger)index {
    _selectedIndex = index;
    for (NSInteger i = 0; i < _buttons.count; i++) {
        UIButton *btn = _buttons[i];
        if (i == index) {
            btn.backgroundColor = [self selectedBgColor];
            [btn setTitleColor:[self selectedTextColor] forState:UIControlStateNormal];
        } else {
            btn.backgroundColor = [UIColor whiteColor];
            [btn setTitleColor:[self normalTextColor] forState:UIControlStateNormal];
        }
    }
}
#pragma mark - Colors
- (UIColor *)selectedBgColor {
    NSString *currentKey = [ColorManager currentColorKey];
    ColorItem *blue = [ColorManager itemForKey:currentKey];
    NSArray *colorArray = blue.colors;
    //return [self colorWithHexString:@"#D6E6FF" alpha:1];//选中背景颜色
    return [self colorWithHexString:colorArray[1] alpha:1];//选中背景颜色
}
- (UIColor *)selectedTextColor {
    NSString *currentKey = [ColorManager currentColorKey];
    ColorItem *blue = [ColorManager itemForKey:currentKey];
    NSArray *colorArray = blue.colors;
    //return [self colorWithHexString:@"#3D5CFF" alpha:1];//选中字体颜色
    return [self colorWithHexString:colorArray[0] alpha:1];//选中字体颜色
}
- (UIColor *)normalTextColor {
    return [self colorWithHexString:@"#A0A8AE" alpha:1];//默认字体颜色
}
#pragma mark - Private Layout
- (void)relayoutButtons {
//    BOOL isOrange = YES;//[ColorManager isOrange];
//    BOOL isBlue = NO;//[ColorManager isBlue];
//    int space = 39 - isBlue * 11;
//    CGFloat width = SCREEN_WIDTH - 2 * space - isOrange * 80;
//
//    CGRect frame = CGRectMake((SCREEN_WIDTH - width)/2, 0, width, 54);  // 左右边距各 28
//    self.frame = frame;
//    
//    NSInteger count = 2;
//    CGFloat btnWidth = (width - (count + 1) * 4) / count; // 左右边距+中间间距=4
//
//    CGFloat btnHeight = frame.size.height - 8; // 上下各4
//    CGFloat btnY = 4;
//    for (NSInteger i = 0; i < count; i++) {
//        CGFloat btnX = 4 + i * (btnWidth + 4);
//        UIButton *btn = (UIButton *)[self viewWithTag:100 + i];
//        btn.frame = CGRectMake(btnX, btnY, btnWidth, btnHeight);
//    }
}
@end
