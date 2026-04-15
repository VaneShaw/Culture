//
//  YTVVideoCategoryTabsView.m
//  YiTongProject
//

#import "YTVVideoCategoryTabsView.h"
#import "YTVVideoCategoryKeys.h"
#import "HeaderConfig.h"

@interface YTVVideoCategoryTabsView ()
@property (nonatomic, strong) UIScrollView *tabsScrollView;
@property (nonatomic, strong) UIStackView *tabsRowStack;
@property (nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) UIView *selectionUnderline;
@property (nonatomic, assign) NSInteger selectedIndex;
@end

@implementation YTVVideoCategoryTabsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _selectedIndex = 0;
        [self addSubview:self.tabsScrollView];
        [self.tabsScrollView addSubview:self.tabsRowStack];
        [self addSubview:self.searchButton];
        [self addSubview:self.selectionUnderline];
        [self.tabsScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(4);
            make.top.bottom.equalTo(self);
            make.right.equalTo(self.searchButton.mas_left).offset(-2);
        }];
        self.tabsRowStack.translatesAutoresizingMaskIntoConstraints = NO;
        UILayoutGuide *contentG = self.tabsScrollView.contentLayoutGuide;
        UILayoutGuide *frameG = self.tabsScrollView.frameLayoutGuide;
        [NSLayoutConstraint activateConstraints:@[
            [self.tabsRowStack.topAnchor constraintEqualToAnchor:contentG.topAnchor],
            [self.tabsRowStack.leadingAnchor constraintEqualToAnchor:contentG.leadingAnchor],
            [self.tabsRowStack.bottomAnchor constraintEqualToAnchor:contentG.bottomAnchor],
            [self.tabsRowStack.trailingAnchor constraintEqualToAnchor:contentG.trailingAnchor],
            [self.tabsRowStack.heightAnchor constraintEqualToAnchor:frameG.heightAnchor],
        ]];
        [self.searchButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-4);
            make.centerY.equalTo(self);
            make.width.height.mas_equalTo(44);
        }];
        self.tabsScrollView.showsHorizontalScrollIndicator = NO;
        self.tabsScrollView.showsVerticalScrollIndicator = NO;
        self.tabsScrollView.alwaysBounceHorizontal = YES;
        self.tabsScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        [self ytv_applyTabTitles:nil];
        [self.selectionUnderline mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(2.5);
            make.bottom.equalTo(self).offset(-5);
            make.width.mas_equalTo(28);
            if (self.tabButtons.count > 0) {
                make.centerX.equalTo(self.tabButtons.firstObject);
            } else {
                make.centerX.equalTo(self.tabsScrollView);
            }
        }];
        [self ytv_updateButtonStylesAnimated:NO];
        [self layoutIfNeeded];
        [self ytv_updateSelectionUnderlineConstraints];
    }
    return self;
}

