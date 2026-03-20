//
//  YTMockUnitFactory.m
//  YiTongProject
//

#import "YTMockUnitFactory.h"
#import "HeaderConfig.h"

static NSString *const kLastPositionKeyPrefix = @"talk_last_position";

@implementation YTMockUnitFactory

+ (void)fetchUnitsForSceneId:(NSString *)sceneId
                      levelId:(YTLevelId)levelId
                    completion:(void (^)(NSArray<YTUnit *> * _Nonnull units))completion {
    // MVP：用固定延迟模拟接口耗时（后续接真实网络只需替换这里）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        NSDictionary *response = [self buildMockAPIResponseForSceneId:sceneId levelId:levelId];
        NSArray<NSDictionary *> *unitsArray = response[@"units"];
        if (![unitsArray isKindOfClass:[NSArray class]]) unitsArray = @[];
        NSArray<YTUnit *> *units = [self buildUnitsFromAPIResponse:unitsArray sceneId:sceneId levelId:levelId];
        if (completion) completion(units);
    });
}

+ (NSArray<YTUnit *> *)buildUnitsForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    NSDictionary *response = [self buildMockAPIResponseForSceneId:sceneId levelId:levelId];
    NSArray<NSDictionary *> *unitsArray = response[@"units"];
    if (![unitsArray isKindOfClass:[NSArray class]]) unitsArray = @[];
    return [self buildUnitsFromAPIResponse:unitsArray sceneId:sceneId levelId:levelId];
}

#pragma mark - Mock API response -> YTUnit mapping

/**
 * mock “接口返回”的完整结构（为贴近真实接入，先构建 response，再映射成 YTUnit）
 *
 * 返回结构：@{ @"units": [...], @"lastPosition": {...} }
 * - units：各难度的学习单元列表
 * - lastPosition：上次学习步骤（模拟阶段从本地取；接接口后由接口返回）
 */
