//
//  KeychainUUID.h
//  YiTongProject
//
//  Created by ios01 on 2026/1/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeychainUUID : NSObject
+ (NSString *)getUUID;
+ (BOOL)isEmptyString:(NSString *)str;
@end

NS_ASSUME_NONNULL_END
