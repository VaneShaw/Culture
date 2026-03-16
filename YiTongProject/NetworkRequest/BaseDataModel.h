//
//  BaseDataModel.h
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseDataModel : NSObject
// 错误码
@property (nonatomic, copy) NSString *time;
@property (nonatomic, assign) NSUInteger code;
@property (nonatomic, assign) NSUInteger count;
// 提示信息
@property (nonatomic, copy) NSString *msg;

// 返回数据
@property (nonatomic, strong) id data;
// 判断是否成功
@property (nonatomic, assign,getter=isSuccess) BOOL successs;
@end

NS_ASSUME_NONNULL_END
