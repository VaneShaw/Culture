//
//  TalkTopicHomeViewController.m
//  YiTongProject
//
//  Created by ios01 on 2026/3/17.
//

#import "TalkTopicHomeViewController.h"
#import "HeaderConfig.h"
#import "UIViewController+BackButton.h"
#import "TalkLearningFlowViewController.h"
#import "YTLearningFlowBootstrap.h"
#import "YTMockLearningFlowBootstrapService.h"
#import "YTUnit.h"
#import "YTTalkLearningDataService.h"
#import "YTTalkLevelItem.h"
#import "YTTipAlertView.h"
#import "YTTopicLevelProgressIndicator.h"
#import "YTDifficultyTheme.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <SDWebImage/SDWebImage.h>
#import "YTInternalUnitViewSupport.h"
#import "LanguageHelper.h"

/**
 话题主页（静态 UI + 难度入口）
 
 作用：
 - 承接 Talk 首页/列表的点击进入
 - 展示三档难度卡片（Beginner/Intermediate/Advanced）
 - 点击卡片进入学习流前校验登录；未登录则弹出登录页，成功后再进入 `TalkLearningFlowViewController`
 - 进阶/困难：上一难度 `is_medal` 为真可直接进入下一难度；否则需上一难度进度达到 `unlock_threshold`（level=1/2 行）；本地占位用统一 `unlockThresholdPercent`
 - 卡片右侧：`YTTopicLevelProgressIndicator`（未开始箭头 / 进行中圆环 / 完成圆+勾）；`is_medal` 为真时直接按完成（勾）；为假时仍仅按 `progress_percent` 判断
 - 卡片「完成」底色/阴影：`is_medal` 为真直接完成态；为假时仍按原逻辑（进度达到 100% 为完成态）
 
 约束：
 - 列表进入且 `talkSceneNumericId > 0` 时请求 `POST /talk/level`（`scene_id`、`lang`），文案与进度以服务端为准；失败或空数据不兜底，隐藏难度列表
 - 无场景 id（如 Banner）仅用本地 mock
 - 统一使用工程内返回按钮（`UIViewController+BackButton`），并隐藏系统导航栏保证视觉一致
 */
static NSString *const kTalkTopicSceneId = @"scene_school";

/// Core Image 高斯模糊半径（点），轻微虚化；可调 3～10
static CGFloat const kYTTopicHomeBackgroundBlurRadius = 5.0;
/// 顶部背景占位绘制画布高度（与 `YTTalkImageAspectFitInBounds` 画布一致）
static CGFloat const kYTTopicHomeHeaderBackgroundCanvasHeight = 260.0;

// 用于更新三张难度卡片的标题/副标题（不大改 UI 结构）
static NSInteger const kYTTopicHomeCardTitleLabelTag = 901001;
static NSInteger const kYTTopicHomeCardSubtitleLabelTag = 901002;
static NSInteger const kYTTopicHomeCardContentViewTag = 901003;

/// 转为 OrientationUp，避免 CGImage + CI 与 UIImage 展示不一致导致边缘异常
static UIImage *YTTopicHomeImageNormalizedUp(UIImage *image) {
    if (!image) return image;
    if (image.imageOrientation == UIImageOrientationUp) return image;
    UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    UIImage *out = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return out ?: image;
}

/// 轻微高斯模糊：先 CIAffineClamp 再模糊，避免边缘向外采样透明/白底形成「一圈白」
static UIImage *YTTopicHomeImageByApplyingGaussianBlur(UIImage *image, CGFloat radius) {
    if (!image || image.size.width < 1.0 || image.size.height < 1.0) return image;

    UIImage *flat = YTTopicHomeImageNormalizedUp(image);
    CGImageRef cgImage = flat.CGImage;
    if (!cgImage) return image;

    CIImage *input = [CIImage imageWithCGImage:cgImage];
    if (!input) return image;

    CIFilter *clamp = [CIFilter filterWithName:@"CIAffineClamp"];
    [clamp setValue:input forKey:kCIInputImageKey];
    [clamp setValue:[NSValue valueWithCGAffineTransform:CGAffineTransformIdentity] forKey:kCIInputTransformKey];
    CIImage *clamped = clamp.outputImage;
    if (!clamped) return image;

    CIFilter *blur = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blur setValue:clamped forKey:kCIInputImageKey];
    [blur setValue:@(radius) forKey:kCIInputRadiusKey];
    CIImage *output = blur.outputImage;
    if (!output) return image;

    CGRect extent = input.extent;
    CIImage *cropped = [output imageByCroppingToRect:extent];
    if (!cropped) return image;

    static CIContext *ctx = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ctx = [CIContext contextWithOptions:nil];
    });
    CGImageRef outCG = [ctx createCGImage:cropped fromRect:extent];
    if (!outCG) return image;
    UIImage *result = [UIImage imageWithCGImage:outCG scale:flat.scale orientation:UIImageOrientationUp];
    CGImageRelease(outCG);
    return result ?: image;
}

@interface TalkTopicHomeViewController ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
/// 背景图底部与页面底色之间的渐变过渡，消除硬切割
@property (nonatomic, strong) UIView *headerBottomFadeView;
@property (nonatomic, strong) CAGradientLayer *headerBottomFadeGradientLayer;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIStackView *lockStackView;
@property (nonatomic, strong) UIImageView *beginnerLockImageView;
@property (nonatomic, strong) UIImageView *intermediateLockImageView;
@property (nonatomic, strong) UIImageView *advancedLockImageView;

@property (nonatomic, strong) UIStackView *cardsStackView;

@property (nonatomic, strong) UIView *beginnerCard;
@property (nonatomic, strong) UIView *intermediateCard;
@property (nonatomic, strong) UIView *advancedCard;

@property (nonatomic, strong) YTTopicLevelProgressIndicator *beginnerProgressIndicator;
@property (nonatomic, strong) YTTopicLevelProgressIndicator *intermediateProgressIndicator;
@property (nonatomic, strong) YTTopicLevelProgressIndicator *advancedProgressIndicator;

@property (nonatomic, assign) BOOL isRequestingUnits;

