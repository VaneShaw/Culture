//
//  GridCollectionView.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/4.
//

#import <UIKit/UIKit.h>
#import "GridCollectionViewCell.h"
NS_ASSUME_NONNULL_BEGIN

@interface GridCollectionView : UICollectionView
//@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic, strong) NSMutableArray *dataArrays; // 存放字典/模型转字典
@property (nonatomic, copy) NSString *localJSONString;   // 用于缓存对比

@property (nonatomic,copy) void (^selectedTypeIndex)(NSInteger index);//代码块传值
// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame;
// 刷新数据（可选）
- (void)reloadWithData:(NSArray *)data;

@end

NS_ASSUME_NONNULL_END
