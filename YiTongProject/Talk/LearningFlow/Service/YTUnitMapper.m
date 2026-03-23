//
//  YTUnitMapper.m
//  YiTongProject
//

#import "YTUnitMapper.h"

@implementation YTUnitMapper

+ (NSArray<YTUnit *> *)mapUnitsFromResponse:(NSArray<NSDictionary *> *)response
                                    sceneId:(NSString *)sceneId
                                    levelId:(YTLevelId)levelId {
    NSMutableArray<YTUnit *> *units = [NSMutableArray array];
    for (NSDictionary *payload in response) {
        if (![payload isKindOfClass:[NSDictionary class]]) continue;

        NSString *unitTypeStr = payload[@"unitType"];
        NSString *unitId = payload[@"unitId"] ?: @"";
        NSInteger stepIndex = [payload[@"stepIndex"] integerValue];

        YTUnit *u = [[YTUnit alloc] init];
        u.sceneId = sceneId;
        u.levelId = levelId;
        u.unitId = unitId;
        u.stepIndex = stepIndex;

        NSDictionary *display = payload[@"display"];
        if (![display isKindOfClass:[NSDictionary class]]) display = @{};

        if ([unitTypeStr isEqualToString:@"pronounce"]) {
            u.unitType = YTUnitTypePronounce;
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

            u.grammarText = display[@"grammarText"];

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
        } else if ([unitTypeStr hasPrefix:@"exercise_"]) {
            if ([unitTypeStr isEqualToString:@"exercise_listen_choose_image"]) {
                u.unitType = YTUnitTypeExerciseListenChooseImage;
            } else if ([unitTypeStr isEqualToString:@"exercise_look_choose_word"]) {
                u.unitType = YTUnitTypeExerciseLookChooseWord;
            } else if ([unitTypeStr isEqualToString:@"exercise_choose_word_fill_blank"]) {
                u.unitType = YTUnitTypeExerciseChooseWordFillBlank;
            } else if ([unitTypeStr isEqualToString:@"exercise_listen_choose_response"]) {
                u.unitType = YTUnitTypeExerciseListenChooseResponse;
            } else if ([unitTypeStr isEqualToString:@"exercise_build_sentence"]) {
                u.unitType = YTUnitTypeExerciseBuildSentence;
            } else if ([unitTypeStr isEqualToString:@"exercise_complete_dialogue"]) {
                u.unitType = YTUnitTypeExerciseCompleteDialogue;
            } else {
                u.unitType = YTUnitTypeExerciseListenChooseImage;
            }

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
        }

        [units addObject:u];
    }

    return units;
}

@end