// topic-home 接口返回的数据
@property (nonatomic, copy) NSString *topicHomeBackgroundUrl;
@property (nonatomic, assign) CGFloat unlockThresholdProgressRatio; // 兼容旧逻辑：与初→中门槛同步，默认 0.6
/// 入门级进度 ≥ 该 % 可进入进阶（`unlock_threshold` 在 level=1 行，表示解锁下一档所需的本档进度）
@property (nonatomic, assign) NSInteger unlockThresholdBeginnerToIntermediatePercent;
/// 进阶进度 ≥ 该 % 可进入困难（`unlock_threshold` 在 level=2 行）
@property (nonatomic, assign) NSInteger unlockThresholdIntermediateToAdvancedPercent;
@property (nonatomic, assign) BOOL didLoadTopicHome;
@property (nonatomic, assign) BOOL isRequestingTopicHome;

@property (nonatomic, assign) CGFloat beginnerProgressRatio;
@property (nonatomic, assign) CGFloat intermediateProgressRatio;
@property (nonatomic, assign) CGFloat advancedProgressRatio;

@property (nonatomic, assign) BOOL beginnerBadgeUnlocked;
@property (nonatomic, assign) BOOL intermediateBadgeUnlocked;
@property (nonatomic, assign) BOOL advancedBadgeUnlocked;

/// 是否已用 `/talk/level` 成功刷新（解锁：上一难度 `is_medal` 或进度达 `unlock_threshold`）
@property (nonatomic, assign) BOOL didApplyTalkLevelAPI;
@property (nonatomic, assign) BOOL beginnerEntryUnlocked;
@property (nonatomic, assign) BOOL intermediateEntryUnlocked;
@property (nonatomic, assign) BOOL advancedEntryUnlocked;
@property (nonatomic, assign) NSInteger beginnerLevelRecordId;
@property (nonatomic, assign) NSInteger intermediateLevelRecordId;
@property (nonatomic, assign) NSInteger advancedLevelRecordId;

@end

@implementation TalkTopicHomeViewController

#pragma mark - 生命周期

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 使用工程统一的全局返回按钮（同首页 push 后页面一致），因此隐藏系统导航栏避免重叠
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    // 不先清空 UI；进入页面时强制刷新一次数据（请求成功后再 set 并 refresh）
    [self yt_refreshTopicHomeData];
    // 先根据当前已缓存的值刷新一次（请求完成后会再次刷新）
    [self refreshTopicLevelProgressIndicators];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.headerBottomFadeGradientLayer && self.headerBottomFadeView) {
        self.headerBottomFadeGradientLayer.frame = self.headerBottomFadeView.bounds;
    }
    // viewWillAppear 往往早于卡片/指示器首帧布局，圆环 path 未建立时描边不画；布局完成后再刷一次进度与主题色
    [self refreshTopicLevelProgressIndicators];
    [self yt_updateDifficultyCardShadowPathsIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 离开后恢复，避免影响其它页面
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"talk_topic_home";
    self.view.backgroundColor = [theAppDelegate.window colorWithHexString:@"#F6F8FF" alpha:1];

    self.unlockThresholdProgressRatio = 0.6;
    self.unlockThresholdBeginnerToIntermediatePercent = 60;
    self.unlockThresholdIntermediateToAdvancedPercent = 60;
    self.beginnerProgressRatio = 0;
    self.intermediateProgressRatio = 0;
    self.advancedProgressRatio = 0;
    self.beginnerBadgeUnlocked = NO;
    self.intermediateBadgeUnlocked = NO;
    self.advancedBadgeUnlocked = NO;
    self.didLoadTopicHome = NO;
    self.isRequestingTopicHome = NO;
    self.didApplyTalkLevelAPI = NO;
    self.beginnerEntryUnlocked = YES;
    self.intermediateEntryUnlocked = NO;
    self.advancedEntryUnlocked = NO;
    self.beginnerLevelRecordId = 1;
    self.intermediateLevelRecordId = 2;
    self.advancedLevelRecordId = 3;

    [self setupUI];
    [self yt_applySceneListCoverImageIfNeeded];
    // 返回按钮统一走工程封装（图标/点击区域等）
    [self addGlobalBackButtonColor:[UIColor colorWithWhite:1.0 alpha:0.85] headerTitleDic:@{}];

    if (self.scenePageTitle.length > 0) {
        self.titleLabel.text = self.scenePageTitle;
    }
    if (self.scenePageSubtitle.length > 0) {
        self.subtitleLabel.text = self.scenePageSubtitle;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yt_onAppLanguageDidChange:)
                                                 name:LanguageDidChangeNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LanguageDidChangeNotification object:nil];
}

- (void)yt_onAppLanguageDidChange:(NSNotification *)note {
    (void)note;
    [self refreshTopicLevelProgressIndicators];
}

#pragma mark - UI

/// 与学习流一致：`talk_default` 在画布内按半宽×半高居中绘制，再作顶部背景
- (CGSize)yt_topicHeaderCanvasSize {
    CGFloat w = CGRectGetWidth(UIScreen.mainScreen.bounds);
    if (w < 1.0) {
        w = (CGFloat)SCREEN_WIDTH;
    }
    return CGSizeMake(w, kYTTopicHomeHeaderBackgroundCanvasHeight);
}

- (UIImage *)yt_topicHeaderPlaceholderImage {
    UIImage *raw = [UIImage imageNamed:@"talk_default"];
    if (!raw) {
        return nil;
    }
    return YTTalkImageAspectFitInBounds(raw, [self yt_topicHeaderCanvasSize], 0, 0.5) ?: raw;
}

- (void)yt_remakeBackgroundImageViewConstraintsForImage:(UIImage *)img {
    if (!self.backgroundImageView.superview) {
        return;
    }
    [self.backgroundImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        if (img && img.size.width > 0 && img.size.height > 0) {
            CGFloat ratio = img.size.height / img.size.width;
            make.height.equalTo(self.view.mas_width).multipliedBy(ratio);
        } else {
            make.height.mas_equalTo(kYTTopicHomeHeaderBackgroundCanvasHeight);
        }
    }];
}

/// 列表传入的 `cover_image` 完整 URL，优先展示；`/talk/level` 若返回背景 URL 会取消本次加载并覆盖
- (void)yt_applySceneListCoverImageIfNeeded {
    NSString *urlStr = self.sceneListCoverImageURLString;
    if (urlStr.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:urlStr];
    if (!url) {
        return;
    }
    UIImage *ph = [self yt_topicHeaderPlaceholderImage];
    __weak typeof(self) weakSelf = self;
    [self.backgroundImageView sd_setImageWithURL:url
                                placeholderImage:ph
                                         options:0
                                       completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (image && !error) {
            [self yt_remakeBackgroundImageViewConstraintsForImage:image];
            [self yt_enqueueCoreImageBlurForBackgroundImage:image];
        }
    }];
}

