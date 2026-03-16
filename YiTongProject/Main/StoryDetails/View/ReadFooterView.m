//
//  ReadFooterView.m
//  YiTongProject
//
//  Created by ios01 on 2025/11/4.
//

#import "ReadFooterView.h"
static NSCache *gifMemoryCache;
@interface ReadFooterView(){
    UIImageView *_arrow0;
    UIImageView *_arrow1;
    UIImageView *_arrow2;
}
@property (strong, nonatomic) UIImageView *footerImage;
@property (nonatomic, strong) NSURLSessionDataTask *currentTask; // 用于取消旧请求
@property (assign, nonatomic) BOOL isValue;
@end
@implementation ReadFooterView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.clipsToBounds = YES;
        [self setupViews];
        if(frame.size.height == 251 ){
            //self.isValue = frame.size.height == 331;
            [self setupViews2];
        }
    }
    return self;
}
- (void)setupViews {
    self.footerImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self addSubview:self.footerImage];
    
    self.gifImageView = [[SDAnimatedImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.gifImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.gifImageView.hidden = YES;
    [self addSubview:self.gifImageView];
}
- (void)setupViews2 {
    // ===== nextButton =====
    //"NEXT CHAPTER COMING UP" = "即将进入下一回";
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.titleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
    [self.nextButton setTitleColor:[self colorWithHexString:@"#C7A275" alpha:1] forState:UIControlStateNormal];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:14];
    self.nextButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.nextButton];
   
    // 距底部 200
    int width = 260;
    [NSLayoutConstraint activateConstraints:@[
        [self.nextButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.nextButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-138],
        [self.nextButton.widthAnchor constraintEqualToConstant:width],
        [self.nextButton.heightAnchor constraintEqualToConstant:100],
    ]];

    // ===== arrows =====
    _arrow0 = [self createArrow:@"next_page_0"];
    _arrow1 = [self createArrow:@"next_page_1"];
    _arrow2 = [self createArrow:@"next_page_2"];

    [self.nextButton addSubview:_arrow0];
    [self.nextButton addSubview:_arrow1];
    [self.nextButton addSubview:_arrow2];

    // 初始位置（竖向排列）
    _arrow0.frame = CGRectMake((width-16)/2, 65, 16, 10);
    _arrow1.frame = CGRectMake((width-16)/2, 76 , 16, 10);
    _arrow2.frame = CGRectMake((width-16)/2, 87, 16, 10);
}
- (void)setFooterArrowState:(int)state {
    
    NSString *next0 = NSLocalizedString(@"Start reading", @"");
    NSString *next1 = NSLocalizedString(@"NEXT CHAPTER COMING UP", @"");
    NSString *next2 = NSLocalizedString(@"The battle for the Gods continues...", @"");
    [self.nextButton setTitle:@[next0,next1,next2][state]
                                              forState:UIControlStateNormal];
    NSArray<UIImageView *> *arrows = @[_arrow0, _arrow1, _arrow2];
    if (state==2) {
        // 1️⃣ 隐藏时，先停动画，避免 layer 残留
        [self stopArrowAnimation];
        for (UIImageView *arrow in arrows) {
            arrow.hidden = YES;
        }
    } else {
        // 2️⃣ 显示
        for (UIImageView *arrow in arrows) {
            arrow.hidden = NO;
        }

        // 3️⃣ 再启动动画
        [self startArrowAnimation];
    }
}
//=======================================================================
//=======================================================================
- (UIImageView *)createArrow:(NSString *)imageName {
    UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.alpha = 1.0;
    return iv;
}
- (void)startArrowAnimation {
    [self animateArrow:_arrow0 delay:0.0];
    [self animateArrow:_arrow1 delay:0.2];
    [self animateArrow:_arrow2 delay:0.4];
}
- (void)stopArrowAnimation {
    [_arrow0.layer removeAllAnimations];
    [_arrow1.layer removeAllAnimations];
    [_arrow2.layer removeAllAnimations];
}
- (void)animateArrow:(UIImageView *)arrow delay:(NSTimeInterval)delay {

    arrow.alpha = 0.0;
    arrow.transform = CGAffineTransformIdentity;
    [UIView animateKeyframesWithDuration:1.2
                                    delay:delay
                                  options:UIViewKeyframeAnimationOptionRepeat
                               animations:^{

        // 出现
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^{
            arrow.alpha = 1.0;
            arrow.transform = CGAffineTransformMakeTranslation(0, 4);
        }];

        // 下移
        [UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.4 animations:^{
            arrow.transform = CGAffineTransformMakeTranslation(0, 8);
        }];

        // 消失
        [UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.3 animations:^{
            arrow.alpha = 0.0;
        }];

    } completion:nil];
}
//=======================================================================
//======================gif===========================N===================
- (void)clearCurrentGIFxxx {
    if (self.currentTask) {
        [self.currentTask cancel];
        self.currentTask = nil;
    }
    //self.gifImageView.animatedImage = nil;
}
- (void)clearCurrentGIF {
    // 取消 SDWebImage 当前下载任务
    [self.gifImageView sd_cancelCurrentImageLoad];
    // 清空 GIF 显示
    self.gifImageView.image = nil;
    // 可选：隐藏控件
    self.gifImageView.hidden = YES;
}
- (void)loadGIFWithURLString:(NSString *)gifUrlString {
    NSString *encodedUrlString = gifUrlString;
    //[gifUrlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    if (!encodedUrlString || encodedUrlString.length == 0) return;
    NSURL *url = [NSURL URLWithString:encodedUrlString];
    if (!url) return;
    
    // 清空旧内容（可选）
    self.gifImageView.image = nil;
    self.gifImageView.hidden = YES;
    // 显示 GIF 控件
    self.gifImageView.hidden = NO;
    // SDWebImage 自动处理：
    // 1️⃣ 内存缓存
    // 2️⃣ 磁盘缓存
    // 3️⃣ 异步下载
    // 4️⃣ GIF 解析与自动播放
    [self.gifImageView sd_setImageWithURL:url
                        placeholderImage:nil
                                 options:SDWebImageRetryFailed | SDWebImageLowPriority
                               completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (error) {
            //NSLog(@"❌ GIF 加载失败: [%@]------", error);
            self.gifImageView.hidden = YES; // 下载失败可隐藏
        } else {
            //NSLog(@"✅ GIF 加载成功，缓存类型: [%ld]----------", (long)cacheType);
        }
    }];
}
- (NSString *)cachePathForGIFURL:(NSString *)urlString {
    NSString *fileName = [urlString lastPathComponent];
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *gifCacheDir = [cacheDir stringByAppendingPathComponent:@"GIFCache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:gifCacheDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:gifCacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return [gifCacheDir stringByAppendingPathComponent:fileName];
}
//======================gif====================================v==========
            // ✅ 关键：重新赋值 footerView 才会刷新高度！
- (UIViewController *)parentViewController {
    UIResponder *responder = self;
    while (responder) {
        responder = responder.nextResponder;
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}
- (void)loadImageWithURLString:(NSString *)imageUrlString {
    if (!imageUrlString || imageUrlString.length == 0) return;
    NSURL *url = [NSURL URLWithString:imageUrlString];
    if (!url) return;
    UIViewController *vc = [self parentViewController];
    if (vc) {
        //[MBProgressHUD showHUDAddedTo:vc.view animated:YES];
    }
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                                 completionHandler:^(NSData * _Nullable data,NSURLResponse * _Nullable response,NSError * _Nullable error) {
            if (vc) {
                //[MBProgressHUD hideHUDForView:vc.view animated:YES];
            }
            if (error || !data) {
                //NSLog(@"图片下载失败: %@", error);
                return;
            }
            UIImage *image = [UIImage imageWithData:data];
            if (!image) return;

            dispatch_async(dispatch_get_main_queue(), ^{
                CGFloat displayHeight = SCREEN_WIDTH * (image.size.height / image.size.width);
                // ✅ 设置 UIImageView 图片
                weakSelf.footerImage.image = image;
                weakSelf.footerImage.hidden = NO;
                // ✅ 更新 frame（如果使用 frame 布局）
                weakSelf.footerImage.frame = CGRectMake(0, 0, SCREEN_WIDTH, displayHeight);
                weakSelf.frame = CGRectMake(0, 0, SCREEN_WIDTH, displayHeight);
                weakSelf.gifImageView.frame = CGRectMake(0, 0, SCREEN_WIDTH, displayHeight);
                // ✅ 关键：重新设置 tableHeaderView 才能让高度刷新
                UITableView *tableView = [weakSelf parentTableView];
                tableView.tableFooterView = weakSelf;
            });
        }];
        [task resume];
}
- (UITableView *)parentTableView {
    UIView *view = self.superview;
    while (view && ![view isKindOfClass:[UITableView class]]) {
        view = view.superview;
    }
    return (UITableView *)view;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
