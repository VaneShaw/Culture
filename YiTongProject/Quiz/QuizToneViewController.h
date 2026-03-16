//
//  QuizToneViewController.h
//  YiTongProject
//
//  Created by ios01 on 2025/8/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QuizToneViewController : BaseViewController
@property (strong, nonatomic) NSString *practice_id;
@end
NS_ASSUME_NONNULL_END
//..1 自动点击
/*if(![KUSER_DEFAULT boolForKey:@"text_001_0_"]){
    for (int i = 0; i < self.dataArray.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6*i * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
  
            UIButton *button = (UIButton *)[self.headerView viewWithTag:Tag_Question + i];
            [self buttonTapped:button];
            UIButton *button2 = (UIButton *)[self.headerView viewWithTag:Tag_Answer + i];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               [self buttonTapped:button2];
            });
        });
    }
}*/
/*- (void)calculateNonOverlappingPositions{
    // 清除旧位置
    [_targetPositions removeAllObjects];
    // 创建位置数组
    NSMutableArray *positions = [NSMutableArray array];
    //int randomNumber = rand() % 10;
    // 计算安全区域（距离屏幕边缘至少30pt）
    _screenSize = CGSizeMake(390, 450);
    CGFloat marginX = 30 + 30;
    CGFloat marginY = 30 + 30;
    CGRect safeArea = CGRectMake(marginX, marginY + 30,
                                _screenSize.width - 2*marginX,
                                _screenSize.height - 2*marginY);
    CGFloat midX = _screenSize.width / 2;
    // 生成随机位置（确保不重叠但更接近）

    for (int i = 0; i < _buttons.count; i++) {
        NSLog(@"页面开始启动---------ff------i=[%d]",i);
        UIButton *button = _buttons[i];
        CGPoint newPosition;
        BOOL positionValid;
        int attempts = 0;
        do {
            positionValid = YES;
            attempts++;
            // 在安全区域内随机生成位置
            //...1 原始位置
            if(button.tag < Tag_Answer){
                marginX = 80;//距离左边距至少
                safeArea = CGRectMake(marginX, marginY + 30,
                                      midX-marginX,_screenSize.height - 2*marginY);
                newPosition = CGPointMake(
                    safeArea.origin.x + arc4random_uniform(safeArea.size.width),
                    safeArea.origin.y + arc4random_uniform(safeArea.size.height)
                );
                
            } else {
                safeArea = CGRectMake(midX, marginY + 30,
                                      midX-marginX ,_screenSize.height - 2*marginY);
                
                newPosition = CGPointMake(
                    safeArea.origin.x + arc4random_uniform(safeArea.size.width),
                    safeArea.origin.y + arc4random_uniform(safeArea.size.height)
                );
            }
            //NSLog(@"页面开始启动-----[%d]----ff------22",attempts);
            // 检查是否与其他位置重叠
            for (NSValue *positionValue in positions) {
                CGPoint existingPosition = [positionValue CGPointValue];
                CGFloat distance = sqrt(pow(newPosition.x - existingPosition.x, 2) +
                                     pow(newPosition.y - existingPosition.y, 2));
                
                // 最小间距为按钮直径+5（更接近）
                if (distance < self.diameterRound+2) { // 88 + 5
                    positionValid = NO;
                    break;
                }
            }
            //NSLog(@"页面开始启动----[%d]-----ff------33",attempts);
            // 如果尝试100次仍然找不到位置，扩大安全区域
            if (attempts > 100) {
                safeArea = CGRectInset(safeArea, -5, -5);
                attempts = 0;
            }
        } while (!positionValid);
        [positions addObject:[NSValue valueWithCGPoint:newPosition]];
    }
    // 应用位置
    for (int i = 0; i < self.buttons.count; i++) {
        self.buttons[i].center = [positions[i] CGPointValue];
        [self.targetPositions addObject:positions[i]];
    }
}*/