/// 服务端 `/talk/level` 返回的顶部背景（若存在）
- (void)yt_applyTopicHomeBackgroundURLStringFromServer:(nullable NSString *)bgUrl {
    NSString *trimmed = [bgUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:trimmed];
    if (!url) {
        return;
    }
    self.topicHomeBackgroundUrl = trimmed;
    [self.backgroundImageView sd_cancelCurrentImageLoad];
    UIImage *ph = [self yt_topicHeaderPlaceholderImage];
    __weak typeof(self) weakSelf = self;
    [self.backgroundImageView sd_setImageWithURL:url
                                placeholderImage:ph
                                         options:0
                                       completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        if (image && !error) {
            [self yt_remakeBackgroundImageViewConstraintsForImage:image];
            [self yt_enqueueCoreImageBlurForBackgroundImage:image];
        }
    }];
}

- (void)setupUI {
    [self.view addSubview:self.backgroundImageView];
    [self yt_remakeBackgroundImageViewConstraintsForImage:self.backgroundImageView.image];

    // 底部渐变：图片区域平滑融入 self.view 背景色，避免与下方区域硬边
    UIColor *pageBG = self.view.backgroundColor ?: [theAppDelegate.window colorWithHexString:@"#F6F8FF" alpha:1];
    UIView *fade = [[UIView alloc] init];
    fade.userInteractionEnabled = NO;
    fade.backgroundColor = [UIColor clearColor];
    CAGradientLayer *fadeGr = [CAGradientLayer layer];
    fadeGr.startPoint = CGPointMake(0.5, 0.0);
    fadeGr.endPoint = CGPointMake(0.5, 1.0);
    fadeGr.colors = @[
        (id)[UIColor clearColor].CGColor,
        (id)[pageBG colorWithAlphaComponent:0.35].CGColor,
        (id)pageBG.CGColor
    ];
    fadeGr.locations = @[@0.0, @0.45, @1.0];
    [fade.layer addSublayer:fadeGr];
    self.headerBottomFadeView = fade;
    self.headerBottomFadeGradientLayer = fadeGr;
    [self.view addSubview:fade];
    [fade mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.backgroundImageView);
        make.height.mas_equalTo(140);
    }];

    [self.view addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        make.top.mas_equalTo(statusBarH + 45 + 13);
        make.left.greaterThanOrEqualTo(self.view).offset(16);
        make.right.lessThanOrEqualTo(self.view).offset(-16);
    }];

    [self.view addSubview:self.subtitleLabel];
    [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.greaterThanOrEqualTo(self.view).offset(16);
        make.right.lessThanOrEqualTo(self.view).offset(-16);
    }];

    [self.view addSubview:self.lockStackView];
    [self.lockStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.subtitleLabel.mas_bottom).offset(18);
        make.height.mas_equalTo(42);
    }];

    [self.view addSubview:self.cardsStackView];
    [self.cardsStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(self.lockStackView.mas_bottom).offset(80);
    }];

    [self.cardsStackView addArrangedSubview:self.beginnerCard];
    [self.cardsStackView addArrangedSubview:self.intermediateCard];
    [self.cardsStackView addArrangedSubview:self.advancedCard];

    [self.beginnerCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(86);
    }];
    [self.intermediateCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(86);
    }];
    [self.advancedCard mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(86);
    }];

    [self yt_enqueueCoreImageBlurForBackgroundImage:self.backgroundImageView.image];
}

- (void)yt_enqueueCoreImageBlurForBackgroundImage:(UIImage *)source {
    if (!source) return;
    UIImage *sourceCopy = source;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        UIImage *blurred = YTTopicHomeImageByApplyingGaussianBlur(sourceCopy, kYTTopicHomeBackgroundBlurRadius);
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            self.backgroundImageView.image = blurred;
        });
    });
}

- (UIView *)buildCardWithTitle:(NSString *)title
                      subtitle:(NSString *)subtitle
                trailingWidget:(UIView *)trailingWidget
{
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor clearColor];
    card.layer.cornerRadius = 16;
    card.layer.masksToBounds = NO;

    UIView *content = [[UIView alloc] init];
    content.tag = kYTTopicHomeCardContentViewTag;
    content.backgroundColor = [UIColor whiteColor];
    content.layer.cornerRadius = 16;
    content.layer.masksToBounds = YES;
    [card addSubview:content];
    [content mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(card);
    }];

    UILabel *lblTitle = [[UILabel alloc] init];
    lblTitle.text = title;
    lblTitle.tag = kYTTopicHomeCardTitleLabelTag;
    lblTitle.textColor = BLACK_COLOR_1F;
    lblTitle.font = [UIFont fontWithName:FONT_NAME_Semibold size:18];
    [content addSubview:lblTitle];

    UILabel *lblSubtitle = [[UILabel alloc] init];
    lblSubtitle.text = subtitle;
    lblSubtitle.tag = kYTTopicHomeCardSubtitleLabelTag;
    lblSubtitle.textColor = [UIColor colorWithWhite:0.35 alpha:1.0];
    lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:13];
    [content addSubview:lblSubtitle];

    [content addSubview:trailingWidget];

    [lblTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(content).offset(18);
        make.top.equalTo(content).offset(18);
        make.right.lessThanOrEqualTo(trailingWidget.mas_left).offset(-12);
    }];

    [lblSubtitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(lblTitle);
        make.top.equalTo(lblTitle.mas_bottom).offset(6);
        make.right.lessThanOrEqualTo(trailingWidget.mas_left).offset(-12);
    }];

    [trailingWidget mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(content);
        make.right.equalTo(content).offset(-16);
    }];

    return card;
}

#pragma mark - 进度展示

- (NSString *)yt_effectiveLearningSceneId {
    return (self.talkLearningSceneId.length > 0) ? self.talkLearningSceneId : kTalkTopicSceneId;
}

