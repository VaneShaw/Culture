//
//  YTTalkLevelItem.h
//  YiTongProject
//
//  /talk/level → data[] 单条等级
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YTTalkLevelItem : NSObject

@property (nonatomic, assign) NSInteger levelRecordId;
@property (nonatomic, assign) NSInteger level;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) NSInteger unlockThreshold;
@property (nonatomic, assign) BOOL isUnlocked;
@property (nonatomic, assign) NSInteger progressPercent;
/// 与话题页顶部三枚徽章对应：`1` 显示已获得勋章，`0` 为未获得（与 `level` 1/2/3 对应初/中/高）
@property (nonatomic, assign) BOOL isMedal;
@property (nonatomic, assign) NSInteger completedUnits;
@property (nonatomic, assign) NSInteger totalUnits;
@property (nonatomic, copy, nullable) NSString *levelStatus;

+ (NSArray<YTTalkLevelItem *> *)itemsByParsingAPIData:(id)data;

@end

NS_ASSUME_NONNULL_END
