//
//  PinyinLettersViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/7/4.
//

#import "PinyinLettersViewController.h"
#import "GridCollectionView.h"
@interface PinyinLettersViewController ()<UIGestureRecognizerDelegate,UINavigationControllerDelegate>
@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) UILabel *lblTitle;
@property (strong, nonatomic) UILabel *lblSubtitle;
@property (strong, nonatomic) UIButton *btnPronunciation;
@property (strong, nonatomic) UIButton *btnAlphabetical;
@property (strong, nonatomic) UIView *line;
@property (nonatomic, strong) GridCollectionView *collectionPronunciation;
@property (nonatomic, strong) GridCollectionView *collectionAlphabetical;

@end

@implementation PinyinLettersViewController
//拼音字母表
//拼音发音   -      字母对照
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageId = @"letters";
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.delegate = self;
    [self addGlobalBackButton];
    //self.navigationController.navigationBarHidden = YES;

    [self.view addSubview:self.headerView];
    [self setupUI];
    [self getPronunciation];
    [self getAlphabetical];
    
    //[self loadLocalData];
    self.collectionPronunciation.dataArrays = [[DataCacheManager loadDataForClass:[self class]] mutableCopy];
    if (self.collectionPronunciation.dataArrays.count > 0) {
        [self.collectionPronunciation reloadData];
    }
}
- (void)setupUI {
    CGRect frame =  CGRectMake(0,self.headerView.frame.size.height + self.headerView.frame.origin.y, SCREEN_WIDTH, SCREEN_HEIGHT - (self.headerView.frame.size.height + self.headerView.frame.origin.y));
    _collectionPronunciation = [[GridCollectionView alloc] initWithFrame:frame];
    _collectionPronunciation.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _collectionPronunciation.tag = 300;
    [_collectionPronunciation setSelectedTypeIndex:^(NSInteger index) {
        //NSLog(@"---点击了------[%d]--------左",(int)index);
    }];
    [self.view addSubview:_collectionPronunciation];
    
    _collectionAlphabetical = [[GridCollectionView alloc] initWithFrame:frame];
    _collectionAlphabetical.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _collectionAlphabetical.tag = 301;
    [_collectionAlphabetical setSelectedTypeIndex:^(NSInteger index) {
        //NSLog(@"---点击了------[%d]----右---",(int)index);
    }];
    [self.view addSubview:_collectionAlphabetical];
    self.collectionPronunciation.hidden = NO;
    self.collectionAlphabetical.hidden = YES;
}
- (UIView *)headerView {
    if (!_headerView) {
        CGFloat statusBarH = [PublicTool getStatusBarHeight];
        CGRect rectNav = self.navigationController.navigationBar.frame;
        CGRect frame = CGRectMake(0, statusBarH + rectNav.size.height, SCREEN_WIDTH, 165 - 15);
        
        _headerView = [[UIView alloc]initWithFrame:frame];
        _headerView.backgroundColor = [UIColor whiteColor];
        [_headerView addSubview:self.lblTitle];
        [_headerView addSubview:self.lblSubtitle];
        [_headerView addSubview:self.btnPronunciation];
        [_headerView addSubview:self.btnAlphabetical];
        
        NSString *title = [NSString stringWithFormat:@"%@",self.dic[@"title"]];
        self.lblTitle.text = title;
        //@"Pinyin Letters 拼音字母表";
        //NSString *subtitle = [NSString stringWithFormat:@"%@",self.dic[@"subtitle"]]; //subtitle;//
        self.lblSubtitle.text = NSLocalizedString(@"Arranged to help you learn sounds faster.",@"");
    
        //self.lettersView.lblTitle.text =
        //self.lettersView.lblSubtitle.text = [NSString stringWithFormat:@"%@",self.dic[@"subtitle"]];
    }
    return _headerView;
}
- (UILabel *)lblTitle {
    if(!_lblTitle){
        _lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(Distance＿M, 35-5, SCREEN_WIDTH - 2 * Distance＿M, 25)];
        _lblTitle.textColor = BLACK_COLOR_1F;
        _lblTitle.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
    }
    return _lblTitle;
}
- (UILabel *)lblSubtitle {
    if(!_lblSubtitle){
        _lblSubtitle = [[UILabel alloc]initWithFrame:CGRectMake(self.lblTitle.frame.origin.x, 10 + self.lblTitle.frame.origin.y + self.lblTitle.frame.size.height, self.lblTitle.frame.size.width, 20)];
        _lblSubtitle.textColor = [self.view colorWithHexString:@"#63637D" alpha:1];
        _lblSubtitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
        _lblSubtitle.numberOfLines = 2;
    }
    return _lblSubtitle;
}
- (UIButton *)btnPronunciation {
    if(!_btnPronunciation){
        _btnPronunciation = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnPronunciation.frame = CGRectMake(Distance＿M,  115, (SCREEN_WIDTH - 2 * Distance＿M)/2, 25);
        [_btnPronunciation setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
        _btnPronunciation.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:18];
        [_btnPronunciation addTarget:self action:@selector(btnPronunciationAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnPronunciation setTitle:NSLocalizedString(@"Pronunciation",@"") forState:UIControlStateNormal];
        
        UIView *line = [[UIView alloc]init];
        line.layer.cornerRadius = LINE_WIDTH/2;
        line.layer.masksToBounds = YES;
        line.backgroundColor = [self.view colorWithHexString:@"#FC789F" alpha:1];
        self.line = line;
        self.line.frame = CGRectMake(Distance＿M + self.btnPronunciation.frame.size.width/4, self.btnPronunciation.frame.origin.y + 31 ,self.btnPronunciation.frame.size.width/2, LINE_WIDTH);
        [self.headerView addSubview:self.line];
    }
    return _btnPronunciation;
}
- (UIButton *)btnAlphabetical {
    if(!_btnAlphabetical){
        _btnAlphabetical = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnAlphabetical.frame = CGRectMake(self.btnPronunciation.frame.origin.x + self.btnPronunciation.frame.size.width + 5, self.btnPronunciation.frame.origin.y, self.btnPronunciation.frame.size.width, 25);
    
        [_btnAlphabetical setTitleColor:[self.view colorWithHexString:@"#B6BDC3" alpha:1] forState:UIControlStateNormal];
        _btnAlphabetical.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:18];
        [_btnAlphabetical addTarget:self action:@selector(btnAlphabeticalAction:) forControlEvents:UIControlEventTouchUpInside];
        [_btnAlphabetical setTitle:NSLocalizedString(@"Alphabetical",@"") forState:UIControlStateNormal];
    }
    return _btnAlphabetical;
}
- (void)btnPronunciationAction:(UIButton *)sender {
    self.collectionPronunciation.hidden = NO;
    self.collectionAlphabetical.hidden = YES;
    
    [self.btnPronunciation setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
    [self.btnAlphabetical setTitleColor:[self.view colorWithHexString:@"#B6BDC3" alpha:1] forState:UIControlStateNormal];
    [UIView animateWithDuration:0.2 animations:^{
        self.line.frame = CGRectMake(Distance＿M + self.btnPronunciation.frame.size.width/4, self.btnPronunciation.frame.origin.y + 31 ,self.btnPronunciation.frame.size.width/2, LINE_WIDTH);
    }];
}
- (void)btnAlphabeticalAction:(UIButton *)sender {
    self.collectionPronunciation.hidden = YES;
    self.collectionAlphabetical.hidden = NO;
    
    [self.btnPronunciation setTitleColor:[self.view colorWithHexString:@"#B6BDC3" alpha:1] forState:UIControlStateNormal];
    [self.btnAlphabetical setTitleColor:BLACK_COLOR_1F forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.line.frame = CGRectMake(Distance＿M + self.btnPronunciation.frame.size.width/4 + self.btnPronunciation.frame.size.width , self.btnPronunciation.frame.origin.y + 31 ,self.btnPronunciation.frame.size.width/2, LINE_WIDTH);
    }];
}
- (void)getPronunciation{//左
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:@"/pinyin/getPronunciation" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
         if (success) {
             //self.collectionPronunciation.dataArray = [NSArray arrayWithArray:response.data];
             //[self.collectionPronunciation reloadData];
             
             NSArray *newArray = [NSArray arrayWithArray:response.data];
             if ([DataCacheManager hasDataChanged:newArray forClass:[self class]]) {
                  self.collectionPronunciation.dataArrays = [newArray mutableCopy];
                  [self.collectionPronunciation reloadData];
              }
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
- (void)getAlphabetical{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params = [LanguageHelper currentLanguageParams:params];
    [HttpTools postRequest:@"/pinyin/getAlphabetical" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        //NSLog(@"--------[%@]-----[%d],,,,[%@]",response.data,response.code,response.msg);
         if (success) {
             NSArray *newArray = [NSArray arrayWithArray:response.data];
             self.collectionAlphabetical.dataArrays = [NSMutableArray arrayWithArray:newArray];
             [self.collectionAlphabetical reloadData];
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}
#pragma mark - 加载本地缓存

@end
