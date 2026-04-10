//
//  YTUnitMapper.m
//  YiTongProject
//

#import "YTUnitMapper.h"
#import "NSDictionary+YTSafe.h"
#import "YTUnitViewProtocol.h"
#import "HeaderConfig.h"

/// `explore/audios/...` 等相对路径拼 HOST，便于播放器加载
static NSString * _Nullable YTFullMediaURLStringFromPathOrURL(NSString * _Nullable raw) {
    if (raw.length == 0) return nil;
    NSString *s = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (s.length == 0) return nil;
    NSString *low = s.lowercaseString;
    if ([low hasPrefix:@"http://"] || [low hasPrefix:@"https://"]) {
        return s;
    }
    NSString *host = [HOST copy];
    while ([host hasSuffix:@"/"]) {
        host = [host substringToIndex:host.length - 1];
    }
    NSString *path = s;
    if (![path hasPrefix:@"/"]) {
        path = [NSString stringWithFormat:@"/%@", path];
    }
    return [NSString stringWithFormat:@"%@%@", host, path];
}

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

/// 与 `correct_answer.fills` 顺序一致，从 `options` 解析出各空对应的 `id`（续学 `serverAnswerPayload` 用）
static NSArray<NSString *> *YTMapperOptionIdsForFillTexts(YTUnit *u) {
    if (u.unitType != YTUnitTypeExerciseChooseWordFillBlank || u.correctFillTexts.count == 0) return nil;
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    for (NSString *want in u.correctFillTexts) {
        if (![want isKindOfClass:[NSString class]]) return nil;
        NSString *trimWant = [want stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimWant.length == 0) return nil;
        NSString *foundId = nil;
        for (NSDictionary *opt in u.options) {
            if (![opt isKindOfClass:[NSDictionary class]]) continue;
            NSString *txt = opt[@"text"];
            if (![txt isKindOfClass:[NSString class]]) continue;
            if ([[txt stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:trimWant]) {
                id oid = opt[@"id"];
                foundId = [oid isKindOfClass:[NSString class]] ? (NSString *)oid : [NSString stringWithFormat:@"%@", oid];
                break;
            }
        }
        if (foundId.length == 0) return nil;
        [out addObject:foundId];
    }
    return [out copy];
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
    // 接口外层 `unit_id` 优先（提交 /talk/complete 与后台一致）；勿用 ref_id 覆盖
    id rawOuterUnitId = [payload objectForKey:@"unit_id"];
    if (rawOuterUnitId != nil && rawOuterUnitId != (id)kCFNull) {
        if ([rawOuterUnitId isKindOfClass:[NSString class]]) {
            NSString *s = YTStringByTrimmingToNil((NSString *)rawOuterUnitId);
            if (s.length > 0) {
                return s;
            }
        } else if ([rawOuterUnitId isKindOfClass:[NSNumber class]]) {
            NSInteger n = [(NSNumber *)rawOuterUnitId integerValue];
            if (n > 0) {
                return [NSString stringWithFormat:@"%ld", (long)n];
            }
        }
    }
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
        NSString *choiceId = YTStringByTrimmingToNil([choice yt_stringForKey:@"id"])
            ?: YTStringByTrimmingToNil([choice yt_stringForKey:@"choice_id"]);
        if (choiceId.length > 0) {
            mapped[@"id"] = choiceId;
        }
        NSString *text = YTStringByTrimmingToNil([choice yt_stringForKey:@"text"])
            ?: YTStringByTrimmingToNil([choice yt_stringForKey:@"text_cn"])
            ?: YTStringByTrimmingToNil([choice yt_stringForKey:@"word_cn"])
            ?: YTStringByTrimmingToNil([choice yt_stringForKey:@"word_en"])
            ?: YTStringByTrimmingToNil([choice yt_stringForKey:@"title"])
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
            if (!mapped[@"id"] || [(NSString *)mapped[@"id"] length] == 0) {
                mapped[@"id"] = [NSString stringWithFormat:@"choice_%ld", (long)out.count];
            }
            [out addObject:[mapped copy]];
        }
    }
    return [out copy];
}

/// `sentence_builder`：`options.shuffle == 1` 时对词块顺序做一次随机打乱（与 Mock 行为一致）
static NSArray<NSDictionary *> *YTShuffledWordBankOptionsIfNeeded(NSArray *mapped, BOOL shuffle) {
    if (![mapped isKindOfClass:[NSArray class]] || mapped.count < 2 || !shuffle) {
        return mapped;
    }
    NSMutableArray *m = [mapped mutableCopy];
    for (NSUInteger i = m.count; i > 1; i--) {
        NSUInteger j = arc4random_uniform((uint32_t)i);
        [m exchangeObjectAtIndex:j withObjectAtIndex:i - 1];
    }
    return [m copy];
}

