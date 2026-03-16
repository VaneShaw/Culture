//
//  StoryGodsViewController.h
//  YiTongProject
//
//  Created by ios01 on 2026/1/5.
//

#import <UIKit/UIKit.h>
//#import "StoryRoundModel.h"
#import "StoryCoverPageView.h"
#import "StoryRoundPageView.h"
NS_ASSUME_NONNULL_BEGIN

@interface StoryGodsViewController : BaseViewController
@property (strong, nonatomic) NSString *storyId;
@property (nonatomic, assign) int isFairy;//0 成语 1 神话  2封神榜
@property (nonatomic, assign) int modeType;//0  1  2 @[@"backward",@"forward",@"window"][self.modeType];//+前。+后  中
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<StorySectionModel *> *rounds;
@end

NS_ASSUME_NONNULL_END


/*
 - (void)mockData {
     NSMutableArray *arr = [NSMutableArray array];
     for (int i = 0; i < 8; i++) {
         StorySectionModel *m = [StorySectionModel new];
         m.title = [NSString stringWithFormat:@"第 %d 回合", i + 1];
         m.coverImageName = @"story_cover";
         if(i < 2){
             m.coverImageName = @"";
         }
         m.type = StorySectionTypeText;
         NSMutableArray *contents = [NSMutableArray array];
         for (int j = 0; j < 50; j++) {
             StorySectionModel *m = [StorySectionModel new];
             m.type = StorySectionTypeText;
             m.title =  [NSString stringWithFormat:@"第 %d 回合 - 内容 %d", i + 1, j + 1];
             m.model_id = [NSString stringWithFormat:@"%d", i + 1];
             m.textCN = [NSString stringWithFormat:@"%@--%@", @"而是",m.title];
             m.textEN = [NSString stringWithFormat:@"%@", @"english-是对方说了开发说说了分手的楼房是否说啥地方是否收到放水淀粉啥地方"];
             [m setStartTimeCNWithString:@{@"main_start":@"30",@"main_end":@"60"}];
             [m setStartTimeENWithString:@{@"fallback_start":@"30",@"fallback_end":@"60"}];
             [contents addObject:m];
         }
         m.contents = contents;
         [arr addObject:m];
     }
     self.rounds = arr;
 }
 */
//- (void)mockData {
//    NSMutableArray *arr = [NSMutableArray array];
//    for (int i = 0; i < 8; i++) {
//        StorySectionModel *m = [StorySectionModel new];
//        m.title = [NSString stringWithFormat:@"第 %d 回合", i + 1];
//        m.coverImageName = @"story_cover";
//        if(i < 2){
//            //m.coverImageName = @"";
//        }
//        m.coverImageName = @"https://testoss.shiyi-yitong.com/story/fengshen/images/ch1_cover.png";
        
//        m.type = StorySectionTypeText;
//        NSMutableArray *contents = [NSMutableArray array];
//        for (int j = 0; j < 50; j++) {
//            StorySectionModel *m = [StorySectionModel new];
//            m.type = StorySectionTypeText;
//            m.title =  [NSString stringWithFormat:@"第 %d 回合 - 内容 %d", i + 1, j + 1];
//            m.model_id = [NSString stringWithFormat:@"%d", i + 1];
//            m.textCN = [NSString stringWithFormat:@"%@--%@", @"而是",m.title];
//            m.textEN = [NSString stringWithFormat:@"%@", @"english-是对方说了开发说说了分手的楼房是否说啥地方是否收到放水淀粉啥地方"];
//            [m setStartTimeCNWithString:@{@"main_start":@"30",@"main_end":@"60"}];
//            [m setStartTimeENWithString:@{@"fallback_start":@"30",@"fallback_end":@"60"}];
//            [contents addObject:m];
//        }
//        m.contents = contents;
//        [arr addObject:m];
//    }
//    self.rounds = arr;
//}


/*
 //====================================================================
 //跳转到 对应index
 - (void)jumpToRoundxxx:(NSInteger)roundIndex jumpToCover:(BOOL)cover {
     if (roundIndex < 0 || roundIndex >= self.rounds.count) return;
     NSInteger targetPage = 0;
     // 前 N 回合无封面
     if (roundIndex < kRoundsWithoutCover) {
         targetPage = roundIndex; // 每回合一页
     } else {
         // 第三回合开始，每回合两页
         targetPage = kRoundsWithoutCover + (roundIndex - kRoundsWithoutCover) * 2;
         if (!cover) targetPage += 1; // 内容页
     }
     // 滚动到对应页
     CGFloat offsetY = targetPage * self.scrollView.bounds.size.height;
     [self.scrollView setContentOffset:CGPointMake(0, offsetY) animated:NO];

     //✅ 更新当前 myTableView
     [self updateCurrentRoundIndex:roundIndex];
     [self switchAudioForRoundIndex:roundIndex];
 }

 // 获取当前回合
 - (NSInteger)currentRoundIndex111 {
     CGFloat pageHeight = self.scrollView.bounds.size.height;
     CGFloat offsetY = self.scrollView.contentOffset.y;
     NSInteger pageIndex = (NSInteger)round(offsetY / pageHeight);
     if (pageIndex < kRoundsWithoutCover) {
         // 前 N 回合，每页就是一回合
         return pageIndex;
     }
     // 后面回合，每回合两页
     NSInteger roundIndex = kRoundsWithoutCover + (pageIndex - kRoundsWithoutCover) / 2;
     if (roundIndex >= self.rounds.count) {
         roundIndex = self.rounds.count - 1;
     }
     self.currentRoundIndex = roundIndex;
     return roundIndex;
 }
 // 判断当前页是否是封面
 - (BOOL)currentPageIsCover111 {
     CGFloat pageHeight = self.scrollView.bounds.size.height;
     CGFloat offsetY = self.scrollView.contentOffset.y;
     NSInteger pageIndex = (NSInteger)round(offsetY / pageHeight);
     if (pageIndex < kRoundsWithoutCover) {
         return NO; // 前 N 回合都是内容
     }
     NSInteger pagesAfterFirstN = pageIndex - kRoundsWithoutCover;
     return (pagesAfterFirstN % 2 == 0); // 偶数页是封面
 }
 //-----------------------------
 */