- (void)yt_setCardTitle:(NSString *)title subtitle:(NSString *)subtitle forCard:(UIView *)card {
    if (!card) return;
    UIView *t = [card viewWithTag:kYTTopicHomeCardTitleLabelTag];
    if ([t isKindOfClass:[UILabel class]]) {
        ((UILabel *)t).text = title ?: @"";
    }
    UIView *s = [card viewWithTag:kYTTopicHomeCardSubtitleLabelTag];
    if ([s isKindOfClass:[UILabel class]]) {
        ((UILabel *)s).text = subtitle ?: @"";
    }
}

- (void)yt_fetchTopicHomeDataIfNeeded {
    if (self.didLoadTopicHome) return;
    [self yt_refreshTopicHomeData];
}

- (void)yt_refreshTopicHomeData {
    if (self.isRequestingTopicHome) return;
    self.isRequestingTopicHome = YES;

 
        [[GlobalHUDManager shared] showSpinnerOnly];
 

    if (self.talkSceneNumericId <= 0) {
        [[GlobalHUDManager shared] hide];
        self.isRequestingTopicHome = NO;
        [self yt_hideTopicLevelCardsForMissingServerData];
        return;
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    params[@"scene_id"] = @(self.talkSceneNumericId);

    __weak typeof(self) weakSelf = self;
    [HttpTools postRequest:@"/talk/level" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
 
            [[GlobalHUDManager shared] hide];

        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isRequestingTopicHome = NO;
        if (success) {
            id rawData = response.data;
            NSArray *itemsArray = nil;
            NSString *bgUrlFromLevel = nil;
            if ([rawData isKindOfClass:[NSArray class]]) {
                itemsArray = (NSArray *)rawData;
            } else if ([rawData isKindOfClass:[NSDictionary class]]) {
                NSDictionary *d = (NSDictionary *)rawData;
                id levels = d[@"levels"];
                if ([levels isKindOfClass:[NSArray class]]) {
                    itemsArray = levels;
                }
                id bg = d[@"background_url"];
                if (![bg isKindOfClass:[NSString class]]) {
                    bg = d[@"backgroundUrl"];
                }
                if ([bg isKindOfClass:[NSString class]]) {
                    bgUrlFromLevel = [(NSString *)bg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
            }
            NSArray<YTTalkLevelItem *> *items = [YTTalkLevelItem itemsByParsingAPIData:itemsArray ?: @[]];
            [self yt_applyTalkLevelItems:items];
            [self yt_applyTopicHomeBackgroundURLStringFromServer:bgUrlFromLevel];
        } else {
            [self yt_hideTopicLevelCardsForMissingServerData];
        }
    } failure:^(NSError * _Nonnull error) {
        
            [[GlobalHUDManager shared] hide];
 
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.isRequestingTopicHome = NO;
        [self yt_hideTopicLevelCardsForMissingServerData];
    }];
}

- (void)yt_hideTopicLevelCardsForMissingServerData {
    self.didLoadTopicHome = YES;
    self.didApplyTalkLevelAPI = NO;
    self.cardsStackView.hidden = YES;
}

- (void)yt_applyTopicHomeData:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) return;
    self.didLoadTopicHome = YES;
    self.didApplyTalkLevelAPI = NO;
    self.cardsStackView.hidden = NO;

    // unlockThresholdPercent：用于控制 Intermediate/Advanced 解锁阈值
    NSInteger thresholdPercent = 60;
    id thrObj = data[@"unlockThresholdPercent"];
    if ([thrObj isKindOfClass:[NSNumber class]]) {
        thresholdPercent = [(NSNumber *)thrObj integerValue];
    }
    self.unlockThresholdProgressRatio = (CGFloat)thresholdPercent / 100.0;
    self.unlockThresholdBeginnerToIntermediatePercent = thresholdPercent;
    self.unlockThresholdIntermediateToAdvancedPercent = thresholdPercent;

    // backgroundUrl
    NSString *bgUrl = nil;
    id bgObj = data[@"backgroundUrl"];
    if ([bgObj isKindOfClass:[NSString class]]) {
        bgUrl = (NSString *)bgObj;
    }
    self.topicHomeBackgroundUrl = bgUrl;
    if (bgUrl.length > 0) {
        UIImage *placeholder = [self yt_topicHeaderPlaceholderImage] ?: [UIImage imageNamed:@"talk_default"];
        __weak typeof(self) weakSelf = self;
        [self.backgroundImageView sd_cancelCurrentImageLoad];
        [self.backgroundImageView sd_setImageWithURL:[NSURL URLWithString:bgUrl]
                                    placeholderImage:placeholder
                                           completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            if (image && !error) {
                [self yt_remakeBackgroundImageViewConstraintsForImage:image];
                [self yt_enqueueCoreImageBlurForBackgroundImage:image];
            }
        }];
    }
    // 无网络图时沿用 setupUI 里已对占位图做的模糊

    // levels
    NSArray *levels = data[@"levels"];
    if (![levels isKindOfClass:[NSArray class]]) levels = @[];

    for (NSDictionary *lv in levels) {
        if (![lv isKindOfClass:[NSDictionary class]]) continue;
        NSInteger levelId = [lv[@"levelId"] integerValue];
        CGFloat progressPercent = 0;
        id pObj = lv[@"progressPercent"];
        if ([pObj isKindOfClass:[NSNumber class]]) {
            progressPercent = [(NSNumber *)pObj floatValue];
        }
        CGFloat ratio = progressPercent / 100.0;
        ratio = MAX(0.0, MIN(1.0, ratio));

        // 顶部三枚徽章：优先 `is_medal`（1 是 / 0 否）；否则兼容 `badgeUnlocked` 或按进度 100% 推导
        BOOL badgeUnlocked = NO;
        id medalObj = lv[@"is_medal"];
        if ([medalObj isKindOfClass:[NSNumber class]]) {
            badgeUnlocked = [(NSNumber *)medalObj integerValue] != 0;
        } else {
            id badgeObj = lv[@"badgeUnlocked"];
            if ([badgeObj isKindOfClass:[NSNumber class]]) {
                badgeUnlocked = [(NSNumber *)badgeObj boolValue];
            } else {
                badgeUnlocked = (progressPercent >= 100.0 - 1e-5);
            }
        }

        NSString *title = @"";
        NSString *subtitle = @"";
        if ([lv[@"title"] isKindOfClass:[NSString class]]) {
            title = (NSString *)lv[@"title"];
        }
        if ([lv[@"subtitle"] isKindOfClass:[NSString class]]) {
            subtitle = (NSString *)lv[@"subtitle"];
        }

        switch (levelId) {
            case YTLevelIdBeginner: {
                self.beginnerProgressRatio = ratio;
                self.beginnerBadgeUnlocked = badgeUnlocked;
                [self yt_setCardTitle:title subtitle:subtitle forCard:self.beginnerCard];
            } break;
            case YTLevelIdIntermediate: {
                self.intermediateProgressRatio = ratio;
                self.intermediateBadgeUnlocked = badgeUnlocked;
                [self yt_setCardTitle:title subtitle:subtitle forCard:self.intermediateCard];
            } break;
            case YTLevelIdAdvanced: {
                self.advancedProgressRatio = ratio;
                self.advancedBadgeUnlocked = badgeUnlocked;
                [self yt_setCardTitle:title subtitle:subtitle forCard:self.advancedCard];
            } break;
            default:
                break;
        }
    }

    self.beginnerEntryUnlocked = YES;
    [self yt_recomputeIntermediateAdvancedEntryUnlockedUsingThresholds];

    [self refreshTopicLevelProgressIndicators];
}