+ (NSDictionary *)buildMockAPIResponseForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    NSMutableArray<NSDictionary *> *resp = [NSMutableArray array];

    if (levelId == YTLevelIdBeginner) {
        NSString *remoteImageURL = @"https://img0.baidu.com/it/u=3591665277,2616537962&fm=253&app=138&f=JPEG?w=800&h=1333";
        NSArray *vocabs = @[
            @{@"cn": @"学生", @"py": @"xué shēng", @"en": @"Student", @"img": @"scene_vocab_student"},
            @{@"cn": @"老师", @"py": @"lǎo shī", @"en": @"Teacher", @"img": @"scene_vocab_teacher"},
            @{@"cn": @"教室", @"py": @"jiào shì", @"en": @"Classroom", @"img": @"scene_vocab_classroom"},
            @{@"cn": @"图书馆", @"py": @"tú shū guǎn", @"en": @"Library", @"img": @"scene_vocab_library"},
        ];
        for (NSInteger i = 0; i < vocabs.count; i++) {
            NSDictionary *d = vocabs[i];
            // Demo：词汇页中间媒体可为图片或视频（左右滑动）。
            // 后续接真实接口时由后端下发 display.media 结构即可。
            NSArray *media = nil;
            if (i == 0) {
                media = @[
                    @{@"type": @"video", @"url": @"https://www.w3schools.com/html/mov_bbb.mp4"},
                    @{@"type": @"image", @"url": remoteImageURL ?: @""},
                ];
            } else {
                media = @[
                    @{@"type": @"image", @"url": remoteImageURL ?: @""},
                ];
            }
            [resp addObject:@{
                @"unitType": @"vocab",
                @"unitId": [NSString stringWithFormat:@"vocab_%ld", (long)i],
                @"stepIndex": @(i),
                @"display": @{
                    @"title": @{@"zh": d[@"cn"], @"pinyin": d[@"py"], @"en": d[@"en"]},
                    @"image": @{@"name": d[@"img"], @"url": remoteImageURL ?: @""},
                    @"media": media ?: @[],
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
                @"unitType": @"exercise_listen_choose_image",
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
                @"unitType": @"exercise_look_choose_word",
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

        NSArray<NSString *> *exTypes = @[
            @"exercise_choose_word_fill_blank",
            @"exercise_listen_choose_response",
            @"exercise_build_sentence",
            @"exercise_complete_dialogue",
        ];

        for (NSInteger i = 0; i < exTypes.count; i++) {
            NSString *t = exTypes[i];
            NSString *unitId = [NSString stringWithFormat:@"ex_%ld", (long)i];

            NSMutableDictionary *display = [@{
                @"title": @{@"zh": @"", @"pinyin": @"", @"en": @""},
                @"options": @[],
                @"audio": @{@"referenceUrl": @""},
            } mutableCopy];

            NSString *correctOptionId = @"";

            if ([t isEqualToString:@"exercise_choose_word_fill_blank"]) {
                display[@"title"] = @{@"zh": @"你是学生__？", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"吗"},
                    @{@"id": @"b", @"text": @"呢"},
                    @{@"id": @"c", @"text": @"啊"},
                ];
                correctOptionId = @"a";
            } else if ([t isEqualToString:@"exercise_listen_choose_response"]) {
                display[@"title"] = @{@"zh": @"听音选择正确回应", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"是的，我是学生。"},
                    @{@"id": @"b", @"text": @"我也是。"},
                    @{@"id": @"c", @"text": @"你好！"},
                ];
                // MVP 当前 audioURLString 为空即可
                display[@"audio"] = @{@"referenceUrl": @""};
                correctOptionId = @"a";
            } else if ([t isEqualToString:@"exercise_build_sentence"]) {
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
            } else if ([t isEqualToString:@"exercise_complete_dialogue"]) {
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
                @"unitType": t,
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

        NSArray<NSString *> *exTypes = @[
            @"exercise_choose_word_fill_blank",
            @"exercise_listen_choose_response",
            @"exercise_build_sentence",
            @"exercise_complete_dialogue",
        ];
        for (NSInteger i = 0; i < exTypes.count; i++) {
            NSString *t = exTypes[i];
            NSString *unitId = [NSString stringWithFormat:@"ex_adv_%ld", (long)i];

            NSMutableDictionary *display = [@{
                @"title": @{@"zh": @"", @"pinyin": @"", @"en": @""},
                @"options": @[],
                @"audio": @{@"referenceUrl": @""},
            } mutableCopy];
            NSString *correctOptionId = @"";

            if ([t isEqualToString:@"exercise_choose_word_fill_blank"]) {
                display[@"title"] = @{@"zh": @"请问图书馆在__里？", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"哪"},
                    @{@"id": @"b", @"text": @"那"},
                    @{@"id": @"c", @"text": @"呢"},
                ];
                correctOptionId = @"a";
            } else if ([t isEqualToString:@"exercise_listen_choose_response"]) {
                display[@"title"] = @{@"zh": @"听音选择正确回应", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"还没有，要到九点才开门。"},
                    @{@"id": @"b", @"text": @"我是学生。"},
                    @{@"id": @"c", @"text": @"谢谢。"},
                ];
                correctOptionId = @"a";
            } else if ([t isEqualToString:@"exercise_build_sentence"]) {
                display[@"title"] = @{@"zh": @"拼出句子", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"text": @"现在"},
                    @{@"text": @"开门"},
                    @{@"text": @"了吗"},
                    @{@"text": @"？"},
                ];
                correctOptionId = @"现在开门了吗？";
            } else if ([t isEqualToString:@"exercise_complete_dialogue"]) {
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
                @"unitType": t,
                @"unitId": unitId,
                @"stepIndex": @(lines.count + i),
                @"display": display,
                @"evaluation": @{@"rule": @{@"correctOptionId": correctOptionId}}
            }];
        }

        // 追加一题：困难级句子组装（要求至少 7 个词块）
        {
            NSString *t = @"exercise_build_sentence";
            NSString *unitId = [NSString stringWithFormat:@"ex_adv_%ld", (long)exTypes.count];

            // 注意：答案字符串必须等于 options 中 text 的顺序拼接（无空格）
            NSString *correctOptionId = @"现在请你打开书本开始学习";
            NSMutableDictionary *display = [@{
                @"title": @{@"zh": @"拼出句子", @"pinyin": @"", @"en": @""},
                @"options": @[
                    @{@"text": @"现在"},
                    @{@"text": @"请"},
                    @{@"text": @"你"},
                    @{@"text": @"打开"},
                    @{@"text": @"书本"},
                    @{@"text": @"开始"},
                    @{@"text": @"学习"},
                ],
                @"audio": @{@"referenceUrl": @""},
            } mutableCopy];

            [resp addObject:@{
                @"unitType": t,
                @"unitId": unitId,
                @"stepIndex": @(lines.count + exTypes.count),
                @"display": display,
                @"evaluation": @{@"rule": @{@"correctOptionId": correctOptionId}}
            }];
        }
    }

    // 上次学习步骤：模拟阶段从本地取；接接口后该字段由接口返回
    NSString *lastPositionKey = [NSString stringWithFormat:@"%@_%@_%ld", kLastPositionKeyPrefix, sceneId ?: @"", (long)levelId];
    id lastPositionRaw = [KUSER_DEFAULT objectForKey:lastPositionKey];
    if (![lastPositionRaw isKindOfClass:[NSDictionary class]]) lastPositionRaw = nil;

    return @{
        @"units": resp,
        @"lastPosition": lastPositionRaw ?: [NSNull null],
    };
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

        if ([unitTypeStr isEqualToString:@"vocab"] || [unitTypeStr isEqualToString:@"dialogue_line"]) {
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
                // 未知 exercise_*：必须标成练习题，避免默认成 pronounce 导致进度/解锁异常
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

