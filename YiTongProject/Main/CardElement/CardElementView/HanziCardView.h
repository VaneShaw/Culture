//
//  HanziCardView.h
//  YiTongProject
//
//  Created by ios01 on 2025/10/20.
//

#import <UIKit/UIKit.h>
#import "CardBaseView.h"

NS_ASSUME_NONNULL_BEGIN


@interface HanziCardView : CardBaseView
- (void)btnflipCardActionNo;
- (void)loadGIFWithURLString:(NSString *)urlString;
- (void)updateMeaningViewWithText:(NSDictionary *)formWords;

@end

NS_ASSUME_NONNULL_END