/// 根据上一难度 `is_medal` 与 `unlock_threshold` 更新进阶/困难是否可进入（有勋章则不再要求门槛进度）
- (void)yt_recomputeIntermediateAdvancedEntryUnlockedUsingThresholds {
    NSInteger thBI = self.unlockThresholdBeginnerToIntermediatePercent > 0 ? self.unlockThresholdBeginnerToIntermediatePercent : 60;
    NSInteger thIA = self.unlockThresholdIntermediateToAdvancedPercent > 0 ? self.unlockThresholdIntermediateToAdvancedPercent : 60;
    BOOL beginnerMeetsThreshold = (self.beginnerProgressRatio * 100.0 >= (CGFloat)thBI - 1e-5);
    BOOL intermediateMeetsThreshold = (self.intermediateProgressRatio * 100.0 >= (CGFloat)thIA - 1e-5);
    self.intermediateEntryUnlocked = self.beginnerBadgeUnlocked || beginnerMeetsThreshold;
    self.advancedEntryUnlocked = self.intermediateBadgeUnlocked || intermediateMeetsThreshold;
}

/// 应用 `POST /talk/level` 的 `data` 数组（`level` 1/2/3；进阶/困难解锁：上一档 `is_medal` 或达 `unlock_threshold`；顶部三徽章用 `is_medal`）
- (void)yt_applyTalkLevelItems:(NSArray<YTTalkLevelItem *> *)items {
    if (items.count == 0) {
        [self yt_hideTopicLevelCardsForMissingServerData];
        return;
    }

    self.cardsStackView.hidden = NO;
    self.didApplyTalkLevelAPI = YES;
    self.didLoadTopicHome = YES;

    NSInteger thBI = 60;
    NSInteger thIA = 60;
    for (YTTalkLevelItem *it in items) {
        if (it.level == 1 && it.unlockThreshold > 0) {
            thBI = it.unlockThreshold;
        }
        if (it.level == 2 && it.unlockThreshold > 0) {
            thIA = it.unlockThreshold;
        }
    }
    self.unlockThresholdBeginnerToIntermediatePercent = thBI;
    self.unlockThresholdIntermediateToAdvancedPercent = thIA;
    self.unlockThresholdProgressRatio = thBI / 100.0;

    self.beginnerProgressRatio = 0;
    self.intermediateProgressRatio = 0;
    self.advancedProgressRatio = 0;
    self.beginnerBadgeUnlocked = NO;
    self.intermediateBadgeUnlocked = NO;
    self.advancedBadgeUnlocked = NO;
    self.beginnerEntryUnlocked = YES;
    self.intermediateEntryUnlocked = NO;
    self.advancedEntryUnlocked = NO;
    self.beginnerLevelRecordId = 1;
    self.intermediateLevelRecordId = 2;
    self.advancedLevelRecordId = 3;

    [self yt_setCardTitle:@"" subtitle:@"" forCard:self.beginnerCard];
    [self yt_setCardTitle:@"" subtitle:@"" forCard:self.intermediateCard];
    [self yt_setCardTitle:@"" subtitle:@"" forCard:self.advancedCard];

    for (YTTalkLevelItem *it in items) {
        NSInteger apiLevel = it.level;
        YTLevelId lid = YTLevelIdBeginner;
        if (apiLevel == 1) {
            lid = YTLevelIdBeginner;
        } else if (apiLevel == 2) {
            lid = YTLevelIdIntermediate;
        } else if (apiLevel == 3) {
            lid = YTLevelIdAdvanced;
        } else {
            continue;
        }

        CGFloat pct = MAX(0.0, MIN(100.0, (CGFloat)it.progressPercent));
        CGFloat ratio = pct / 100.0;
        NSString *title = it.title ?: @"";
        NSString *subtitle = it.subtitle ?: @"";

        switch (lid) {
            case YTLevelIdBeginner:
                self.beginnerProgressRatio = ratio;
                self.beginnerBadgeUnlocked = it.isMedal;
                self.beginnerEntryUnlocked = it.isUnlocked;
                self.beginnerLevelRecordId = it.levelRecordId > 0 ? it.levelRecordId : 1;
                [self yt_setCardTitle:title subtitle:subtitle forCard:self.beginnerCard];
                break;
            case YTLevelIdIntermediate:
                self.intermediateProgressRatio = ratio;
                self.intermediateBadgeUnlocked = it.isMedal;
                self.intermediateLevelRecordId = it.levelRecordId > 0 ? it.levelRecordId : 2;
                [self yt_setCardTitle:title subtitle:subtitle forCard:self.intermediateCard];
                break;
            case YTLevelIdAdvanced:
                self.advancedProgressRatio = ratio;
                self.advancedBadgeUnlocked = it.isMedal;
                self.advancedLevelRecordId = it.levelRecordId > 0 ? it.levelRecordId : 3;
                [self yt_setCardTitle:title subtitle:subtitle forCard:self.advancedCard];
                break;
            default:
                break;
        }
    }

    [self yt_recomputeIntermediateAdvancedEntryUnlockedUsingThresholds];

    [self refreshTopicLevelProgressIndicators];
}

- (CGFloat)yt_talkProgressRatioForLevel:(YTLevelId)levelId {
    switch (levelId) {
        case YTLevelIdBeginner: return self.beginnerProgressRatio;
        case YTLevelIdIntermediate: return self.intermediateProgressRatio;
        case YTLevelIdAdvanced: return self.advancedProgressRatio;
        default: return 0;
    }
}

