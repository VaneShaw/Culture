//
//  NSArray+JSON.m
//  YiTongProject
//
//  Created by ios01 on 2025/9/12.
//

#import "NSArray+JSON.h"

@implementation NSArray (JSON)
- (NSString *)toJSONString {
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
@end
