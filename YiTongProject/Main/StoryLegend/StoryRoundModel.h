//
//  StoryRoundModel.h
//  YiTongProject
//
//  Created by ios01 on 2026/1/5.
//

#import <Foundation/Foundation.h>

@interface StoryRoundModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *coverImageName;
@property (nonatomic, strong) NSArray<NSString *> *contents;

@end
