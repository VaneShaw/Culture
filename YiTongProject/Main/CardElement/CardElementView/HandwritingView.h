//
//  HandwritingView.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface HandwritingView : UIView

@property (nonatomic, strong) NSString *currentCharacter;
@property (nonatomic, assign) NSInteger writingType;
@property (nonatomic, strong) NSMutableArray *strokesArray; // 存储所有笔画
@property (nonatomic, strong) NSMutableArray *currentStrokePoints; // 当前笔画的点
@property (nonatomic, assign) CFTimeInterval firstTimestamp; // 记录第一个点的时间
@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
- (void)clearDrawing212;

- (void)clearDrawing;
- (NSDictionary *)getWritingData;
//- (void)setContinuousWritingEnabled:(BOOL)enabled;
//- (void)loadCharacterFromImage:(UIImage *)image completion:(void (^)(NSString *character, CGRect bounds))completion;
//重写 数据
- (void)loadWritingData:(NSArray *)strokesArray ;
// 保存和加载
- (void)saveToUserDefaults;
+ (NSDictionary *)loadFromUserDefaults;
@end

NS_ASSUME_NONNULL_END
