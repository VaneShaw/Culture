//
//  LanguageViewController.m
//  YiTongProject
//
//  Created by ios01 on 2025/8/29.
//

#import "LanguageViewController.h"

@interface LanguageViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSDictionary *> *languages;
@property (nonatomic, copy) NSString *currentLang;

@end

@implementation LanguageViewController
- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];//x
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"选择语言",@"x");
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.backgroundColor = [self.view colorWithHexString:@"#F5F9FF" alpha:1];
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] init];
    backBtn.title = @"";
    self.navigationItem.backBarButtonItem = backBtn;
    //self.navigationItem.hidesBackButton = YES;
    
    // 支持的语言（可以自己扩展）
    self.languages = @[
        @{@"code": @"zh-Hans", @"name": @"简体中文"},
        @{@"code": @"en",      @"name": @"English"},
        @{@"code": @"ja",      @"name": @"日本語"},
        @{@"code": @"ko",      @"name": @"한국어"}
    ];
    
    // 当前语言
    self.currentLang = [[NSUserDefaults standardUserDefaults] objectForKey:@"appLanguage"];
    if (!self.currentLang) {
        self.currentLang = @"en"; // 默认英文
    }
    CGFloat statusBarH = [PublicTool getStatusBarHeight];
    CGRect rectNav = self.navigationController.navigationBar.frame;
    CGRect frame =  CGRectMake(0,statusBarH + rectNav.size.height, SCREEN_WIDTH, SCREEN_HEIGHT - statusBarH - rectNav.size.height );
    // tableView
    self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self addGlobalBackButtonColor:[UIColor orangeColor] headerTitleDic:@{}];
    
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.languages.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"langCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    NSDictionary *langInfo = self.languages[indexPath.row];
    cell.textLabel.text = langInfo[@"name"];
    
    // 默认选中当前语言
    if ([self.currentLang isEqualToString:langInfo[@"code"]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *langInfo = self.languages[indexPath.row];
    NSString *selectedLang = langInfo[@"code"];
    
    if (![self.currentLang isEqualToString:selectedLang]) {
        // 保存新语言
        [[NSUserDefaults standardUserDefaults] setObject:selectedLang forKey:@"appLanguage"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        self.currentLang = selectedLang;
        // 刷新 UI
        [self.tableView reloadData];
        
        [LanguageHelper setLanguage:selectedLang];
        // 通知 App 语言切换
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"LanguageChanged" object:nil];
    }
    
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