/// 选词填空 `word_fill`：`options.word_bank` 为字符串数组 → `{ id, text }`，供 `YTFillBlankUnitView` 使用
static NSArray<NSDictionary *> *YTMapWordFillWordBank(NSArray *wordBank) {
    if (![wordBank isKindOfClass:[NSArray class]] || wordBank.count == 0) {
        return @[];
    }
    NSMutableArray<NSDictionary *> *out = [NSMutableArray array];
    for (NSInteger i = 0; i < wordBank.count; i++) {
        id item = wordBank[i];
        NSString *text = nil;
        if ([item isKindOfClass:[NSString class]]) {
            text = YTStringByTrimmingToNil((NSString *)item);
        }
        if (text.length == 0) continue;
        [out addObject:@{ @"id": [NSString stringWithFormat:@"word_%ld", (long)i], @"text": text }];
    }
    return [out copy];
}

/// `vocab` / `dialogue`：`content.media` 非空时直接用；否则用 `image_url` + `video_url` 组装（`video_url` 有值则出现视频页，走 `YTPronounceUnitView` 已有逻辑）
static void YTMapTalkPronounceMediaItemsFromContent(YTUnit *u, NSDictionary *content) {
    if (![content isKindOfClass:[NSDictionary class]] || content.count == 0) return;
    id rawMedia = [content objectForKey:@"media"];
    if ([rawMedia isKindOfClass:[NSArray class]] && [(NSArray *)rawMedia count] > 0) {
        u.mediaItems = [(NSArray *)rawMedia copy];
        return;
    }
    NSString *videoURL = YTStringByTrimmingToNil([content yt_stringForKey:@"video_url"]);
    NSString *imgURL = YTStringByTrimmingToNil([content yt_stringForKey:@"image_url"]);
    NSMutableArray<NSDictionary *> *arr = [NSMutableArray array];
    if (imgURL.length > 0) {
        [arr addObject:@{ @"type": @"image", @"url": imgURL }];
    }
    if (videoURL.length > 0) {
        [arr addObject:@{ @"type": @"video", @"url": videoURL }];
    }
    if (arr.count > 0) {
        u.mediaItems = [arr copy];
    }
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
        u.stemText = YTStringByTrimmingToNil([display yt_stringForKey:@"stem_text"]);
        NSDictionary *image = display[@"image"] ?: @{};
        if ([image isKindOfClass:[NSDictionary class]]) {
            u.imageName = image[@"name"];
            u.imageURLString = image[@"url"];
        }
        id media = display[@"media"];
        if ([media isKindOfClass:[NSArray class]] && [(NSArray *)media count] > 0) {
            u.mediaItems = [(NSArray *)media copy];
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
        if (!u.mediaItems || u.mediaItems.count == 0) {
            NSString *legacyVideo = YTStringByTrimmingToNil([display yt_stringForKey:@"video_url"]);
            if (legacyVideo.length > 0) {
                NSMutableArray<NSDictionary *> *arr = [NSMutableArray array];
                if (u.imageURLString.length > 0) {
                    [arr addObject:@{ @"type": @"image", @"url": u.imageURLString ?: @"" }];
                }
                [arr addObject:@{ @"type": @"video", @"url": legacyVideo }];
                u.mediaItems = [arr copy];
            }
        }
    } else if ([YTUnit yt_isExerciseQuestionType:u.unitType]) {
        NSDictionary *title = display[@"title"] ?: @{};
        if ([title isKindOfClass:[NSDictionary class]]) {
            u.titleCN = title[@"zh"];
            u.titlePinyin = title[@"pinyin"];
            u.titleEN = title[@"en"];
        }
        u.stemText = YTStringByTrimmingToNil([display yt_stringForKey:@"stem_text"]);

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
        u.stemText = YTStringByTrimmingToNil([display yt_stringForKey:@"stem_text"]);
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
        u.stemText = YTStringByTrimmingToNil([display yt_stringForKey:@"stem_text"]);
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

/// `/talk/unit` 单步数据：规范为 `payload.content`；若接口把题干直接放在与 `ref_table` 同级（无 `content` 包裹），则顶层字典即题干
static NSDictionary *YTResolvedTalkContentDictionary(NSDictionary *payload) {
    if (![payload isKindOfClass:[NSDictionary class]]) return @{};
    NSDictionary *nested = [payload yt_dictionaryForKey:@"content"];
    if (nested.count > 0) return nested;
    if (YTStringByTrimmingToNil([payload yt_stringForKey:@"stem_text"]).length > 0 ||
        YTStringByTrimmingToNil([payload yt_stringForKey:@"stem_pinyin"]).length > 0 ||
        YTStringByTrimmingToNil([payload yt_stringForKey:@"exercise_type"]).length > 0 ||
        YTStringByTrimmingToNil([payload yt_stringForKey:@"word_cn"]).length > 0 ||
        YTStringByTrimmingToNil([payload yt_stringForKey:@"text_cn"]).length > 0) {
        return payload;
    }
    return nested;
}

/// 练习题 `content.options`：多为 `{ choices: [...] }`，也可能直接为选项数组
static NSArray *YTExerciseChoicesArrayFromContent(NSDictionary *content) {
    id raw = [content objectForKey:@"options"];
    if ([raw isKindOfClass:[NSArray class]]) return (NSArray *)raw;
    if ([raw isKindOfClass:[NSDictionary class]]) {
        return [(NSDictionary *)raw yt_arrayForKey:@"choices"];
    }
    return @[];
}

static NSDictionary *YTExerciseOptionsDictionary(NSDictionary *content) {
    id raw = [content objectForKey:@"options"];
    if ([raw isKindOfClass:[NSDictionary class]]) return (NSDictionary *)raw;
    return @{};
}

/// `/talk/unit`：`is_unit_completed` 与 `is_line_completed` 任一为 1 即该步已完成
static BOOL YTTalkUnitStepCompleted(NSDictionary *payload) {
    if (![payload isKindOfClass:[NSDictionary class]]) return NO;
    return [payload yt_integerForKey:@"is_unit_completed" defaultValue:0] == 1
        || [payload yt_integerForKey:@"is_line_completed" defaultValue:0] == 1;
}

/// 将接口 `progress`（含 `answerPayload`）合并到单元；优先覆盖本地由 step 标记推导的字段
static void YTMergeTalkProgressDictionaryIntoUnit(YTUnit *u, NSDictionary *payload) {
    NSDictionary *progress = [payload yt_dictionaryForKey:@"progress"];
    if (progress.count == 0) return;
    id ac = progress[@"answeredCorrect"];
    if ([ac isKindOfClass:[NSNumber class]]) {
        u.answeredCorrectFromServer = [ac boolValue];
    }
    id ap = progress[@"answerPayload"];
    if ([ap isKindOfClass:[NSDictionary class]] && [(NSDictionary *)ap count] > 0) {
        u.serverAnswerPayload = [ap copy];
    }
}

static void YTApplyTalkUnitPayloadToUnit(YTUnit *u, NSDictionary *payload, BOOL isLastStep) {
    NSDictionary *content = YTResolvedTalkContentDictionary(payload);
    NSDictionary *dialogue = [payload yt_dictionaryForKey:@"dialogue"];
    NSDictionary *grammar = [content yt_dictionaryForKey:@"grammar"];
    NSString *refTable = [payload yt_stringForKey:@"ref_table"];
    NSInteger flatStep = [payload yt_integerForKey:@"flat_step" defaultValue:u.stepIndex + 1];
    BOOL completed = YTTalkUnitStepCompleted(payload);

    u.stepIndex = MAX(0, flatStep - 1);
    u.unitId = YTUnitIdFromTalkUnitPayload(payload);
    u.answeredCorrectFromServer = completed;
    u.refTable = YTStringByTrimmingToNil(refTable);
    u.contentSceneId = YTStringByTrimmingToNil([content yt_stringForKey:@"scene_id"]);
    u.contentLevelIdString = YTStringByTrimmingToNil([content yt_stringForKey:@"level_id"]);
    u.contentId = YTStringByTrimmingToNil([content yt_stringForKey:@"id"])
        ?: YTStringByTrimmingToNil([content yt_stringForKey:@"content_id"])
        ?: YTStringByTrimmingToNil([payload yt_stringForKey:@"content_id"]);

    if ([refTable isEqualToString:@"vocab"]) {
        u.unitType = YTUnitTypePronounce;
        u.stemText = YTStringByTrimmingToNil([content yt_stringForKey:@"stem_text"]);
        u.titleCN = YTStringByTrimmingToNil([content yt_stringForKey:@"word_cn"]);
        u.titlePinyin = YTStringByTrimmingToNil([content yt_stringForKey:@"pinyin"]);
        u.titleEN = YTStringByTrimmingToNil([content yt_stringForKey:@"word_en"]);
        u.imageURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"image_url"]);
        u.audioURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"audio_url"]);
        YTMapTalkPronounceMediaItemsFromContent(u, content);
        YTMergeTalkProgressDictionaryIntoUnit(u, payload);
        return;
    }

    if ([refTable isEqualToString:@"dialogue"]) {
        u.unitType = YTUnitTypePronounce;
        u.stemText = YTStringByTrimmingToNil([content yt_stringForKey:@"stem_text"]);
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
        YTMapTalkPronounceMediaItemsFromContent(u, content);
        YTMergeTalkProgressDictionaryIntoUnit(u, payload);
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
        u.stemText = YTStringByTrimmingToNil([content yt_stringForKey:@"stem_text"]);
        u.imageURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"image_url"]);
        YTMergeTalkProgressDictionaryIntoUnit(u, payload);
        return;
    }

    if ([refTable isEqualToString:@"exercise"]) {
        NSString *exerciseType = [content yt_stringForKey:@"exercise_type"];
        u.unitType = YTExerciseUnitTypeForString(exerciseType);
        NSString *stemInstruction = YTStringByTrimmingToNil([content yt_stringForKey:@"stem_text"]);
        u.stemText = stemInstruction;
        u.titleCN = stemInstruction;
        u.titlePinyin = YTStringByTrimmingToNil([content yt_stringForKey:@"stem_pinyin"]);
        u.imageURLString = YTStringByTrimmingToNil([content yt_stringForKey:@"stem_image_url"])
            ?: YTStringByTrimmingToNil([content yt_stringForKey:@"image_url"]);
        {
            NSString *stemAudio = YTFullMediaURLStringFromPathOrURL(YTStringByTrimmingToNil([content yt_stringForKey:@"stem_audio_url"]));
            NSString *fallbackAudio = YTFullMediaURLStringFromPathOrURL(YTStringByTrimmingToNil([content yt_stringForKey:@"audio_url"]));
            u.audioURLString = (stemAudio.length > 0) ? stemAudio : fallbackAudio;
        }

        NSDictionary *exerciseOptions = YTExerciseOptionsDictionary(content);
        // word_fill：题干在 `options.sentence_template`（含 __），选项在 `options.word_bank`（字符串数组）
        if (u.unitType == YTUnitTypeExerciseChooseWordFillBlank) {
            NSString *sentenceTemplate = YTStringByTrimmingToNil([exerciseOptions yt_stringForKey:@"sentence_template"]);
            NSArray *mappedBank = YTMapWordFillWordBank([exerciseOptions yt_arrayForKey:@"word_bank"]);
            if (sentenceTemplate.length > 0) {
                u.titleCN = sentenceTemplate;
            }
            if (mappedBank.count > 0) {
                u.options = mappedBank;
            }
        }
        // sentence_builder：词块在 `options.word_bank`（与 word_fill 同形），无 `choices` 时须单独映射
        if (u.unitType == YTUnitTypeExerciseBuildSentence) {
            NSArray *sentenceBank = [exerciseOptions yt_arrayForKey:@"word_bank"];
            if (sentenceBank.count > 0) {
                NSArray *mappedTokens = YTMapWordFillWordBank(sentenceBank);
                if (mappedTokens.count > 0) {
                    BOOL shuffle = YTBooleanFromObject([exerciseOptions objectForKey:@"shuffle"]);
                    u.options = YTShuffledWordBankOptionsIfNeeded(mappedTokens, shuffle);
                }
            }
        }
        if (u.unitType == YTUnitTypeExerciseCompleteDialogue) {
            NSArray *ctxLines = [exerciseOptions yt_arrayForKey:@"context_lines"];
            if (ctxLines.count > 0) {
                u.completeDialogueContextLines = [ctxLines copy];
            }
        }
        if (u.options.count == 0) {
            u.options = YTMapTalkExerciseChoices(YTExerciseChoicesArrayFromContent(content));
        }

        NSDictionary *correctAnswer = [content yt_dictionaryForKey:@"correct_answer"];
        u.serverCorrectAnswerTemplate = correctAnswer.count > 0 ? [correctAnswer copy] : nil;
        NSString *choiceId = YTStringByTrimmingToNil([correctAnswer yt_stringForKey:@"choice_id"]);
        if (choiceId.length > 0) {
            u.correctOptionId = choiceId;
        }
        // word_fill：标答为 correct_answer.fills（词文案数组），与 options 里 text 匹配后得到对应 id（与提交 selectedOptionId 一致）
        if (u.unitType == YTUnitTypeExerciseChooseWordFillBlank) {
            NSArray *fillsRaw = [correctAnswer yt_arrayForKey:@"fills"];
            NSMutableArray<NSString *> *fillTexts = [NSMutableArray array];
            for (id o in fillsRaw) {
                if ([o isKindOfClass:[NSString class]]) {
                    NSString *t = YTStringByTrimmingToNil((NSString *)o);
                    if (t.length > 0) {
                        [fillTexts addObject:t];
                    }
                }
            }
            if (fillTexts.count > 0) {
                u.correctFillTexts = [fillTexts copy];
            }
            if (u.correctOptionId.length == 0 && fillTexts.count > 0) {
                NSString *wantText = fillTexts[0];
                for (NSDictionary *opt in u.options) {
                    if (![opt isKindOfClass:[NSDictionary class]]) continue;
                    NSString *txt = YTStringByTrimmingToNil([opt yt_stringForKey:@"text"]);
                    if (txt.length > 0 && [txt isEqualToString:wantText]) {
                        NSString *oid = YTStringByTrimmingToNil([opt yt_stringForKey:@"id"]);
                        if (oid.length > 0) {
                            u.correctOptionId = oid;
                        }
                        break;
                    }
                }
            }
        }

        NSString *answerTemplate = YTStringByTrimmingToNil([content yt_stringForKey:@"sub_text"])
            ?: YTStringByTrimmingToNil([content yt_stringForKey:@"answer_template"])
            ?: YTStringByTrimmingToNil([exerciseOptions yt_stringForKey:@"answer_template"])
            ?: YTStringByTrimmingToNil([exerciseOptions yt_stringForKey:@"sub_text"]);
        if (u.unitType == YTUnitTypeExerciseCompleteDialogue && answerTemplate.length > 0) {
            u.answerTemplateCN = answerTemplate;
        }

        NSString *correctSentence = YTStringByTrimmingToNil([correctAnswer yt_stringForKey:@"sentence_text"])
            ?: YTStringByTrimmingToNil([correctAnswer yt_stringForKey:@"text"])
            ?: YTStringByTrimmingToNil([content yt_stringForKey:@"score_text"]);
        if (u.unitType == YTUnitTypeExerciseBuildSentence && correctSentence.length == 0) {
            NSArray *orderArr = [correctAnswer yt_arrayForKey:@"order"];
            if (orderArr.count > 0) {
                NSMutableArray<NSString *> *parts = [NSMutableArray array];
                for (id o in orderArr) {
                    if ([o isKindOfClass:[NSString class]]) {
                        NSString *t = YTStringByTrimmingToNil((NSString *)o);
                        if (t.length > 0) [parts addObject:t];
                    } else if ([o isKindOfClass:[NSNumber class]]) {
                        NSString *t = YTStringByTrimmingToNil([NSString stringWithFormat:@"%@", o]);
                        if (t.length > 0) [parts addObject:t];
                    }
                }
                if (parts.count > 0) {
                    correctSentence = [parts componentsJoinedByString:@""];
                }
            }
        }
        if (u.unitType == YTUnitTypeExerciseBuildSentence && correctSentence.length > 0) {
            u.correctSentenceText = correctSentence;
        }

        // 无 `progress.answerPayload` 时，由本题 `correct_answer` 推导回填（仍属接口下发的题干内字段）
        if (completed) {
            if (u.unitType == YTUnitTypeExerciseChooseWordFillBlank && u.correctFillTexts.count > 1) {
                NSArray<NSString *> *fillIds = YTMapperOptionIdsForFillTexts(u);
                if (fillIds.count == u.correctFillTexts.count) {
                    u.serverAnswerPayload = @{ YTAnswerPayloadKeySelectedFillOptionIds: fillIds };
                }
            } else if ([YTUnit yt_isSelectedOptionExerciseType:u.unitType] && u.correctOptionId.length > 0) {
                u.serverAnswerPayload = @{ @"selectedOptionId": u.correctOptionId };
            }
        }
        YTMergeTalkProgressDictionaryIntoUnit(u, payload);
        return;
    }
}

@implementation YTUnitMapper

+ (NSDictionary *)yt_resolvedContentFromTalkUnitPayload:(NSDictionary *)payload {
    return YTResolvedTalkContentDictionary(payload);
}

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
