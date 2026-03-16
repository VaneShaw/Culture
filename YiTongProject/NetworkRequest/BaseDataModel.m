//
//  BaseDataModel.m
//  YiTongProject
//
//  Created by Vincent on 2025/6/25.
//

#import "BaseDataModel.h"

@implementation BaseDataModel
- (void)setCode:(NSUInteger)code{
    
    _code=code;
    _successs = code == 0 ? YES : NO;
}

@end
