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
@property (nonatomic, assign) NSInteger completedUnits;
@property (nonatomic, assign) NSInteger totalUnits;
@property (nonatomic, copy, nullable) NSString *levelStatus;

+ (NSArray<YTTalkLevelItem *> *)itemsByParsingAPIData:(id)data;

@end

NS_ASSUME_NONNULL_END
