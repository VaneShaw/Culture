//
//  YTUnitMapper.m
//  YiTongProject
//

#import "YTUnitMapper.h"
#import "NSDictionary+YTSafe.h"

static NSString * _Nullable YTStringOrNil(id obj) {
    if ([obj isKindOfClass:[NSString class]]) {
        return (NSString *)obj;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@", obj];
    }
    return nil;
}

static NSInteger YTIntegerFromObject(id obj, NSInteger defaultValue) {
    if ([obj respondsToSelector:@selector(integerValue)]) {
        return [obj integerValue];
    }
    return defaultValue;
}

static NSString *YTStringByTrimmingToNil(NSString *value) {
    if (![value isKindOfClass:[NSString class]]) return nil;
    NSString *trimmed = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length > 0 ? trimmed : nil;
}

static BOOL YTBooleanFromObject(id obj) {
    if ([obj respondsToSelector:@selector(integerValue)]) {
        return [obj integerValue] != 0;
    }
    return NO;
}

static NSDictionary *YTDictionaryOrEmpty(id obj) {
    return [obj isKindOfClass:[NSDictionary class]] ? (NSDictionary *)obj : @{};
}

static NSArray *YTArrayOrEmpty(id obj) {
    return [obj isKindOfClass:[NSArray class]] ? (NSArray *)obj : @[];
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

static YTUnitType YTExerciseUnitTypeForString(NSString *exerciseType) {
    NSString *type = exerciseType ?: @"";
    if ([type isEqualToString:@"listen_tap"]) return YTUnitTypeExerciseListenChooseImage;
    if ([type isEqualToString:@"match_word"]) return YTUnitTypeExerciseLookChooseWord;
    if ([type isEqualToString:@"word_fill"]) return YTUnitTypeExerciseChooseWordFillBlank;
    if ([type isEqualToString:@"listen_respond"]) return YTUnitTypeExerciseListenChooseResponse;
    if ([type isEqualToString:@"sentence_builder"]) return YTUnitTypeExerciseBuildSentence;
    if ([type isEqualToString:@"complete_dialogue"]) return YTUnitTypeExerciseCompleteDialogue;
    return YTUnitTypePronounce;
}

static NSString *YTUnitIdFromTalkUnitPayload(NSDictionary *payload) {
    NSString *refTable = [payload yt_stringForKey:@"ref_table"];
    NSInteger unitId = [payload yt_integerForKey:@"unit_id" defaultValue:0];
    NSInteger refId = [payload yt_integerForKey:@"ref_id" defaultValue:0];
    NSInteger dialogueListId = [payload yt_integerForKey:@"dialogue_list_id" defaultValue:0];
    if ([refTable isEqualToString:@"dialogue"] && dialogueListId > 0) {
        return [NSString stringWithFormat:@"%@_%ld_%ld", refTable, (long)unitId, (long)dialogueListId];
    }
    NSInteger stableId = refId > 0 ? refId : unitId;
    if (stableId <= 0) {
        stableId = MAX(unitId, dialogueListId);
    }
    return [NSString stringWithFormat:@"%@_%ld", refTable.length > 0 ? refTable : @"step", (long)stableId];
}

static NSDictionary *YTGrammarPageFromTalkGrammar(NSDictionary *grammar, NSDictionary *content) {
    if (grammar.count == 0) return @{};
    NSString *keyword = YTStringByTrimmingToNil([content yt_stringForKey:@"grammar_keyword"]) ?: @"";
    NSString *keywordPinyin = YTStringByTrimmingToNil([content yt_stringForKey:@"pinyin"]) ?: @"";
    NSString *funcText = [grammar yt_stringForKey:@"func_text"];
    NSString *structText = [grammar yt_stringForKey:@"struct_text"];
    NSString *exampleText = [grammar yt_stringForKey:@"example_text"];

    NSMutableArray<NSDictionary *> *examples = [NSMutableArray array];
    NSArray<NSString *> *parts = [exampleText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray<NSString *> *cleanLines = [NSMutableArray array];
    for (NSString *line in parts) {
        NSString *trimmed = YTStringByTrimmingToNil(line);
        if (trimmed.length > 0) {
            [cleanLines addObject:trimmed];
        }
    }
    for (NSInteger i = 0; i + 1 < cleanLines.count; i += 2) {
        NSString *cn = cleanLines[i] ?: @"";
        NSString *en = cleanLines[i + 1] ?: @"";
        [examples addObject:@{
            @"cn": cn,
            @"en": en,
            @"highlightText": keyword ?: @""
        }];
    }

    NSMutableDictionary *page = [NSMutableDictionary dictionary];
    page[@"navTitle"] = [grammar yt_stringForKey:@"title"] ?: @"";
    page[@"description"] = funcText ?: @"";
    page[@"promptToken"] = keyword ?: @"";
    page[@"promptPinyin"] = keywordPinyin ?: @"";
    page[@"promptText"] = keyword.length > 0 ? keyword : [grammar yt_stringForKey:@"title"];
    page[@"formulaText"] = structText ?: @"";
    page[@"formulaHighlightText"] = keyword ?: @"";
    page[@"exampleLabel"] = NSLocalizedString(@"EXAMPLE", @"");
    page[@"arrowText"] = @"↓";
    if (examples.count > 0) {
        page[@"examples"] = [examples copy];
    }
    return [page copy];
}

static NSArray<NSDictionary *> *YTMapTalkExerciseChoices(NSArray *choices) {
    NSMutableArray<NSDictionary *> *out = [NSMutableArray array];
    for (id item in choices) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *choice = (NSDictionary *)item;
        NSMutableDictionary *mapped = [NSMutableDictionary dictionary];
        NSString *choiceId = [choice yt_stringForKey:@"id"];
        if (choiceId.length > 0) {
            mapped[@"id"] = choiceId;
        }
        NSString *text = YTStringByTrimmingToNil([choice yt_stringForKey:@"text"])
            ?: YTStringByTrimmingToNil([choice yt_stringForKey:@"text_cn"])
            ?: YTStringByTrimmingToNil([choice yt_stringForKey:@"word_cn"])
            ?: YTStringByTrimmingToNil([choice yt_stringForKey:@"word_en"])
            ?: @"";
        if (text.length > 0) {
            mapped[@"text"] = text;
        }
        NSString *imageURL = YTStringByTrimmingToNil([choice yt_stringForKey:@"image_url"]);
        if (imageURL.length > 0) {
            mapped[@"imageURL"] = imageURL;
        }
        NSString *audioURL = YTStringByTrimmingToNil([choice yt_stringForKey:@"audio_url"]);
        if (audioURL.length > 0) {
            mapped[@"audioURL"] = audioURL;
        }
        if (mapped.count > 0) {
            [out addObject:[mapped copy]];
        }
    }
    return [out copy];
}

static void YTApplyLegacyPayloadToUnit(YTUnit *u, NSDictionary *payload) {
    NSDictionary *display = payload[@"display"];
    if (![display isKindOfClass:[NSDictionary class]]) display = @{};

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
    } else if ([YTUnit yt_isExerciseQuestionType:u.unitType]) {
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
}

static void YTApplyTalkUnitPayloadToUnit(YTUnit *u, NSDictionary *payload, BOOL isLastStep) {
    NSDictionary *content = [payload yt_dictionaryForKey:@"content"];
    NSDictionary *dialogue = [payload yt_dictionaryForKey:@"dialogue"];
    NSDictionary *grammar = [content yt_dictionaryForKey:@"grammar"];
    NSDictionary *userPosition = [payload yt_dictionaryForKey:@"user_position"];
    NSString *refTable = [payload yt_stringForKey:@"ref_table"];
    NSInteger flatStep = [payload yt_integerForKey:@"flat_step" defaultValue:u.stepIndex + 1];
    BOOL completed = YTBooleanFromObject(payload[@"is_unit_completed"]);

    u.stepIndex = MAX(0, flatStep - 1);
    u.unitId = YTUnitIdFromTalkUnitPayload(payload);
    u.answeredCorrectFromServer = completed;

    if ([refTable isEqualToString:@"vocab"]) {
        u.unitType = YTUnitTypePronounce;
        u.titleCN = YTStringByTrimmingToNil([content yt_stringForKey:@"word_cn"]);
        u.titlePinyin = YTStringByTrimmingToNil([content yt_stringForKey:@"pinyin"]);
        u.titleEN = YTStringByTrimmingToNil([content yt_stringForKey:@"word_en"]);
        u.imageURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"image_url"]);
        u.audioURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"audio_url"]);
        return;
    }

    if ([refTable isEqualToString:@"dialogue"]) {
        u.unitType = YTUnitTypePronounce;
        u.titleCN = YTStringByTrimmingToNil([content yt_stringForKey:@"text_cn"]);
        u.titlePinyin = YTStringByTrimmingToNil([content yt_stringForKey:@"pinyin"]);
        u.titleEN = YTStringByTrimmingToNil([content yt_stringForKey:@"text_en"]);
        u.imageURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"image_url"]);
        u.audioURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"audio_url"]);

        NSString *grammarKeyword = YTStringByTrimmingToNil([content yt_stringForKey:@"grammar_keyword"]);
        if (grammarKeyword.length > 0 && ![grammarKeyword isEqualToString:@"0"]) {
            u.highlightTexts = @[grammarKeyword];
        }
        NSDictionary *grammarPage = YTGrammarPageFromTalkGrammar(grammar, content);
        if (grammarPage.count > 0) {
            u.grammarPageNavTitle = [grammarPage yt_stringForKey:@"navTitle"];
            u.grammarPageDescription = [grammarPage yt_stringForKey:@"description"];
            u.grammarPagePromptToken = [grammarPage yt_stringForKey:@"promptToken"];
            u.grammarPagePromptPinyin = [grammarPage yt_stringForKey:@"promptPinyin"];
            u.grammarPagePromptText = [grammarPage yt_stringForKey:@"promptText"];
            u.grammarPageFormulaText = [grammarPage yt_stringForKey:@"formulaText"];
            u.grammarPageFormulaHighlightText = [grammarPage yt_stringForKey:@"formulaHighlightText"];
            u.grammarPageExampleLabel = [grammarPage yt_stringForKey:@"exampleLabel"];
            u.grammarPageArrowText = [grammarPage yt_stringForKey:@"arrowText"];
            u.grammarPageExamples = [grammarPage yt_arrayForKey:@"examples"];
        }
        if (dialogue.count > 0) {
            NSString *remark = YTStringByTrimmingToNil([dialogue yt_stringForKey:@"remark"]);
            if (remark.length > 0) {
                u.imageName = remark;
            }
        }
        return;
    }

    if ([refTable isEqualToString:@"cross"]) {
        u.unitType = isLastStep ? YTUnitTypeLevelCompletion : YTUnitTypePracticeTransition;
        NSString *title = YTStringByTrimmingToNil([content yt_stringForKey:@"title"]);
        NSString *subtitle = YTStringByTrimmingToNil([content yt_stringForKey:@"sub_text"]);
        NSDictionary *display = @{
            @"title": title ?: @"",
            @"subtitle": subtitle ?: @""
        };
        YTMapPlainTitleAndSubtitle(u, display, !isLastStep);
        u.imageURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"image_url"]);
        return;
    }

    if ([refTable isEqualToString:@"exercise"]) {
        NSString *exerciseType = [content yt_stringForKey:@"exercise_type"];
        u.unitType = YTExerciseUnitTypeForString(exerciseType);
        u.titleCN = YTStringByTrimmingToNil([content yt_stringForKey:@"stem_text"]);
        u.titlePinyin = YTStringByTrimmingToNil([content yt_stringForKey:@"stem_pinyin"]);
        u.imageURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"stem_image_url"])
            ?: YTStringByTrimmingToNil([content yt_stringForKey:@"image_url"]);
        u.audioURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"stem_audio_url"])
            ?: YTStringByTrimmingToNil([content yt_stringForKey:@"audio_url"]);
        u.options = YTMapTalkExerciseChoices([[content yt_dictionaryForKey:@"options"] yt_arrayForKey:@"choices"]);

        NSDictionary *correctAnswer = [content yt_dictionaryForKey:@"correct_answer"];
        NSString *choiceId = YTStringByTrimmingToNil([correctAnswer yt_stringForKey:@"choice_id"]);
        if (choiceId.length > 0) {
            u.correctOptionId = choiceId;
        }

        NSString *answerTemplate = YTStringByTrimmingToNil([content yt_stringForKey:@"sub_text"])
            ?: YTStringByTrimmingToNil([content yt_stringForKey:@"answer_template"]);
        if (u.unitType == YTUnitTypeExerciseCompleteDialogue && answerTemplate.length > 0) {
            u.answerTemplateCN = answerTemplate;
        }

        NSString *correctSentence = YTStringByTrimmingToNil([correctAnswer yt_stringForKey:@"sentence_text"])
            ?: YTStringByTrimmingToNil([correctAnswer yt_stringForKey:@"text"])
            ?: YTStringByTrimmingToNil([content yt_stringForKey:@"score_text"]);
        if (u.unitType == YTUnitTypeExerciseBuildSentence && correctSentence.length > 0) {
            u.correctSentenceText = correctSentence;
        }

        if (completed && userPosition.count > 0 && [YTUnit yt_isSelectedOptionExerciseType:u.unitType] && u.correctOptionId.length > 0) {
            u.serverAnswerPayload = @{ @"selectedOptionId": u.correctOptionId };
        }
        return;
    }
}

