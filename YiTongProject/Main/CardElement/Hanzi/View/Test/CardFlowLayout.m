//
//  CardFlowLayout.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/22.
//

#import "CardFlowLayout.h"


@implementation CardFlowLayout
/*- (instancetype)init {
    if (self = [super init]) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        // 这个值控制主图和侧边露出卡片之间的间距
              // 注意：由于我们在 itemSize 计算里已经减去了左右露出宽度和间距，
              // 所以这里需要用一个经验值来“抵消”系统默认加的间距
              // -17 是测试出来的经验值，保证左右露出的区域刚好贴合屏幕
        CGFloat desiredSpacing = 12; // 想要的实际视觉间距
        self.minimumLineSpacing = -17 + desiredSpacing;
    }
    return self;
}*/

- (instancetype)init {
    if (self = [super init]) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.sideVisibleWidth = 27 + 12 ;  // 左右露出的宽度  27为待展示图的宽  这个值有三个
        self.spacing = 12;
        self.mainHeight = 438;
        self.sideShrink = 70;
    }
    return self;
}

// 计算 itemSize 并设置 contentInset
- (void)prepareLayout {
    [super prepareLayout];
    
    CGFloat screenW = self.collectionView.bounds.size.width;
    CGFloat itemWidth = screenW - 2 * self.sideVisibleWidth; // 主图宽度
    self.itemSize = CGSizeMake(itemWidth, self.mainHeight);
    
    // 经验值，抵消系统多加的间距
    self.minimumLineSpacing = -17 + self.spacing;
    
    // contentInset 让第一张和最后一张也能居中
    CGFloat inset = (screenW - itemWidth) / 2.0;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, inset, 0, inset);
    
}

// 滑动过程中刷新布局
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

// 布局每个 cell
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attributesArray = [[super layoutAttributesForElementsInRect:rect] copy];
    CGFloat collectionViewCenterX = self.collectionView.contentOffset.x + self.collectionView.bounds.size.width / 2.0;
    
    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
        CGFloat distance = fabs(attributes.center.x - collectionViewCenterX);
        CGFloat maxDistance = attributes.bounds.size.width + self.minimumLineSpacing;
        CGFloat ratio = MIN(distance / maxDistance, 1.0);
        
        CGFloat sideHeight = self.mainHeight - self.sideShrink; // 侧图高度
        CGFloat height = sideHeight + (self.mainHeight - sideHeight) * (1 - ratio);
        
        CGRect frame = attributes.frame;
        frame.size.height = height;
        frame.origin.y = (self.collectionView.bounds.size.height - height) / 2.0;
        attributes.frame = frame;
        
        // 缩放效果，防止侧边图太突兀
        CGFloat scale = 0.9 + (1 - ratio) * 0.1;
        attributes.transform = CGAffineTransformMakeScale(scale, scale);
        // 保证中间卡片在上层
        attributes.zIndex = (NSInteger)(1000 - distance);
    }
    return attributesArray;
}

// 滑动结束时锁定中间主图
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
                               withScrollingVelocity:(CGPoint)velocity {
    CGFloat collectionViewCenterX = proposedContentOffset.x + self.collectionView.bounds.size.width / 2.0;
    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    
    NSArray *attributesArray = [super layoutAttributesForElementsInRect:targetRect];
    CGFloat minOffset = CGFLOAT_MAX;
    UICollectionViewLayoutAttributes *closestAttr = nil;
    
    for (UICollectionViewLayoutAttributes *attributes in attributesArray) {
        CGFloat distance = attributes.center.x - collectionViewCenterX;
        if (fabs(distance) < fabs(minOffset)) {
            minOffset = distance;
            closestAttr = attributes;
        }
    }
    
    // 如果滑动速度很小或微小滑动，直接对齐到最近主图，防止晃动
    CGFloat velocityThreshold = 0.2;
    if (fabs(velocity.x) < velocityThreshold) {
        return CGPointMake(closestAttr.center.x - self.collectionView.bounds.size.width / 2.0, proposedContentOffset.y);
    }
    
    return CGPointMake(proposedContentOffset.x + minOffset, proposedContentOffset.y);
}

@end
