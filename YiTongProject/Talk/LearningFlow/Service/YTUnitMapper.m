//
//  YTUnitMapper.m
//  YiTongProject
//

#import "YTUnitMapper.h"

static NSString * _Nullable YTStringOrNil(id obj) {
    return [obj isKindOfClass:[NSString class]] ? (NSString *)obj : nil;
}

/// 过渡/完成页：`display.title` / `display.subtitle` 约定为 string；若为历史 object（zh/en/pinyin）则合并为一条展示文案
static void YTMapPlainTitleAndSubtitle(YTUnit *u, NSDictionary *display, BOOL isTransition) {
    id titleObj = display[@"title"];
    if ([titleObj isKindOfClass:[NSString class]]) {
        u.titleCN = (NSString *)titleObj;
        u.titleEN = nil;
        u.titlePinyin = nil;
    } else if ([titleObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *t = (NSDictionary *)titleObj;
        NSString *plain = YTStringOrNil(t[@"zh"]) ?: YTStringOrNil(t[@"en"]) ?: YTStringOrNil(t[@"pinyin"]);
        u.titleCN = plain;
        u.titleEN = nil;
        u.titlePinyin = nil;
    }
    id subObj = display[@"subtitle"];
    NSString *subPlain = nil;
    if ([subObj isKindOfClass:[NSString class]]) {
        subPlain = (NSString *)subObj;
    } else if ([subObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *s = (NSDictionary *)subObj;
        subPlain = YTStringOrNil(s[@"zh"]) ?: YTStringOrNil(s[@"en"]) ?: YTStringOrNil(s[@"pinyin"]);
    }
    if (isTransition) {
        u.transitionSubtitle = subPlain;
    } else {
        u.completionSubtitle = subPlain;
    }
}

@implementation YTUnitMapper

+ (NSArray<YTUnit *> *)mapUnitsFromResponse:(NSArray<NSDictionary *> *)response
                                    sceneId:(NSString *)sceneId
                                    levelId:(YTLevelId)levelId {
    NSMutableArray<YTUnit *> *units = [NSMutableArray array];
    for (NSInteger i = 0; i < response.count; i++) {
        id payloadObj = response[i];
        if (![payloadObj isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *payload = (NSDictionary *)payloadObj;

        id unitTypeVal = payload[@"unitType"];
        NSString *unitId = payload[@"unitId"] ?: @"";
        // stepIndex 不再依赖接口返回，统一按数组顺序生成
        NSInteger stepIndex = i;

        YTUnit *u = [[YTUnit alloc] init];
        u.sceneId = sceneId;
        u.levelId = levelId;
        u.unitId = unitId;
        u.stepIndex = stepIndex;

        NSDictionary *display = payload[@"display"];
        if (![display isKindOfClass:[NSDictionary class]]) display = @{};

        // unitType 协议：统一使用 int（与 iOS YTUnitType 数值一致）
        if (![unitTypeVal isKindOfClass:[NSNumber class]]) {
            // 后端契约要求 unitType 一定是数字；如果不是就跳过该 unit
            continue;
        }
        NSInteger unitTypeInt = [unitTypeVal integerValue];
        if (unitTypeInt < (NSInteger)YTUnitTypePronounce || unitTypeInt > (NSInteger)YTUnitTypeLevelCompletion) {
            continue;
        }
        u.unitType = (YTUnitType)unitTypeInt;

        if (u.unitType == YTUnitTypePronounce) {
            NSDictionary *title = display[@"title"] ?: @{};
            if ([title isKindOfClass:[NSDictionary class]]) {
                u.titleCN = title[@"zh"];
                u.titlePinyin = title[@"pinyin"];
                u.titleEN = title[@"en"];
            }
            NSDictionary *image = display[@"image"] ?: @{};
            if ([image isKindOfClass:[NSDictionary class]]) {
                u.imageName = image[@"name"];
                u.imageURLString = image[@"url"];
            }
            id media = display[@"media"];
            if ([media isKindOfClass:[NSArray class]]) {
                u.mediaItems = (NSArray *)media;
            }
            NSDictionary *audio = display[@"audio"] ?: @{};
            if ([audio isKindOfClass:[NSDictionary class]]) {
                u.audioURLString = audio[@"referenceUrl"];
            }
            NSArray *highlights = display[@"highlights"];
            if ([highlights isKindOfClass:[NSArray class]]) {
                NSMutableArray<NSString *> *texts = [NSMutableArray array];
                for (NSDictionary *h in highlights) {
                    NSString *t = [h isKindOfClass:[NSDictionary class]] ? h[@"text"] : nil;
                    if (t.length) [texts addObject:t];
                }
                u.highlightTexts = texts;
            }

            NSDictionary *grammarPage = display[@"grammarPage"] ?: @{};
            if ([grammarPage isKindOfClass:[NSDictionary class]]) {
                u.grammarPageNavTitle = grammarPage[@"navTitle"];
                u.grammarPageDescription = grammarPage[@"description"];
                u.grammarPagePromptToken = grammarPage[@"promptToken"];
                u.grammarPagePromptPinyin = grammarPage[@"promptPinyin"];
                u.grammarPagePromptText = grammarPage[@"promptText"];
                u.grammarPageFormulaText = grammarPage[@"formulaText"];
                u.grammarPageFormulaHighlightText = grammarPage[@"formulaHighlightText"];
                u.grammarPageExampleLabel = grammarPage[@"exampleLabel"];
                u.grammarPageArrowText = grammarPage[@"arrowText"];
                u.grammarPageExamples = grammarPage[@"examples"];
            }
        } else if (u.unitType >= YTUnitTypeExerciseListenChooseImage &&
                   u.unitType <= YTUnitTypeExerciseCompleteDialogue) {
            NSDictionary *title = display[@"title"] ?: @{};
            if ([title isKindOfClass:[NSDictionary class]]) {
                u.titleCN = title[@"zh"];
                u.titlePinyin = title[@"pinyin"];
                u.titleEN = title[@"en"];
            }

            NSDictionary *image = display[@"image"] ?: @{};
            if ([image isKindOfClass:[NSDictionary class]]) {
                u.imageName = image[@"name"];
                u.imageURLString = image[@"url"];
            }

            NSArray *options = display[@"options"];
            if ([options isKindOfClass:[NSArray class]]) {
                u.options = options;
            }

            NSDictionary *answerTpl = display[@"answerTemplate"] ?: @{};
            if ([answerTpl isKindOfClass:[NSDictionary class]]) {
                u.answerTemplateCN = answerTpl[@"zh"];
            }

            NSString *correctSentenceText = [display[@"correctSentenceText"] isKindOfClass:[NSString class]] ? display[@"correctSentenceText"] : nil;
            if (correctSentenceText.length > 0) {
                u.correctSentenceText = correctSentenceText;
            }

            NSDictionary *evaluation = payload[@"evaluation"] ?: @{};
            NSDictionary *rule = evaluation[@"rule"] ?: @{};
            if ([rule isKindOfClass:[NSDictionary class]]) {
                u.correctOptionId = rule[@"correctOptionId"];
            }

            NSDictionary *audio = display[@"audio"] ?: @{};
            if ([audio isKindOfClass:[NSDictionary class]]) {
                u.audioURLString = audio[@"referenceUrl"];
            }
        } else if (u.unitType == YTUnitTypePracticeTransition) {
            YTMapPlainTitleAndSubtitle(u, display, YES);
            NSArray *secs = display[@"sections"];
            if ([secs isKindOfClass:[NSArray class]]) {
                NSMutableArray<NSDictionary *> *out = [NSMutableArray array];
                for (id item in secs) {
                    if (![item isKindOfClass:[NSDictionary class]]) continue;
                    NSDictionary *d = (NSDictionary *)item;
                    NSString *cap = d[@"caption"] ?: d[@"label"];
                    NSString *body = d[@"body"];
                    if (cap.length || body.length) {
                        [out addObject:@{ @"caption": cap ?: @"", @"body": body ?: @"" }];
                    }
                }
                if (out.count) u.transitionSections = [out copy];
            }
        } else if (u.unitType == YTUnitTypeLevelCompletion) {
            YTMapPlainTitleAndSubtitle(u, display, NO);
            id scoreObj = display[@"scoreText"];
            if ([scoreObj isKindOfClass:[NSString class]]) {
                u.completionScoreText = (NSString *)scoreObj;
            }
        }

        NSDictionary *progress = payload[@"progress"];
        if ([progress isKindOfClass:[NSDictionary class]]) {
            id ac = progress[@"answeredCorrect"];
            if ([ac isKindOfClass:[NSNumber class]]) {
                u.answeredCorrectFromServer = [ac boolValue];
            }
            id ap = progress[@"answerPayload"];
            if ([ap isKindOfClass:[NSDictionary class]] && [(NSDictionary *)ap count] > 0) {
                u.serverAnswerPayload = [ap copy];
            }
        }

        [units addObject:u];
    }

    return units;
}

@end
