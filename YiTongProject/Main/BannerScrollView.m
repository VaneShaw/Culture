//
//  BannerScrollView.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/23.
//

#import "BannerScrollView.h"

@interface BannerScrollView () 

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger imageCount;
@property (nonatomic, strong) NSMutableArray *imageViews;
@property (nonatomic, assign) CGFloat maxBannerHeight;
@property (nonatomic, assign) CGFloat imageAspectRatio; // 图片宽高比
@property (nonatomic, assign) BOOL hasLoadedFirstImage; // 是否已加载第一张图片
@end

@implementation BannerScrollView
- (instancetype)initWithFrame:(CGRect)frame maxBannerHeight:(CGFloat)maxHeight {
    self = [super initWithFrame:frame];
    if (self) {
        _maxBannerHeight = maxHeight;
        _actualBannerHeight = maxHeight; // 初始化为最大高度
        _hasLoadedFirstImage = NO;
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    // 初始化ScrollView
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, _maxBannerHeight)];
    _scrollView.delegate = self;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.bounces = NO;
    [self addSubview:_scrollView];
    
    // 初始化PageControl
    _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, _maxBannerHeight - 20, self.frame.size.width, 20)];
    _pageControl.pageIndicatorTintColor = [UIColor grayColor];
    _pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    _pageControl.hidesForSinglePage = YES;
    [self addSubview:_pageControl];
    
    // 初始化数组
    _imageViews = [NSMutableArray array];    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [_scrollView addGestureRecognizer:tap];
}
- (void)setImageUrls:(NSArray *)imageUrls {
    _imageUrls = imageUrls;
    _imageCount = imageUrls.count;
    
    // 清除旧的图片视图
    for (UIView *view in _imageViews) {
        [view removeFromSuperview];
    }
    [_imageViews removeAllObjects];

    // 重置高度状态
    _hasLoadedFirstImage = NO;
    _actualBannerHeight = _maxBannerHeight;
    // 设置内容大小
    if (_imageCount <= 0) {
        return;
    }
    _scrollView.contentSize = CGSizeMake(self.frame.size.width * (_imageCount > 1 ? _imageCount + 2 : _imageCount), _maxBannerHeight);
    // 配置PageControl
    _pageControl.numberOfPages = _imageCount;
    _pageControl.hidden = _imageCount <= 1;
    
    // 添加图片视图
    if (_imageCount > 1) {
        // 第一张前面放最后一张
        UIImageView *firstImageView = [self createImageViewWithIndex:_imageCount - 1];
        firstImageView.frame = CGRectMake(0, 0, self.frame.size.width, _maxBannerHeight);
        [_scrollView addSubview:firstImageView];
        [_imageViews addObject:firstImageView];
    }
    // 添加正常顺序的图片
    for (int i = 0; i < _imageCount; i++) {
        UIImageView *imageView = [self createImageViewWithIndex:i];
        CGFloat x = self.frame.size.width * (_imageCount > 1 ? i + 1 : i);
        imageView.frame = CGRectMake(x, 0, self.frame.size.width, _maxBannerHeight);
        [_scrollView addSubview:imageView];
        [_imageViews addObject:imageView];
    }
    if (_imageCount > 1) {
        // 最后一张后面放第一张
        UIImageView *lastImageView = [self createImageViewWithIndex:0];
        lastImageView.frame = CGRectMake(self.frame.size.width * (_imageCount + 1), 0, self.frame.size.width, _maxBannerHeight);
        [_scrollView addSubview:lastImageView];
        [_imageViews addObject:lastImageView];
        
        // 初始位置
        [_scrollView setContentOffset:CGPointMake(self.frame.size.width, 0) animated:NO];
        _currentIndex = 0;
        _pageControl.currentPage = _currentIndex;
        // 启动定时器
        [self startTimer];
    } else if (_imageCount == 1) {
        [_scrollView setContentOffset:CGPointMake(0, 0) animated:NO];
        _currentIndex = 0;
    }
}
- (UIImageView *)createImageViewWithIndex:(NSInteger)index {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    imageView.userInteractionEnabled = YES;
    // 模拟网络图片加载（实际项目中替换为SDWebImage等）
    [self loadImageForImageView:imageView atIndex:index];
    return imageView;
}
- (void)loadImageForImageView:(UIImageView *)imageView atIndex:(NSInteger)index {
        // 如果是网络图片，应该使用：
         [imageView sd_setImageWithURL:[NSURL URLWithString:self.imageUrls[index]]
                     placeholderImage:nil
                            completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
             if (image && !error) {
                 [self updateBannerHeightIfNeededWithImage:image];
             }
         }];
}
- (void)updateBannerHeightIfNeededWithImage:(UIImage *)image {
    if (_hasLoadedFirstImage) {
        return; // 已经设置过高度，不再重复设置
    }
    // 计算图片的实际高度（保持宽高比）
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    if (imageWidth > 0 && imageHeight > 0) {
        CGFloat aspectRatio = imageHeight / imageWidth;
        CGFloat actualHeight = self.frame.size.width * aspectRatio;
        
        // 确保高度不超过最大高度
        actualHeight = MIN(actualHeight, _maxBannerHeight);
        // 更新实际高度
        _actualBannerHeight = actualHeight;
        _hasLoadedFirstImage = YES;
        
        // 更新所有视图的frame
        [self updateAllFramesWithNewHeight:actualHeight];
        
        // 通知外部高度变化
        if (self.didUpdateBannerHeight) {
            self.didUpdateBannerHeight(actualHeight);
        }
    }
}

