//
//  CardFlowLayout.h
//  YiTongProject
//
//  Created by ios01 on 2025/9/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CardFlowLayout : UICollectionViewFlowLayout
@property (nonatomic, assign) CGFloat sideVisibleWidth; // 左右侧图在屏幕中可见宽度，默认27
@property (nonatomic, assign) CGFloat spacing;          // 主图和侧图间距，默认12
@property (nonatomic, assign) CGFloat mainHeight;       // 主图高度，默认438
@property (nonatomic, assign) CGFloat sideShrink;       // 侧图比主图矮的高度，默认70

@end

NS_ASSUME_NONNULL_END
/*
 为什么是 -17 + 12
 -17 是经验值，用来抵消我们在 itemSize 中减去的露出宽度和间距，否则左右卡片会留空。
 +12 是你希望视觉上的间距（中间主图和侧边卡片之间实际看起来的距离）。
 注意事项
 这个经验值绑定了你当前的 itemSize 和露出宽度，如果以后改了主图宽或左右露出宽，可能需要重新调整。
 对滚动、性能没有影响，只是视觉对齐的技巧。
 */