- (void)ytv_applyTabTitles:(NSArray<NSString *> *)titles {
    NSUInteger n = YTVVideoCategoryCount();
    NSMutableArray<NSString *> *use = [NSMutableArray arrayWithCapacity:n];
    for (NSUInteger i = 0; i < n; i++) {
        NSString *t = nil;
        if (titles != nil && i < titles.count) {
            id o = titles[i];
            if ([o isKindOfClass:[NSString class]]) {
                t = [(NSString *)o stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        if (t.length == 0) {
            t = YTVVideoCategoryTitleAtIndex(i);
        }
        if (t.length == 0) {
            t = YTVVideoCategoryKeyAtIndex(i);
        }
        [use addObject:t];
    }
    for (UIView *v in [self.tabsRowStack.arrangedSubviews copy]) {
        [self.tabsRowStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    for (NSUInteger i = 0; i < use.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b setTitle:use[i] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:15];
        b.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        b.tag = (NSInteger)i;
        [b addTarget:self action:@selector(ytv_tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttons addObject:b];
        [self.tabsRowStack addArrangedSubview:b];
    }
    self.tabButtons = [buttons copy];
    if (self.selectedIndex >= (NSInteger)self.tabButtons.count) {
        self.selectedIndex = MAX(0, (NSInteger)self.tabButtons.count - 1);
    }
    [self ytv_updateButtonStylesAnimated:NO];
    [self layoutIfNeeded];
    [self ytv_updateSelectionUnderlineConstraints];
}

- (void)ytv_setSelectedIndex:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= (NSInteger)YTVVideoCategoryCount()) {
        return;
    }
    if (index >= (NSInteger)self.tabButtons.count) {
        return;
    }
    self.selectedIndex = index;
    [self ytv_updateButtonStylesAnimated:animated];
    [self layoutIfNeeded];
    [self ytv_updateSelectionUnderlineConstraints];
}

- (UIScrollView *)tabsScrollView {
    if (!_tabsScrollView) {
        _tabsScrollView = [[UIScrollView alloc] init];
        _tabsScrollView.backgroundColor = [UIColor clearColor];
    }
    return _tabsScrollView;
}

- (UIStackView *)tabsRowStack {
    if (!_tabsRowStack) {
        _tabsRowStack = [[UIStackView alloc] init];
        _tabsRowStack.axis = UILayoutConstraintAxisHorizontal;
        _tabsRowStack.distribution = UIStackViewDistributionFill;
        _tabsRowStack.alignment = UIStackViewAlignmentCenter;
        _tabsRowStack.spacing = 4;
    }
    return _tabsRowStack;
}

- (UIButton *)searchButton {
    if (!_searchButton) {
        _searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        UIImage *img = [UIImage imageNamed:@"video_home_search"];
        if (img) {
            img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_searchButton setImage:img forState:UIControlStateNormal];
        }
        _searchButton.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.92];
        _searchButton.adjustsImageWhenHighlighted = YES;
        _searchButton.accessibilityLabel = NSLocalizedString(@"YTV_video_search_accessibility", @"");
        [_searchButton addTarget:self action:@selector(ytv_searchTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _searchButton;
}

- (UIView *)selectionUnderline {
    if (!_selectionUnderline) {
        _selectionUnderline = [[UIView alloc] init];
        _selectionUnderline.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.95];
        _selectionUnderline.layer.cornerRadius = 1.25;
        _selectionUnderline.clipsToBounds = YES;
    }
    return _selectionUnderline;
}

- (void)ytv_searchTapped {
    if (self.onSearchTap) {
        self.onSearchTap();
    }
}

- (void)ytv_tabTapped:(UIButton *)sender {
    NSInteger idx = sender.tag;
    if (idx == self.selectedIndex) {
        return;
    }
    self.selectedIndex = idx;
    [self ytv_updateButtonStylesAnimated:YES];
    [self layoutIfNeeded];
    [self ytv_updateSelectionUnderlineConstraints];
    if (self.onSelectIndex) {
        self.onSelectIndex(idx);
    }
}

- (void)ytv_updateButtonStylesAnimated:(BOOL)animated {
    void (^apply)(void) = ^{
        for (NSInteger i = 0; i < (NSInteger)self.tabButtons.count; i++) {
            UIButton *b = self.tabButtons[(NSUInteger)i];
            BOOL on = (i == self.selectedIndex);
            UIColor *titleColor = on ? [UIColor whiteColor] : [[UIColor whiteColor] colorWithAlphaComponent:0.42];
            [b setTitleColor:titleColor forState:UIControlStateNormal];
            b.titleLabel.font = [UIFont fontWithName:on ? FONT_NAME_Semibold : FONT_NAME_Regular size:15];
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:apply];
    } else {
        apply();
    }
}

- (void)ytv_updateSelectionUnderlineConstraints {
    if (self.selectedIndex < 0 || self.selectedIndex >= (NSInteger)self.tabButtons.count) {
        return;
    }
    UIButton *b = self.tabButtons[(NSUInteger)self.selectedIndex];
    [b layoutIfNeeded];
    CGFloat textW = ceil([b.titleLabel intrinsicContentSize].width);
    if (textW < 22) {
        textW = 22;
    }
    [self.selectionUnderline mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(2.5);
        make.bottom.equalTo(self).offset(-5);
        make.width.mas_equalTo(textW);
        make.centerX.equalTo(b);
    }];
}

- (void)ytv_setSelectionUnderlineHidden:(BOOL)hidden {
    self.selectionUnderline.hidden = hidden;
}

@end
