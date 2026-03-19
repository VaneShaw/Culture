//
//  YTMockUnitFactory.m
//  YiTongProject
//

#import "YTMockUnitFactory.h"

@implementation YTMockUnitFactory

+ (void)fetchUnitsForSceneId:(NSString *)sceneId
                      levelId:(YTLevelId)levelId
                    completion:(void (^)(NSArray<YTUnit *> * _Nonnull units))completion {
    // MVP：用固定延迟模拟接口耗时（后续接真实网络只需替换这里）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSArray<NSDictionary *> *response = [self buildMockAPIResponseForSceneId:sceneId levelId:levelId];
        NSArray<YTUnit *> *units = [self buildUnitsFromAPIResponse:response sceneId:sceneId levelId:levelId];
        if (completion) completion(units);
    });
}

+ (NSArray<YTUnit *> *)buildUnitsForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    NSArray<NSDictionary *> *response = [self buildMockAPIResponseForSceneId:sceneId levelId:levelId];
    return [self buildUnitsFromAPIResponse:response sceneId:sceneId levelId:levelId];
}

#pragma mark - Mock API response -> YTUnit mapping

/**
 * mock “接口返回”的结构（为贴近真实接入，先构建 response，再映射成 YTUnit）
 *
 * response 目前只覆盖 MVP 用到的字段；未来替换真实接口时，尽量保持这些字段形状一致即可。
 */
