//
//  SpeakResultsView.h
//  YiTongProject
//
//  Created by Vincent on 2025/7/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SpeakResultsView : UIView
+ (void)showSpeakResultsView:(UIView *)resultsView data:(NSDictionary *)dicData resultsState:(int)state viewType:(BOOL)isSpeak callBack:(void(^)(NSInteger index))callBack;
@end

NS_ASSUME_NONNULL_END