- (CGFloat)progressRatioForDisplayLevel:(YTLevelId)levelId {
    return [self yt_talkProgressRatioForLevel:levelId];
}

- (void)refreshTopicLevelProgressIndicators {
    CGFloat beginnerRatio = [self yt_talkProgressRatioForLevel:YTLevelIdBeginner];
    CGFloat intermediateRatio = [self yt_talkProgressRatioForLevel:YTLevelIdIntermediate];
    CGFloat advancedRatio = [self yt_talkProgressRatioForLevel:YTLevelIdAdvanced];

    [self yt_updateLockBadgesWithBeginnerUnlocked:self.beginnerBadgeUnlocked
                                     intermediateUnlocked:self.intermediateBadgeUnlocked
                                            advancedUnlocked:self.advancedBadgeUnlocked];

    // 卡片完成样式：`is_medal` 为真直接完成；为假仍按原逻辑（进度 100%）
    BOOL bCardDone = self.beginnerBadgeUnlocked || (beginnerRatio >= 1.0 - 1e-5);
    BOOL iCardDone = self.intermediateBadgeUnlocked || (intermediateRatio >= 1.0 - 1e-5);
    BOOL aCardDone = self.advancedBadgeUnlocked || (advancedRatio >= 1.0 - 1e-5);
    [self yt_applyDifficultyCardStyle:self.beginnerCard levelId:YTLevelIdBeginner completed:bCardDone];
    [self yt_applyDifficultyCardStyle:self.intermediateCard levelId:YTLevelIdIntermediate completed:iCardDone];
    [self yt_applyDifficultyCardStyle:self.advancedCard levelId:YTLevelIdAdvanced completed:aCardDone];

    // 右侧圆环/勾：`is_medal` 为真直接完成勾；为假仍只按 `progress_percent` 比例
    CGFloat beginnerIndicatorRatio = self.beginnerBadgeUnlocked ? 1.0 : beginnerRatio;
    CGFloat intermediateIndicatorRatio = self.intermediateBadgeUnlocked ? 1.0 : intermediateRatio;
    CGFloat advancedIndicatorRatio = self.advancedBadgeUnlocked ? 1.0 : advancedRatio;
    [self.beginnerProgressIndicator configureWithProgressRatio:beginnerIndicatorRatio
                                                         theme:[YTDifficultyTheme themeForLevel:YTLevelIdBeginner]];
    [self.intermediateProgressIndicator configureWithProgressRatio:intermediateIndicatorRatio
                                                             theme:[YTDifficultyTheme themeForLevel:YTLevelIdIntermediate]];
    [self.advancedProgressIndicator configureWithProgressRatio:advancedIndicatorRatio
                                                         theme:[YTDifficultyTheme themeForLevel:YTLevelIdAdvanced]];
}

/// 未完成：白底 + 轻阴影；已完成：难度色底 + 对应色阴影（offset 0,2 radius 10）
- (void)yt_applyDifficultyCardStyle:(UIView *)card levelId:(YTLevelId)levelId completed:(BOOL)completed {
    if (!card) return;
    UIView *content = [card viewWithTag:kYTTopicHomeCardContentViewTag];
    if (!content) return;

    if (completed) {
        UIColor *fill = nil;
        UIColor *shadow = nil;
        switch (levelId) {
            case YTLevelIdBeginner:
                fill = [theAppDelegate.window colorWithHexString:@"#F3FAF7" alpha:1];
                shadow = [theAppDelegate.window colorWithHexString:@"#CCDDD7" alpha:1];
                break;
            case YTLevelIdIntermediate:
                fill = [theAppDelegate.window colorWithHexString:@"#F0F5FF" alpha:1];
                shadow = [theAppDelegate.window colorWithHexString:@"#DDE6F4" alpha:1];
                break;
            case YTLevelIdAdvanced:
                fill = [theAppDelegate.window colorWithHexString:@"#F0E8FF" alpha:1];
                shadow = [theAppDelegate.window colorWithHexString:@"#DDD4E7" alpha:1];
                break;
            default:
                fill = [UIColor whiteColor];
                shadow = [[UIColor blackColor] colorWithAlphaComponent:0.12];
                break;
        }
        content.backgroundColor = fill;
        card.layer.shadowColor = shadow.CGColor;
        card.layer.shadowOpacity = 1.0;
    } else {
        content.backgroundColor = [UIColor whiteColor];
        card.layer.shadowColor = [UIColor blackColor].CGColor;
        card.layer.shadowOpacity = 0.08;
    }
    card.layer.shadowOffset = CGSizeMake(0, 2);
    card.layer.shadowRadius = 10.0;

    CGRect b = card.bounds;
    if (b.size.width > 0.5 && b.size.height > 0.5) {
        card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:b cornerRadius:16].CGPath;
    } else {
        card.layer.shadowPath = nil;
    }
}

/// 首帧 bounds 为 0 时 shadowPath 延后到 layout 再补
- (void)yt_updateDifficultyCardShadowPathsIfNeeded {
    for (UIView *card in @[self.beginnerCard, self.intermediateCard, self.advancedCard]) {
        if (!card) continue;
        CGRect b = card.bounds;
        if (b.size.width < 0.5 || b.size.height < 0.5) continue;
        card.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:b cornerRadius:16].CGPath;
    }
}

/// 与 App 界面语言（`LanguageHelper`）一致；资产仅 `zh` / `en` 两套，其它语言回退 `en`
- (NSString *)yt_lockBadgeAssetLanguageSuffix {
    NSString *lang = [LanguageHelper currentLanguage] ?: @"en";
    if ([lang hasPrefix:@"zh"]) {
        return @"zh";
    }
    return @"en";
}

- (NSString *)yt_unlockBadgeImageNameForLevel:(YTLevelId)levelId {
    NSString *difficulty = @"advanced";
    if (levelId == YTLevelIdBeginner) {
        difficulty = @"beginner";
    } else if (levelId == YTLevelIdIntermediate) {
        difficulty = @"intermediate";
    }
    NSString *langToken = [self yt_lockBadgeAssetLanguageSuffix];
    return [NSString stringWithFormat:@"talk_level_badge_unlock_%@_%@", difficulty, langToken];
}

