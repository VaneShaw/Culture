//
//  ClearCacheViewController.m
//  YiTongProject
//
//  Created by Vincent on 2025/8/8.
//

#import "ClearCacheViewController.h"
#import "PasswordSuccessfulView.h"
@interface ClearCacheViewController ()
@property (nonatomic, strong) UIButton *btnReturn;
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UILabel *lblTitle;
@property (nonatomic, strong) UIButton *btnClear;
@end

@implementation ClearCacheViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    self.navigationItem.hidesBackButton = YES;
    [self addGlobalBackButton];

    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    self.imgView = [[UIImageView alloc]initWithFrame:CGRectMake((SCREEN_WIDTH-140)/2, statusBarH + 16 + 200, 140, 140)];
    self.imgView.image = [UIImage imageNamed:@"clearCache_blue"];
    [self.view addSubview:self.imgView];
    
    UILabel *lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(25, 127 + self.imgView.frame.origin.y, SCREEN_WIDTH - 40, 50)];
    lblTitle.font = [UIFont fontWithName:FONT_NAME_Regular size:16];
    lblTitle.textColor = [self.view colorWithHexString:@"#8F8F8F" alpha:1];
    lblTitle.numberOfLines = 0;
    lblTitle.textAlignment = NSTextAlignmentCenter;//@"\n"
    lblTitle.text = NSLocalizedString(@"Clearing cache frees up space without deleting your data.",@"");
    [self.view addSubview:lblTitle];
    self.lblTitle = lblTitle;
    [self.view addSubview:self.btnClear];
}
- (UIButton *)btnClear {
    if(!_btnClear){
        _btnClear = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnClear.frame = CGRectMake(70, self.imgView.frame.origin.y + self.imgView.frame.size.height + 60, SCREEN_WIDTH - 140, 56);
        _btnClear.layer.cornerRadius = 28;//圆角
        _btnClear.layer.masksToBounds = YES;
        _btnClear.titleLabel.font = [UIFont fontWithName:FONT_NAME_HelveticaBold size:20];
        [_btnClear setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_btnClear setTitle:NSLocalizedString(@"Clear Now",@"立即清理") forState:UIControlStateNormal];
        _btnClear.layer.borderWidth = 1;//边框
        _btnClear.layer.borderColor = [UIColor blackColor].CGColor;
        [_btnClear addTarget:self action:@selector(btnClearAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnClear;
}
- (void)btnClearAction:(UIButton *)sender {
    NSInteger cacheSize = [[SDImageCache sharedImageCache] totalDiskSize];
    //self.cacheLabel.text = [NSString stringWithFormat:@"缓存大小: %.2fMB", cacheSize / 1024.0 / 1024.0];
    NSString *str0 = NSLocalizedString(@"Cache cleared successfully.",@"");
    NSString *str1 = NSLocalizedString(@"freed.",@"");
 
    NSString *title = [NSString stringWithFormat:@"%@ %.2fMB %@",str0, cacheSize / 1024.0 / 1024.0,str1];
    [PasswordSuccessfulView showViewTitle:title buttonArrayTitle:@[] callBack:^(NSInteger index) {
    }];
    //[[SDImageCache sharedImageCache] clearDiskOnCompletion:nil];//清除缓存
    
    // 清空内存缓存
    [[SDImageCache sharedImageCache] clearMemory];

    // 清空磁盘缓存（异步）
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        NSLog(@"✅ 所有 SDWebImage 缓存已清空");
    }];
    
    //[self clearGIFCache];
}
- (void)clearGIFCache {
    // 1. 先停止 GIF 播放，释放文件占用


    // 2. 构造缓存路径
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *gifCacheDir = [cacheDir stringByAppendingPathComponent:@"GIFCache"];

    // 3. 检查文件夹是否存在
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL exists = [fm fileExistsAtPath:gifCacheDir isDirectory:&isDir];

    if (exists && isDir) {
        NSError *error = nil;
        BOOL success = [fm removeItemAtPath:gifCacheDir error:&error];
        if (success) {
            NSLog(@"✅ GIF 缓存已清空: %@", gifCacheDir);
        } else {
            NSLog(@"⚠️ 删除失败: %@", error);
        }
    } else {
        NSLog(@"❎ GIF 缓存目录不存在");
    }

    // 4. 可选：延迟重新创建文件夹，避免下次写入失败
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![fm fileExistsAtPath:gifCacheDir]) {
            [fm createDirectoryAtPath:gifCacheDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
    });
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
