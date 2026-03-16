//
//  MainViewController.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MainViewController : BaseViewController

@end

NS_ASSUME_NONNULL_END
/*
 //para21.imageContentMode = UIViewContentModeScaleAspectFill; // 填充
 // imageParagraph.imageContentMode = UIViewContentModeScaleAspectFit; // 适应
 // imageParagraph.imageContentMode = UIViewContentModeCenter; // 居中不缩放
段落2 - 图文重叠（文字在图片上方）
     StoryParagraph *para2 = [[StoryParagraph alloc] init];
     para2.chineseText = @"经过一万八千年，盘古醒来，持巨斧劈开混沌。";
     para2.englishText = @"After eighteen thousand years, Pangu woke up, took a giant axe, and split the chaos.";
     para2.startTime = 8.0;
     para2.endTime = 16.0;
     para2.image = [UIImage imageNamed:imgs[0]];
     para2.layoutStyle = ContentLayoutStyleImageTextOverlap;
     para2.imagePosition = ImagePositionTop;
     para2.overlapOffset = 0; // 文字向下偏移100点
     para2.textInsets = UIEdgeInsetsMake(20, 30, 20, 30);
     [paragraphs addObject:para2];
     
     // 段落3 - 重点段落（图文混合）
     StoryParagraph *para3 = [[StoryParagraph alloc] init];
     para3.chineseText = @"盘古立于天地之间，\n日长一丈。天日高一丈，\n地日厚一丈。又过一万八千年，\n天极高，地极厚，盘古极长。";
     para3.englishText = @"Pangu stood between the heaven and earth,\ngrowing one zhang each day.\nThe sky rose one zhang higher each day,\nthe earth grew one zhang thicker each day.\nAfter another eighteen thousand years,\nthe sky was extremely high,\nthe earth was extremely thick,\nand Pangu was extremely tall.";
     para3.startTime = 16.0;
     para3.endTime = 30.0;
     para3.image = [UIImage imageNamed:imgs[1]];
     para3.layoutStyle = ContentLayoutStyleTextOverImage;
     para3.imageHeightRatio = 1.0; // 图片占60%高度
     para3.textInsets = UIEdgeInsetsMake(30, 40, 30, 40);
     [paragraphs addObject:para3];
     
     // 段落4 - 图片在文字右侧
     StoryParagraph *para4 = [[StoryParagraph alloc] init];
     para4.chineseText = @"盘古死后，气息化为风云，声音化为雷霆，左眼为日，右眼为月，四肢五体为四极五岳，血液为江河，筋脉为地理，肌肉为田土...";
     para4.englishText = @"After Pangu died, his breath became wind and clouds, his voice became thunder, his left eye became the sun, his right eye became the moon, his limbs and trunk became the four poles and five mountains, his blood became rivers, his veins became the earth's veins, and his muscles became the fields...";
     para4.startTime = 30.0;
     para4.endTime = 45.0;
     para4.image = [UIImage imageNamed:imgs[2]];
     para4.layoutStyle = ContentLayoutStyleImageBesideText;
     para4.imagePosition = ImagePositionRight;
     para4.imageInsets = UIEdgeInsetsMake(10, 10, 10, 20);
     [paragraphs addObject:para4];*/
