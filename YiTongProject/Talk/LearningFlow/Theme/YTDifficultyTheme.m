//
//  YTDifficultyTheme.m
//  YiTongProject
//

#import "YTDifficultyTheme.h"
#import "HeaderConfig.h"

@implementation YTDifficultyTheme

+ (instancetype)themeForLevel:(YTLevelId)levelId {
    YTDifficultyTheme *t = [[YTDifficultyTheme alloc] init];
    t.levelId = levelId;

    // 主题色 Token（MVP）：
    // - `backgroundColor`：整页背景（区别三难度氛围）
    // - `primaryColor`：主按钮/选中态/进度色（区别三难度识别）
    // - `correctColor/wrongColor`：跨难度统一（形成稳定学习反馈）
    if (levelId == YTLevelIdBeginner) {
        t.backgroundColor = [theAppDelegate.window colorWithHexString:@"#D7EEE6" alpha:1];
        t.primaryColor = [theAppDelegate.window colorWithHexString:@"#12B886" alpha:1];
        t.progressTintColor = t.primaryColor;
        t.chatAnswerBubbleBackgroundColor = [theAppDelegate.window colorWithHexString:@"#E3F5ED" alpha:1];
    } else if (levelId == YTLevelIdIntermediate) {
        t.backgroundColor = [theAppDelegate.window colorWithHexString:@"#DCE7FF" alpha:1];
        t.primaryColor = [theAppDelegate.window colorWithHexString:@"#2F7BF6" alpha:1];
        t.progressTintColor = t.primaryColor;
        t.chatAnswerBubbleBackgroundColor = [theAppDelegate.window colorWithHexString:@"#E9F2FF" alpha:1];
    } else {
        t.backgroundColor = [theAppDelegate.window colorWithHexString:@"#E8E2FF" alpha:1];
        t.primaryColor = [theAppDelegate.window colorWithHexString:@"#7C5CFF" alpha:1];
        t.progressTintColor = t.primaryColor;
        t.chatAnswerBubbleBackgroundColor = [theAppDelegate.window colorWithHexString:@"#E8E4FF" alpha:1];
    }

    // 左侧题干气泡：全难度统一
    t.chatPromptBubbleBackgroundColor = [theAppDelegate.window colorWithHexString:@"#F2F2F2" alpha:1];

    t.correctColor = [theAppDelegate.window colorWithHexString:@"#2AC769" alpha:1];
    t.wrongColor = [theAppDelegate.window colorWithHexString:@"#FF4D4F" alpha:1];
    return t;
}

@end