- (void)yt_updateLockImageView:(UIImageView *)imageView levelId:(YTLevelId)levelId unlocked:(BOOL)unlocked {
    UIImage *img = nil;
    if (unlocked) {
        NSString *name = [self yt_unlockBadgeImageNameForLevel:levelId];
        img = [UIImage imageNamed:name];
        // 兼容历史错误资源名：beginner_zh imageset 目录尾部误带了换行符
        if (!img && levelId == YTLevelIdBeginner && [[self yt_lockBadgeAssetLanguageSuffix] isEqualToString:@"zh"]) {
            img = [UIImage imageNamed:@"talk_level_badge_unlock_beginner_zh\n"];
        }
    }
    if (!img) {
        img = [UIImage imageNamed:@"talk_lock"];
    }
    imageView.image = img;
}

- (void)yt_updateLockBadgesWithBeginnerUnlocked:(BOOL)beginnerUnlocked
                           intermediateUnlocked:(BOOL)intermediateUnlocked
                                   advancedUnlocked:(BOOL)advancedUnlocked {
    [self yt_updateLockImageView:self.beginnerLockImageView levelId:YTLevelIdBeginner unlocked:beginnerUnlocked];
    [self yt_updateLockImageView:self.intermediateLockImageView levelId:YTLevelIdIntermediate unlocked:intermediateUnlocked];
    [self yt_updateLockImageView:self.advancedLockImageView levelId:YTLevelIdAdvanced unlocked:advancedUnlocked];
}

#pragma mark - 懒加载

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] init];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backgroundImageView.clipsToBounds = YES;
        _backgroundImageView.image = [self yt_topicHeaderPlaceholderImage] ?: [UIImage imageNamed:@"talk_default"];
        if (!_backgroundImageView.image) {
            _backgroundImageView.backgroundColor = [theAppDelegate.window colorWithHexString:@"#F6F8FF" alpha:1];
        }
    }
    return _backgroundImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = NSLocalizedString(@"Talk_TopicHome_Title", @"");
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:FONT_NAME_Semibold size:26];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

- (UILabel *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.text = NSLocalizedString(@"Talk_TopicHome_Subtitle", @"");
        _subtitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.85];
        _subtitleLabel.font = [UIFont fontWithName:FONT_NAME_Regular size:14];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.numberOfLines = 2;
    }
    return _subtitleLabel;
}

- (UIStackView *)lockStackView {
    if (!_lockStackView) {
        _lockStackView = [[UIStackView alloc] init];
        _lockStackView.axis = UILayoutConstraintAxisHorizontal;
        _lockStackView.alignment = UIStackViewAlignmentCenter;
        _lockStackView.distribution = UIStackViewDistributionEqualSpacing;
        _lockStackView.spacing = 10;
        [_lockStackView addArrangedSubview:self.beginnerLockImageView];
        [_lockStackView addArrangedSubview:self.intermediateLockImageView];
        [_lockStackView addArrangedSubview:self.advancedLockImageView];
    }
    return _lockStackView;
}

- (UIImageView *)beginnerLockImageView {
    if (!_beginnerLockImageView) {
        _beginnerLockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"talk_lock"]];
        _beginnerLockImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_beginnerLockImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(42);
        }];
    }
    return _beginnerLockImageView;
}

- (UIImageView *)intermediateLockImageView {
    if (!_intermediateLockImageView) {
        _intermediateLockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"talk_lock"]];
        _intermediateLockImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_intermediateLockImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(42);
        }];
    }
    return _intermediateLockImageView;
}

- (UIImageView *)advancedLockImageView {
    if (!_advancedLockImageView) {
        _advancedLockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"talk_lock"]];
        _advancedLockImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_advancedLockImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(42);
        }];
    }
    return _advancedLockImageView;
}

- (UIStackView *)cardsStackView {
    if (!_cardsStackView) {
        _cardsStackView = [[UIStackView alloc] init];
        _cardsStackView.axis = UILayoutConstraintAxisVertical;
        _cardsStackView.alignment = UIStackViewAlignmentFill;
        _cardsStackView.distribution = UIStackViewDistributionFill;
        _cardsStackView.spacing = 20;
    }
    return _cardsStackView;
}

- (UIView *)beginnerCard {
    if (!_beginnerCard) {
        _beginnerCard = [self buildCardWithTitle:NSLocalizedString(@"Beginner", @"")
                                        subtitle:NSLocalizedString(@"Key Vocabulary", @"")
                                  trailingWidget:self.beginnerProgressIndicator];
        _beginnerCard.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBeginner)];
        [_beginnerCard addGestureRecognizer:tap];
    }
    return _beginnerCard;
}

- (UIView *)intermediateCard {
    if (!_intermediateCard) {
        _intermediateCard = [self buildCardWithTitle:NSLocalizedString(@"Simple", @"")
                                            subtitle:NSLocalizedString(@"Basic Dialogue & Grammar", @"")
                                      trailingWidget:self.intermediateProgressIndicator];
        _intermediateCard.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapIntermediate)];
        [_intermediateCard addGestureRecognizer:tap];
    }
    return _intermediateCard;
}

- (UIView *)advancedCard {
    if (!_advancedCard) {
        _advancedCard = [self buildCardWithTitle:NSLocalizedString(@"Difficult", @"")
                                        subtitle:NSLocalizedString(@"Politeness, Nuance & Real-life Logic", @"")
                                  trailingWidget:self.advancedProgressIndicator];
        _advancedCard.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapAdvanced)];
        [_advancedCard addGestureRecognizer:tap];
    }
    return _advancedCard;
}

- (YTTopicLevelProgressIndicator *)beginnerProgressIndicator {
    if (!_beginnerProgressIndicator) {
        _beginnerProgressIndicator = [[YTTopicLevelProgressIndicator alloc] init];
    }
    return _beginnerProgressIndicator;
}

- (YTTopicLevelProgressIndicator *)intermediateProgressIndicator {
    if (!_intermediateProgressIndicator) {
        _intermediateProgressIndicator = [[YTTopicLevelProgressIndicator alloc] init];
    }
    return _intermediateProgressIndicator;
}

- (YTTopicLevelProgressIndicator *)advancedProgressIndicator {
    if (!_advancedProgressIndicator) {
        _advancedProgressIndicator = [[YTTopicLevelProgressIndicator alloc] init];
    }
    return _advancedProgressIndicator;
}