+ (NSArray<NSDictionary *> *)buildMockAPIResponseForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    NSMutableArray<NSDictionary *> *resp = [NSMutableArray array];

    if (levelId == YTLevelIdBeginner) {
        NSArray *vocabs = @[
            @{@"cn": @"学生", @"py": @"xué shēng", @"en": @"Student", @"img": @"scene_vocab_student"},
            @{@"cn": @"老师", @"py": @"lǎo shī", @"en": @"Teacher", @"img": @"scene_vocab_teacher"},
            @{@"cn": @"教室", @"py": @"jiào shì", @"en": @"Classroom", @"img": @"scene_vocab_classroom"},
            @{@"cn": @"图书馆", @"py": @"tú shū guǎn", @"en": @"Library", @"img": @"scene_vocab_library"},
        ];
        for (NSInteger i = 0; i < vocabs.count; i++) {
            NSDictionary *d = vocabs[i];
            [resp addObject:@{
                @"unitType": @"vocab",
                @"unitId": [NSString stringWithFormat:@"vocab_%ld", (long)i],
                @"stepIndex": @(i),
                @"display": @{
                    @"title": @{@"zh": d[@"cn"], @"pinyin": d[@"py"], @"en": d[@"en"]},
                    @"image": @{@"name": d[@"img"]},
                    @"audio": @{@"referenceUrl": @""},
                }
            }];
        }

        // 听词选图 x2
        for (NSInteger i = 0; i < 2; i++) {
            NSString *unitId = [NSString stringWithFormat:@"ex_listen_choose_image_%ld", (long)i];
            NSString *pinyin = (i == 0) ? @"tú shū guǎn" : @"xué shēng";
            NSString *correctId = (i == 0) ? @"b" : @"d";

            [resp addObject:@{
                @"unitType": @"exercise",
                @"exerciseType": @(YTExerciseTypeListenChooseImage),
                @"unitId": unitId,
                @"stepIndex": @(vocabs.count + i),
                @"display": @{
                    // 听词选图：pinyin 会在 UI 的 pinyinLabel 展示
                    @"title": @{@"zh": @"", @"pinyin": pinyin, @"en": @""},
                    @"image": @{@"name": @""},
                    @"options": @[
                        @{@"id": @"a", @"text": @"老师", @"imageName": @"scene_vocab_teacher"},
                        @{@"id": @"b", @"text": @"图书馆", @"imageName": @"scene_vocab_library"},
                        @{@"id": @"c", @"text": @"教室", @"imageName": @"scene_vocab_classroom"},
                        @{@"id": @"d", @"text": @"学生", @"imageName": @"scene_vocab_student"},
                    ],
                    @"audio": @{@"referenceUrl": @""},
                },
                @"evaluation": @{
                    @"rule": @{@"correctOptionId": correctId}
                }
            }];
        }

        // 看图选词 x2
        for (NSInteger i = 0; i < 2; i++) {
            NSString *unitId = [NSString stringWithFormat:@"ex_look_choose_word_%ld", (long)i];
            NSString *headerImg = (i == 0) ? @"scene_vocab_student" : @"scene_vocab_classroom";
            NSString *correctId = (i == 0) ? @"b" : @"c";

            [resp addObject:@{
                @"unitType": @"exercise",
                @"exerciseType": @(YTExerciseTypeLookChooseWord),
                @"unitId": unitId,
                @"stepIndex": @(vocabs.count + 2 + i),
                @"display": @{
                    @"title": @{@"zh": @"", @"pinyin": @"", @"en": @""},
                    @"image": @{@"name": headerImg},
                    @"options": @[
                        @{@"id": @"a", @"text": @"老师"},
                        @{@"id": @"b", @"text": @"学生"},
                        @{@"id": @"c", @"text": @"教室"},
                        @{@"id": @"d", @"text": @"图书馆"},
                    ],
                },
                @"evaluation": @{
                    @"rule": @{@"correctOptionId": correctId}
                }
            }];
        }
    } else if (levelId == YTLevelIdIntermediate) {
        NSArray *lines = @[
            @{@"cn": @"你是学生吗？", @"py": @"Nǐ shì xué shēng ma?", @"en": @"Are you a student?"},
            @{@"cn": @"是的，我是学生。", @"py": @"Shì de, wǒ shì xué shēng.", @"en": @"Yes, I am a student."},
        ];
        for (NSInteger i = 0; i < lines.count; i++) {
            NSDictionary *d = lines[i];
            NSMutableDictionary *display = [@{
                @"title": @{@"zh": d[@"cn"], @"pinyin": d[@"py"], @"en": d[@"en"]},
                @"image": @{@"name": @"scene_dialogue_people"},
            } mutableCopy];

            if (i == 0) {
                display[@"highlights"] = @[@{@"text": @"吗"}];
                display[@"grammarText"] = @"Grammar Rule\n\n“吗”用于一般疑问句的句末。";
                display[@"grammarPage"] = @{
                    @"navTitle": @"Grammar Rule",
                    @"description": @"Used at the end of a sentence to ask a yes/no question.",
                    @"promptToken": @"吗",
                    @"promptPinyin": @"ma",
                    @"promptText": @"… 吗?  (ma)",
                    @"formulaText": @"Statement +  吗?  = Question",
                    @"formulaHighlightText": @"吗?",
                    @"exampleLabel": @"EXAMPLE",
                    @"arrowText": @"↓",
                    @"examples": @[
                        @{@"cn": @"你是学生。", @"en": @"You are a student.", @"highlightText": @""},
                        @{@"cn": @"你是学生吗?", @"en": @"Are you a student?", @"highlightText": @"吗?"},
                        @{@"cn": @"你是老师吗?", @"en": @"Are you a teacher?", @"highlightText": @"吗?"},
                    ]
                };
            }

            [resp addObject:@{
                @"unitType": @"dialogue_line",
                @"unitId": [NSString stringWithFormat:@"dlg_%ld", (long)i],
                @"stepIndex": @(i),
                @"display": display
            }];
        }

        NSArray *exTypes = @[
            @(YTExerciseTypeChooseWordFillBlank),
            @(YTExerciseTypeListenChooseResponse),
            @(YTExerciseTypeBuildSentence),
            @(YTExerciseTypeCompleteDialogue),
        ];

        for (NSInteger i = 0; i < exTypes.count; i++) {
            YTExerciseType t = (YTExerciseType)[exTypes[i] integerValue];
            NSString *unitId = [NSString stringWithFormat:@"ex_%ld", (long)i];

            NSMutableDictionary *display = [@{
                @"title": @{@"zh": @"", @"pinyin": @"", @"en": @""},
                @"options": @[],
                @"audio": @{@"referenceUrl": @""},
            } mutableCopy];

            NSString *correctOptionId = @"";

            if (t == YTExerciseTypeChooseWordFillBlank) {
                display[@"title"] = @{@"zh": @"你是学生__？", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"吗"},
                    @{@"id": @"b", @"text": @"呢"},
                    @{@"id": @"c", @"text": @"啊"},
                ];
                correctOptionId = @"a";
            } else if (t == YTExerciseTypeListenChooseResponse) {
                display[@"title"] = @{@"zh": @"听音选择正确回应", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"是的，我是学生。"},
                    @{@"id": @"b", @"text": @"我也是。"},
                    @{@"id": @"c", @"text": @"你好！"},
                ];
                // MVP 当前 audioURLString 为空即可
                display[@"audio"] = @{@"referenceUrl": @""};
                correctOptionId = @"a";
            } else if (t == YTExerciseTypeBuildSentence) {
                display[@"title"] = @{@"zh": @"拼出句子", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"text": @"你"},
                    @{@"text": @"是"},
                    @{@"text": @"学生"},
                    @{@"text": @"吗"},
                    @{@"text": @"？"},
                ];
                // MVP：复用 correctOptionId 保存“正确句子字符串”
                correctOptionId = @"你是学生吗？";
            } else if (t == YTExerciseTypeCompleteDialogue) {
                display[@"title"] = @{@"zh": @"你是学生吗？如果是的话请回答一下，我们需要确认你的身份。", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"是的"},
                    @{@"id": @"b", @"text": @"谢谢"},
                    @{@"id": @"c", @"text": @"请问"},
                ];
                display[@"answerTemplate"] = @{@"zh": @"__，我是学生。我在一年级。"};
                correctOptionId = @"a";
            }

            [resp addObject:@{
                @"unitType": @"exercise",
                @"exerciseType": @(t),
                @"unitId": unitId,
                @"stepIndex": @(lines.count + i),
                @"display": display,
                @"evaluation": @{@"rule": @{@"correctOptionId": correctOptionId}}
            }];
        }
    } else if (levelId == YTLevelIdAdvanced) {
        NSArray *lines = @[
            @{@"cn": @"请问图书馆在哪里？", @"py": @"Qǐng wèn tú shū guǎn zài nǎ lǐ?", @"en": @"Where is the library?"},
            @{@"cn": @"在教学楼旁边。", @"py": @"Zài jiào xué lóu páng biān.", @"en": @"Next to the teaching building."},
            @{@"cn": @"现在开门了吗？", @"py": @"Xiàn zài kāi mén le ma?", @"en": @"Is it open now?"},
            @{@"cn": @"还没有，要到九点才开门。", @"py": @"Hái méi yǒu, yào dào jiǔ diǎn cái kāi mén.", @"en": @"Not yet, it opens at 9."},
        ];

        for (NSInteger i = 0; i < lines.count; i++) {
            NSDictionary *d = lines[i];
            NSMutableDictionary *display = [@{
                @"title": @{@"zh": d[@"cn"], @"pinyin": d[@"py"], @"en": d[@"en"]},
                @"image": @{@"name": @"scene_dialogue_people"},
            } mutableCopy];

            if ([d[@"cn"] containsString:@"吗"]) {
                display[@"highlights"] = @[@{@"text": @"吗"}];
                display[@"grammarText"] = @"Grammar Rule\n\n“吗”用于一般疑问句的句末。";
                display[@"grammarPage"] = @{
                    @"navTitle": @"Grammar Rule",
                    @"description": @"Used at the end of a sentence to ask a yes/no question.",
                    @"promptToken": @"吗",
                    @"promptPinyin": @"ma",
                    @"promptText": @"… 吗?  (ma)",
                    @"formulaText": @"Statement +  吗?  = Question",
                    @"formulaHighlightText": @"吗?",
                    @"exampleLabel": @"EXAMPLE",
                    @"arrowText": @"↓",
                    @"examples": @[
                        @{@"cn": @"你是学生。", @"en": @"You are a student.", @"highlightText": @""},
                        @{@"cn": @"你是学生吗?", @"en": @"Are you a student?", @"highlightText": @"吗?"},
                        @{@"cn": @"你是老师吗?", @"en": @"Are you a teacher?", @"highlightText": @"吗?"},
                    ]
                };
            }

            [resp addObject:@{
                @"unitType": @"dialogue_line",
                @"unitId": [NSString stringWithFormat:@"dlg_adv_%ld", (long)i],
                @"stepIndex": @(i),
                @"display": display
            }];
        }

        NSArray *exTypes = @[
            @(YTExerciseTypeChooseWordFillBlank),
            @(YTExerciseTypeListenChooseResponse),
            @(YTExerciseTypeBuildSentence),
            @(YTExerciseTypeCompleteDialogue),
        ];
        for (NSInteger i = 0; i < exTypes.count; i++) {
            YTExerciseType t = (YTExerciseType)[exTypes[i] integerValue];
            NSString *unitId = [NSString stringWithFormat:@"ex_adv_%ld", (long)i];

            NSMutableDictionary *display = [@{
                @"title": @{@"zh": @"", @"pinyin": @"", @"en": @""},
                @"options": @[],
                @"audio": @{@"referenceUrl": @""},
            } mutableCopy];
            NSString *correctOptionId = @"";

            if (t == YTExerciseTypeChooseWordFillBlank) {
                display[@"title"] = @{@"zh": @"请问图书馆在__里？", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"哪"},
                    @{@"id": @"b", @"text": @"那"},
                    @{@"id": @"c", @"text": @"呢"},
                ];
                correctOptionId = @"a";
            } else if (t == YTExerciseTypeListenChooseResponse) {
                display[@"title"] = @{@"zh": @"听音选择正确回应", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"还没有，要到九点才开门。"},
                    @{@"id": @"b", @"text": @"我是学生。"},
                    @{@"id": @"c", @"text": @"谢谢。"},
                ];
                correctOptionId = @"a";
            } else if (t == YTExerciseTypeBuildSentence) {
                display[@"title"] = @{@"zh": @"拼出句子", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"text": @"现在"},
                    @{@"text": @"开门"},
                    @{@"text": @"了吗"},
                    @{@"text": @"？"},
                ];
                correctOptionId = @"现在开门了吗？";
            } else if (t == YTExerciseTypeCompleteDialogue) {
                display[@"title"] = @{@"zh": @"现在开门了吗？", @"pinyin": @"", @"en": @""};
                display[@"answerTemplate"] = @{@"zh": @"__，还没有。"};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"不"},
                    @{@"id": @"b", @"text": @"是的"},
                    @{@"id": @"c", @"text": @"谢谢"},
                ];
                correctOptionId = @"a";
            }

            [resp addObject:@{
                @"unitType": @"exercise",
                @"exerciseType": @(t),
                @"unitId": unitId,
                @"stepIndex": @(lines.count + i),
                @"display": display,
                @"evaluation": @{@"rule": @{@"correctOptionId": correctOptionId}}
            }];
        }
    }

    return resp;
}