/*
 - (void)showPanGuStory {
     // 创建故事段落
     //[self getStoryDetail];
     //[self showFairyTales];
     //[self getMythStory];
     [self getMythStoryDetail:@"1"];
     return;
     NSArray *imgs = @[@"myths_0",@"myths_1",@"myths_2",@"myths_3",@"myths_4",@"myths_5",@"myths_6",@"",@"",@"",@"",@"",@"",@""];
     NSMutableArray *paragraphs = [NSMutableArray array];
        //case ContentLayoutStyleImageOnly: {
        //文字在图片上case ContentLayoutStyleTextOverImage: {
        //图文重叠  case ContentLayoutStyleImageTextOverlap: {

         // 段落1 - 纯文本
         StoryParagraph *para10 = [[StoryParagraph alloc] init];
         para10.chineseText = @"女娲的诞生";
         para10.englishText = @"In the distant ancient times, the universe was chaotic like an egg, and Pangu was nurtured within it.";
         para10.startTime = 0.0;
         para10.endTime = 8.0;
        para10.textInsets = UIEdgeInsetsMake(15, 15, 15, 15); // 默认内边距
         para10.layoutStyle = ContentLayoutStyleTitleOnly;
         [paragraphs addObject:para10];
     //==========================================
     // 1自定义位置
     //==========================================
     StoryParagraph *para2 = [[StoryParagraph alloc] init];
      //para2.image = [UIImage imageNamed:imgs[6]];
      para2.layoutStyle = ContentLayoutStyleImageOnly;
      para2.autoFitWidth = NO; // 自动宽度
      //{top, left, bottom, right}   (0, 100, 0, 0); // 左边距100
      para2.imageInsets = UIEdgeInsetsMake(0, 100, 0, 100); // 左右边距
      para2.negativeYOffset = 0; // 向上延伸30点
      para2.startTime = 8.0;
      para2.endTime = 16.0;
      [paragraphs addObject:para2];
        //3. 创建两端对齐的长段落//xxxxxxxxxxxxxxxxxxxx
        StoryParagraph *para12 = [[StoryParagraph alloc] init];
        para12.chineseText = @"盘古开天辟地后，身躯化山川，魂灵成灵气。 昆仑之巅，千年汇聚为七彩云霞，纳日月精华万载。  春雷乍响，云霞绽光， 叶脉轻纱的女神临世。 足落生雪莲，袖拂化祥云。 天地灵气来朝，草木低伏，万灵恭迎。 东方虹桥贯苍穹，创世之神降人间。 她垂眸苍生，守护之念，自此而生。";
     para12.englishText = @"In the distant ancient times, the universe was chaotic like an egg, and Pangu was nurtured within it.";
     para12.startTime = 16.0;
     para12.endTime = 28.0;
     para12.layoutStyle = ContentLayoutStyleTextOnly;
     
     //para12.font = [UIFont fontWithName:@"STKaiti" size:20];
     para12.textAlignment = TextAlignmentJustified;
     //para12.textInsets = UIEdgeInsetsMake(20, 25, 20, 25);
     para12.lineSpacing = 8.0;
     para12.paragraphSpacing = 12.0;
     [paragraphs addObject:para12];
     //==========================================
     //2 自动宽度平铺图片
     //==========================================
     StoryParagraph *para3 = [[StoryParagraph alloc] init];
     //para3.image = [UIImage imageNamed:imgs[0]];
     para3.layoutStyle = ContentLayoutStyleImageOnly;
     para3.autoFitWidth = YES; // 自定义尺寸
     para3.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0); // 左边距50 (0, 50, 0, 0)
     para3.negativeYOffset = 0; // 无延伸
     para3.startTime = 16.0;
     para3.endTime = 24.0;
     [paragraphs addObject:para3];

     StoryParagraph *para14 = [[StoryParagraph alloc] init];
     para14.chineseText = @"女娲造人";
     para14.englishText = @"In the distant ancient times, the universe was chaotic like an egg, and Pangu was nurtured within it.";
     para14.textInsets = UIEdgeInsetsMake(15, 15, 15, 15); // 默认内边距
     para14.layoutStyle = ContentLayoutStyleTitleOnly;
     para14.startTime = 28.0;
     para14.endTime = 38.0;
     [paragraphs addObject:para14];

    // 段落2 - 图文重叠（文字在图片上方）
     StoryParagraph *para15 = [[StoryParagraph alloc] init];
     //para15.image = [UIImage imageNamed:imgs[6]];
     para15.layoutStyle = ContentLayoutStyleImageOnly;
     para15.autoFitWidth = NO; // 自定义尺寸
     para15.imageInsets = UIEdgeInsetsMake(0, 100, 0, 100); // 左边距100
     [paragraphs addObject:para15];

     //2. 创建居中对齐标题----------------xxxxxxxxx
     StoryParagraph *para16 = [[StoryParagraph alloc] init];
     para16.englishText = @"盘古开天辟地后，身躯化山川，魂灵成灵气。 昆仑之巅，千年汇聚为七彩云霞，纳日月精华万载。  春雷乍响，云霞绽光， 叶脉轻纱的女神临世。 足落生雪莲，袖拂化祥云。 天地灵气来朝，草木低伏，万灵恭迎。 东方虹桥贯苍穹，创世之神降人间。 她垂眸苍生，守护之念，自此而生。";
     para16.chineseText = @"In the distant ancient times, the universe was chaotic like an egg, and Pangu was nurtured within it.";
     para16.startTime = 0.0;
     para16.endTime = 8.0;
     para16.layoutStyle = ContentLayoutStyleTextOnly;
     para16.textAlignment = TextAlignmentCenter;
     //para16.textInsets = UIEdgeInsetsMake(30, 20, 30, 20);
     para16.lineSpacing = 0;
     [paragraphs addObject:para16];
     //==========================================
     //3. 向上延伸图片（部分展示在上一行底部）
     //==========================================
     StoryParagraph *para17 = [[StoryParagraph alloc] init];
     //para17.image = [UIImage imageNamed:imgs[1]];
     //para17.imagePosition = ImagePositionTop;
     para17.layoutStyle = ContentLayoutStyleImageOnly;
     para17.autoFitWidth = YES; // 自动宽度
     para17.negativeYOffset = 20; // 向上延伸80点
     [paragraphs addObject:para17];

     StoryParagraph *para18 = [[StoryParagraph alloc] init];
     para18.chineseText = @"神怒天崩·不周山的倾覆";
     para18.englishText = @"In the distant ancient times, the universe was chaotic like an egg, and Pangu was nurtured within it.";

     para18.layoutStyle = ContentLayoutStyleTitleOnly;
     [paragraphs addObject:para18];

     // 段落2 - 图文重叠（文字在图片上方）
     StoryParagraph *para19 = [[StoryParagraph alloc] init];
     //para19.image = [UIImage imageNamed:imgs[2]];
     para19.autoFitWidth = YES; // 自动宽度
     para19.layoutStyle = ContentLayoutStyleImageOnly;
     para19.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0); // 左右边距
     para19.negativeYOffset = 0; // 无延伸
     //para21.textInsets = UIEdgeInsetsMake(20, 30, 20, 30);
     [paragraphs addObject:para19];
     
     //1. 创建左对齐段落-------xxxxxxxxxxxx
     StoryParagraph *para20 = [[StoryParagraph alloc] init];
     para20.chineseText = @"人类繁衍后，水神共工不满女娲统治，联手魔族叛乱。 火神祝融应命平乱，二神大战引发天地动荡。   共工惨败，怒撞不周山，  擎天巨柱轰然折断，天空倾斜，日月星辰随之西坠；
    大地塌陷，江河奔腾，洪水肆虐，  天火自裂缝倾泻，吞噬万物，猛兽横行。   女娲见苍生苦难，决意拯救苍生。";
     para20.englishText = @"In the distant ancient times, the universe was chaotic like an egg, and Pangu was nurtured within it.";
     para20.startTime = 0.0;
     para20.endTime = 8.0;
     para20.layoutStyle = ContentLayoutStyleTextOnly;
     para20.textAlignment = TextAlignmentLeft;
     //para20.textInsets = UIEdgeInsetsMake(15, 20, 15, 20);
     [paragraphs addObject:para20];
         
     // 段落2 - 图文重叠（文字在图片上方）
     StoryParagraph *para21 = [[StoryParagraph alloc] init];
     //para21.image = [UIImage imageNamed:imgs[3]];
     para21.layoutStyle = ContentLayoutStyleImageOnly;
     para21.autoFitWidth = YES; // 自动宽度
     para21.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0); // 左右边距
     para21.negativeYOffset = 0; // 无延伸
     [paragraphs addObject:para21];
     
     // 创建视图控制器
     NewMythStoryViewController *vc = [[NewMythStoryViewController alloc] init];
     vc.paragraphs = paragraphs;
     vc.audioURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"myth_story_0" ofType:@"mp3"]];
     vc.hidesBottomBarWhenPushed = YES;
     [self.navigationController pushViewController:vc animated:YES];
 }
 */

/*
- (void)getMythStory{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [HttpTools postRequest:@"/story/getMythStory" parames:params success:^(BOOL success, BaseDataModel * _Nonnull response) {
        //[self getBanner];
         if (success) {
             NSArray *dataArray = [NSArray arrayWithArray:response.data];
             if(dataArray.count > 0){
                 //NSString *strId = [NSString stringWithFormat:@"%@",dataArray[0][@"id"]];
                 //[self getMythStoryDetail:strId];
             }
        } else {
            [MBProgressHUD showLabel:response.msg];
        }
    } failure:^(NSError * _Nonnull error) {
    }];
}*/


/*
 - (void)showNoNetworkAlert {
     UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"网络不可用"
                                                                    message:@"请检查您的网络连接后重试"
                                                             preferredStyle:UIAlertControllerStyleAlert];
     UIAlertAction *retryAction = [UIAlertAction actionWithTitle:@"重试"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
         [self performNetworkAction:nil];
     }];
     UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"网络设置"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                            options:@{}
                                  completionHandler:nil];
     }];
     UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil];
     [alert addAction:retryAction];
     [alert addAction:settingsAction];
     [alert addAction:cancelAction];
     [self presentViewController:alert animated:YES completion:nil];
 }

 
 */