#pragma mark - 交互

- (void)onTapBeginner {
    [self pushLearningFlowWithLevel:YTLevelIdBeginner];
}

- (void)onTapIntermediate {
    [self pushLearningFlowWithLevel:YTLevelIdIntermediate];
}

- (void)onTapAdvanced {
    [self pushLearningFlowWithLevel:YTLevelIdAdvanced];
}

- (void)pushLearningFlowWithLevel:(YTLevelId)levelId {
    if (self.isRequestingUnits) return;

    if (![[UserModel sharedInstance] isLogin]) {
        __weak typeof(self) weakSelf = self;
        [[LoginManager sharedManager] handleLoginExpiredWithCompletion:^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            if ([[UserModel sharedInstance] isLogin]) {
                [self pushLearningFlowWithLevel:levelId];
            }
        }];
        return;
    }

    // Intermediate/Advanced 需要解锁条件：必须先拿到后端进度数据
    if (levelId == YTLevelIdIntermediate || levelId == YTLevelIdAdvanced) {
        if (self.isRequestingTopicHome) {
            [YTTipAlertView showInView:self.view
                              topTitle:nil
                           contentText:NSLocalizedString(@"Talk_TopicHome_LoadingProgressWait", @"")
                    primaryButtonTitle:NSLocalizedString(@"OK", @"")
                   secondaryButtonTitle:nil
                                onClose:nil
                             onConfirm:nil
                              onCancel:nil];
            return;
        }
    }

    if ((levelId == YTLevelIdIntermediate || levelId == YTLevelIdAdvanced) && !self.didLoadTopicHome) {
        [self yt_fetchTopicHomeDataIfNeeded];
        [YTTipAlertView showInView:self.view
                          topTitle:nil
                       contentText:NSLocalizedString(@"Talk_TopicHome_LoadingProgressWait", @"")
                primaryButtonTitle:NSLocalizedString(@"OK", @"")
               secondaryButtonTitle:nil
                            onClose:nil
                         onConfirm:nil
                          onCancel:nil];
        return;
    }

    NSString *flowSceneId = [self yt_effectiveLearningSceneId];

    // 解锁：`intermediateEntryUnlocked` / `advancedEntryUnlocked`（含上一档 `is_medal` 或达 `unlock_threshold`）；本地占位同 `yt_applyTopicHomeData`
    if (self.didLoadTopicHome) {
        if (levelId == YTLevelIdBeginner && !self.beginnerEntryUnlocked) {
            [YTTipAlertView showInView:self.view
                              topTitle:nil
                           contentText:NSLocalizedString(@"Talk_LevelEntry_Locked", @"")
                    primaryButtonTitle:NSLocalizedString(@"Talk_Alert_Confirm", @"")
                   secondaryButtonTitle:nil
                                onClose:nil
                             onConfirm:nil
                              onCancel:nil];
            return;
        }
        if (levelId == YTLevelIdIntermediate && !self.intermediateEntryUnlocked) {
            NSInteger thresholdPercent = self.unlockThresholdBeginnerToIntermediatePercent > 0 ? self.unlockThresholdBeginnerToIntermediatePercent : 60;
            NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Talk_TopicHome_UnlockIntermediateNeedPercent", @""), (long)thresholdPercent];
            [YTTipAlertView showInView:self.view
                              topTitle:nil
                           contentText:msg
                    primaryButtonTitle:NSLocalizedString(@"OK", @"")
                   secondaryButtonTitle:nil
                                onClose:nil
                             onConfirm:nil
                              onCancel:nil];
            return;
        }
        if (levelId == YTLevelIdAdvanced && !self.advancedEntryUnlocked) {
            NSInteger thresholdPercent = self.unlockThresholdIntermediateToAdvancedPercent > 0 ? self.unlockThresholdIntermediateToAdvancedPercent : 60;
            NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Talk_TopicHome_UnlockAdvancedNeedPercent", @""), (long)thresholdPercent];
            [YTTipAlertView showInView:self.view
                              topTitle:nil
                           contentText:msg
                    primaryButtonTitle:NSLocalizedString(@"OK", @"")
                   secondaryButtonTitle:nil
                                onClose:nil
                             onConfirm:nil
                              onCancel:nil];
            return;
        }
    }

    self.isRequestingUnits = YES;

    [[GlobalHUDManager shared] showSpinnerOnly];

    __weak typeof(self) weakSelf = self;
    YTMockLearningFlowBootstrapService *bootstrapService = [YTMockLearningFlowBootstrapService shared];
    bootstrapService.talkSceneNumericId = self.talkSceneNumericId;
    NSInteger requestLevelId = levelId + 1;
    if (self.didApplyTalkLevelAPI) {
        if (levelId == YTLevelIdBeginner) {
            requestLevelId = self.beginnerLevelRecordId > 0 ? self.beginnerLevelRecordId : 1;
        } else if (levelId == YTLevelIdIntermediate) {
            requestLevelId = self.intermediateLevelRecordId > 0 ? self.intermediateLevelRecordId : 2;
        } else {
            requestLevelId = self.advancedLevelRecordId > 0 ? self.advancedLevelRecordId : 3;
        }
    }
    [bootstrapService fetchBootstrapForSceneId:flowSceneId levelId:requestLevelId completion:^(YTLearningFlowBootstrap * _Nullable bootstrap, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        [[GlobalHUDManager shared] hide];
        if (!self) return;
        self.isRequestingUnits = NO;
        if (!bootstrap || error) return;

        CGFloat entryRatio = [self yt_talkProgressRatioForLevel:levelId];
        NSInteger entryPct = (NSInteger)llround(MAX(0.0, MIN(1.0, entryRatio)) * 100.0);
        TalkLearningFlowViewController *vc = [[TalkLearningFlowViewController alloc] initWithSceneId:flowSceneId
                                                                                              levelId:levelId
                                                                                   preloadedBootstrap:bootstrap
                                                                           initialProgressPercent:entryPct];
        vc.talkSceneNumericId = self.talkSceneNumericId;
        vc.talkDidApplyLevelAPI = self.didApplyTalkLevelAPI;
        vc.talkBeginnerLevelRecordId = self.beginnerLevelRecordId;
        vc.talkIntermediateLevelRecordId = self.intermediateLevelRecordId;
        vc.talkAdvancedLevelRecordId = self.advancedLevelRecordId;
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }];
}

@end