/**
 * response 映射成 YTUnit，尽量保证“字段形状”与后续真实接口一致，从而让替换网络层改动最小。
 */
+ (NSArray<YTUnit *> *)buildUnitsFromAPIResponse:(NSArray<NSDictionary *> *)response
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

        if ([unitTypeStr isEqualToString:@"vocab"]) {
            u.unitType = YTUnitTypeVocab;
            NSDictionary *title = display[@"title"] ?: @{};
            if ([title isKindOfClass:[NSDictionary class]]) {
                u.titleCN = title[@"zh"];
                u.titlePinyin = title[@"pinyin"];
                u.titleEN = title[@"en"];
            }
            NSDictionary *image = display[@"image"] ?: @{};
            if ([image isKindOfClass:[NSDictionary class]]) {
                u.imageName = image[@"name"];
            }
            NSDictionary *audio = display[@"audio"] ?: @{};
            if ([audio isKindOfClass:[NSDictionary class]]) {
                u.audioURLString = audio[@"referenceUrl"];
            }
        } else if ([unitTypeStr isEqualToString:@"dialogue_line"]) {
            u.unitType = YTUnitTypeDialogueLine;
            NSDictionary *title = display[@"title"] ?: @{};
            if ([title isKindOfClass:[NSDictionary class]]) {
                u.titleCN = title[@"zh"];
                u.titlePinyin = title[@"pinyin"];
                u.titleEN = title[@"en"];
            }

            NSDictionary *image = display[@"image"] ?: @{};
            if ([image isKindOfClass:[NSDictionary class]]) {
                u.imageName = image[@"name"];
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
        } else if ([unitTypeStr isEqualToString:@"exercise"]) {
            u.unitType = YTUnitTypeExercise;
            NSNumber *exTypeNum = payload[@"exerciseType"];
            if ([exTypeNum isKindOfClass:[NSNumber class]]) {
                u.exerciseType = (YTExerciseType)[exTypeNum integerValue];
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
            }

            NSArray *options = display[@"options"];
            if ([options isKindOfClass:[NSArray class]]) {
                u.options = options;
            }

            NSDictionary *answerTpl = display[@"answerTemplate"] ?: @{};
            if ([answerTpl isKindOfClass:[NSDictionary class]]) {
                u.answerTemplateCN = answerTpl[@"zh"];
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