@implementation YTUnitMapper

+ (NSArray<YTUnit *> *)mapUnitsFromResponse:(NSArray<NSDictionary *> *)response
                                    sceneId:(NSString *)sceneId
                                    levelId:(YTLevelId)levelId {
    NSMutableArray<YTUnit *> *units = [NSMutableArray array];
    NSInteger totalCount = response.count;
    for (NSInteger i = 0; i < totalCount; i++) {
        id payloadObj = response[i];
        if (![payloadObj isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *payload = (NSDictionary *)payloadObj;

        YTUnit *u = [[YTUnit alloc] init];
        u.sceneId = sceneId;
        u.levelId = levelId;
        u.stepIndex = i;

        if ([payload objectForKey:@"unitType"] != nil) {
            id unitTypeVal = payload[@"unitType"];
            NSString *unitId = payload[@"unitId"] ?: @"";
            NSInteger stepIndex = i;
            if (![unitTypeVal isKindOfClass:[NSNumber class]]) {
                continue;
            }
            NSInteger unitTypeInt = [unitTypeVal integerValue];
            if (unitTypeInt < (NSInteger)YTUnitTypePronounce || unitTypeInt > (NSInteger)YTUnitTypeLevelCompletion) {
                continue;
            }
            u.unitId = unitId;
            u.stepIndex = stepIndex;
            u.unitType = (YTUnitType)unitTypeInt;
            YTApplyLegacyPayloadToUnit(u, payload);
            [units addObject:u];
            continue;
        }

        if ([payload objectForKey:@"ref_table"] != nil) {
            YTApplyTalkUnitPayloadToUnit(u, payload, i == totalCount - 1);
            if (u.unitId.length == 0) {
                u.unitId = [NSString stringWithFormat:@"step_%ld", (long)i];
            }
            [units addObject:u];
        }
    }

    return units;
}

@end
