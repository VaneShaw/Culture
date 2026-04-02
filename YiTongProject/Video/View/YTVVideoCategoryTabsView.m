//
//  YTVVideoCategoryTabsView.m
//  YiTongProject
//

#import "YTVVideoCategoryTabsView.h"
#import "YTVVideoCategoryKeys.h"
#import "HeaderConfig.h"

@interface YTVVideoCategoryTabsView ()
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation YTVVideoCategoryTabsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.92];
        _selectedIndex = 0;
        [self addSubview:self.stackView];
        [self.stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsMake(6, 8, 6, 8));
        }];
    }
    return self;
}

- (void)ytv_setSelectedIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= (NSInteger)YTVVideoCategoryCount()) {
        return;
    }
    self.selectedIndex = index;
    [self ytv_updateButtonStylesAnimated:animated];
}

- (UIStackView *)stackView {
    if (!_stackView) {
        NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
        NSArray<NSString *> *titles = @[
            NSLocalizedString(@"YTV_category_recommend", @""),
            NSLocalizedString(@"YTV_category_idiom", @""),
            NSLocalizedString(@"YTV_category_myth", @""),
            NSLocalizedString(@"YTV_category_fengshen", @""),
        ];
        for (NSInteger i = 0; i < (NSInteger)titles.count; i++) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            [b setTitle:titles[(NSUInteger)i] forState:UIControlStateNormal];
            b.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
            b.tag = i;
            [b addTarget:self action:@selector(ytv_tabTapped:) forControlEvents:UIControlEventTouchUpInside];
            [buttons addObject:b];
        }
        self.tabButtons = [buttons copy];
        _stackView = [[UIStackView alloc] initWithArrangedSubviews:self.tabButtons];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.distribution = UIStackViewDistributionFillEqually;
        _stackView.alignment = UIStackViewAlignmentFill;
        _stackView.spacing = 4;
        [self ytv_updateButtonStylesAnimated:NO];
    }
    return _stackView;
}

- (void)ytv_tabTapped:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx == self.selectedIndex) {
        return;
    }
    self.selectedIndex = idx;
    [self ytv_updateButtonStylesAnimated:YES];
    if (self.onSelectIndex) {
        self.onSelectIndex(idx);
    }
}

- (void)ytv_updateButtonStylesAnimated:(BOOL)animated {
    void (^apply)(void) = ^{
        for (NSInteger i = 0; i < (NSInteger)self.tabButtons.count; i++) {
            UIButton *b = self.tabButtons[(NSUInteger)i];
            BOOL on = (i == self.selectedIndex);
            UIColor *titleColor = on ? [UIColor whiteColor] : [[UIColor whiteColor] colorWithAlphaComponent:0.45];
            [b setTitleColor:titleColor forState:UIControlStateNormal];
            b.titleLabel.font = [UIFont fontWithName:on ? FONT_NAME_Medium : FONT_NAME_Regular size:14];
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:apply];
    } else {
        apply();
    }
}

@end