- (void)updateAllFramesWithNewHeight:(CGFloat)newHeight {
    // 更新scrollView的frame
    CGRect scrollFrame = _scrollView.frame;
    scrollFrame.size.height = newHeight;
    _scrollView.frame = scrollFrame;
    
    // 更新pageControl的位置
    CGRect pageControlFrame = _pageControl.frame;
    pageControlFrame.origin.y = newHeight - 20;
    _pageControl.frame = pageControlFrame;
    
    // 更新所有imageView的高度
    for (UIImageView *imageView in _imageViews) {
        CGRect frame = imageView.frame;
        frame.size.height = newHeight;
        imageView.frame = frame;
    }
    
    // 更新scrollView的contentSize
    _scrollView.contentSize = CGSizeMake(_scrollView.contentSize.width, newHeight);
    // 更新自身的高度
    CGRect selfFrame = self.frame;
    selfFrame.size.height = newHeight;
    self.frame = selfFrame;
}
- (void)startTimer {
    [self stopTimer];
    if (_imageCount <= 1) {
        return;
    }
    _timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(autoScroll) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}
- (void)stopTimer {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
}
- (void)autoScroll {
    if (_imageCount <= 1) {
        return;
    }
    CGFloat targetX = _scrollView.contentOffset.x + self.frame.size.width;
    [_scrollView setContentOffset:CGPointMake(targetX, 0) animated:YES];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (self.didSelectItemAtIndex) {
        self.didSelectItemAtIndex(_currentIndex);
    }
}

#pragma mark - UIScrollViewDelegate
//随着时间左右切换
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_imageCount <= 1) {
        return;
    }
    
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat width = self.frame.size.width;
    // 向右滑动到最前面时，跳转到最后面
    if (offsetX <= 0) {
        [scrollView setContentOffset:CGPointMake(width * _imageCount, 0) animated:NO];
    }
    
    // 向左滑动到最后面时，跳转到最前面
    if (offsetX >= width * (_imageCount + 1)) {
        [scrollView setContentOffset:CGPointMake(width, 0) animated:NO];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateCurrentIndex];
    [self startTimer];
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self updateCurrentIndex];
}
- (void)updateCurrentIndex {
    if (_imageCount <= 1) {
        return;
    }
    CGFloat offsetX = _scrollView.contentOffset.x;
    CGFloat width = self.frame.size.width;
    
    if (offsetX <= 0) {
        _currentIndex = _imageCount - 1;
    } else if (offsetX >= width * (_imageCount + 1)) {
        _currentIndex = 0;
    } else {
        _currentIndex = (NSInteger)((offsetX - width) / width);
    }
    _pageControl.currentPage = _currentIndex;
    // 重置到中间位置
    [_scrollView setContentOffset:CGPointMake(width * (_currentIndex + 1), 0) animated:NO];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self stopTimer];
}
- (void)dealloc {
    [self stopTimer];
}


@end
