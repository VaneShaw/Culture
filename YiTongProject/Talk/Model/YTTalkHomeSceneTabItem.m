//
//  YTTalkHomeSceneTabItem.m
//  YiTongProject
//

#import "YTTalkHomeSceneTabItem.h"

@implementation YTTalkHomeSceneTabItem

+ (instancetype)itemWithTypeIdentifier:(NSString *)typeIdentifier {
    YTTalkHomeSceneTabItem *item = [[YTTalkHomeSceneTabItem alloc] init];
    item.typeIdentifier = [typeIdentifier stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    return item;
}

+ (instancetype)defaultAllTabItem {
    YTTalkHomeSceneTabItem *item = [[YTTalkHomeSceneTabItem alloc] init];
    item.typeIdentifier = @"all";
    item.overrideDisplayTitle = NSLocalizedString(@"Talk_Home_Tab_AllScenes", @"");
    return item;
}

- (NSString *)displayTitle {
    if (self.overrideDisplayTitle.length > 0) {
        return self.overrideDisplayTitle;
    }
    return self.typeIdentifier.length > 0 ? self.typeIdentifier : @"all";
}

@end
