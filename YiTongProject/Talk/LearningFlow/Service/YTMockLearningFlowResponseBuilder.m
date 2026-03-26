//
//  YTMockLearningFlowResponseBuilder.m
//  YiTongProject
//

#import "YTMockLearningFlowResponseBuilder.h"
#import "HeaderConfig.h"

static NSString *const kLastPositionKeyPrefix = @"talk_last_position";

/// 与旧版「前端插入」位置一致：过渡页插在首道练习题前；完成页在末尾。若 `units` 已含 7/8 则不再追加（便于真实接口直接下发）。
static void YTAppendBuiltinTransitionAndCompletionIfMissing(NSMutableArray<NSDictionary *> *resp, NSString *sceneId, YTLevelId levelId) {
    BOOL hasTrans = NO;
    BOOL hasComp = NO;
    for (NSDictionary *u in resp) {
        NSInteger ut = [u[@"unitType"] integerValue];
        if (ut == YTUnitTypePracticeTransition) hasTrans = YES;
        if (ut == YTUnitTypeLevelCompletion) hasComp = YES;
    }
    if (!hasTrans && resp.count > 0) {
        NSInteger firstExerciseIndex = NSNotFound;
        for (NSInteger i = 0; i < resp.count; i++) {
            NSInteger t = [resp[i][@"unitType"] integerValue];
            if (t != YTUnitTypePronounce) {
                firstExerciseIndex = i;
                break;
            }
        }
        if (firstExerciseIndex != NSNotFound && firstExerciseIndex > 0) {
            NSDictionary *payload = [YTMockLearningFlowResponseBuilder practiceTransitionUnitPayloadForSceneId:sceneId levelId:levelId];
            [resp insertObject:payload atIndex:firstExerciseIndex];
        }
    }
    if (!hasComp && resp.count > 0) {
        [resp addObject:[YTMockLearningFlowResponseBuilder levelCompletionUnitPayloadForSceneId:sceneId levelId:levelId]];
    }
}

@implementation YTMockLearningFlowResponseBuilder

+ (NSDictionary *)buildResponseForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
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
                @"unitType": @(YTUnitTypePronounce),
                @"unitId": [NSString stringWithFormat:@"vocab_%ld", (long)i],
                @"display": @{
                    @"title": @{@"zh": d[@"cn"], @"pinyin": d[@"py"], @"en": d[@"en"]},
                    @"image": @{@"name": d[@"img"], @"url": remoteImageURL ?: @""},
                    @"media": media ?: @[],
                    @"audio": @{@"referenceUrl": @""},
                }
            }];
        }

        for (NSInteger i = 0; i < 2; i++) {
            NSString *unitId = [NSString stringWithFormat:@"ex_listen_choose_image_%ld", (long)i];
            NSString *pinyin = (i == 0) ? @"tú shū guǎn" : @"xué shēng";
            NSString *correctId = (i == 0) ? @"b" : @"d";

            [resp addObject:@{
                @"unitType": @(YTUnitTypeExerciseListenChooseImage),
                @"unitId": unitId,
                @"display": @{
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

        for (NSInteger i = 0; i < 2; i++) {
            NSString *unitId = [NSString stringWithFormat:@"ex_look_choose_word_%ld", (long)i];
            NSString *headerImg = (i == 0) ? @"scene_vocab_student" : @"scene_vocab_classroom";
            NSString *correctId = (i == 0) ? @"b" : @"c";

            [resp addObject:@{
                @"unitType": @(YTUnitTypeExerciseLookChooseWord),
                @"unitId": unitId,
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
                @"unitType": @(YTUnitTypePronounce),
                @"unitId": [NSString stringWithFormat:@"dlg_%ld", (long)i],
                @"display": display
            }];
        }

        NSArray<NSNumber *> *exTypes = @[
            @(YTUnitTypeExerciseChooseWordFillBlank),
            @(YTUnitTypeExerciseListenChooseResponse),
            @(YTUnitTypeExerciseBuildSentence),
            @(YTUnitTypeExerciseCompleteDialogue),
        ];

        for (NSInteger i = 0; i < exTypes.count; i++) {
            YTUnitType t = (YTUnitType)[exTypes[i] integerValue];
            NSString *unitId = [NSString stringWithFormat:@"ex_%ld", (long)i];

            NSMutableDictionary *display = [@{
                @"title": @{@"zh": @"", @"pinyin": @"", @"en": @""},
                @"options": @[],
                @"audio": @{@"referenceUrl": @""},
            } mutableCopy];

            NSString *correctOptionId = @"";

            if (t == YTUnitTypeExerciseChooseWordFillBlank) {
                display[@"title"] = @{@"zh": @"你是学生__？", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"吗"},
                    @{@"id": @"b", @"text": @"呢"},
                    @{@"id": @"c", @"text": @"啊"},
                ];
                correctOptionId = @"a";
            } else if (t == YTUnitTypeExerciseListenChooseResponse) {
                display[@"title"] = @{@"zh": @"听音选择正确回应", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"是的，我是学生。"},
                    @{@"id": @"b", @"text": @"我也是。"},
                    @{@"id": @"c", @"text": @"你好！"},
                ];
                display[@"audio"] = @{@"referenceUrl": @""};
                correctOptionId = @"a";
            } else if (t == YTUnitTypeExerciseBuildSentence) {
                display[@"title"] = @{@"zh": @"拼出句子", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"text": @"你"},
                    @{@"text": @"是"},
                    @{@"text": @"学生"},
                    @{@"text": @"吗"},
                    @{@"text": @"？"},
                ];
                display[@"correctSentenceText"] = @"你是学生吗？";
            } else if (t == YTUnitTypeExerciseCompleteDialogue) {
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
                @"unitType": @(t),
                @"unitId": unitId,
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
                @"unitType": @(YTUnitTypePronounce),
                @"unitId": [NSString stringWithFormat:@"dlg_adv_%ld", (long)i],
                @"display": display
            }];
        }

        NSArray<NSNumber *> *exTypes = @[
            @(YTUnitTypeExerciseChooseWordFillBlank),
            @(YTUnitTypeExerciseListenChooseResponse),
            @(YTUnitTypeExerciseBuildSentence),
            @(YTUnitTypeExerciseCompleteDialogue),
        ];
        for (NSInteger i = 0; i < exTypes.count; i++) {
            YTUnitType t = (YTUnitType)[exTypes[i] integerValue];
            NSString *unitId = [NSString stringWithFormat:@"ex_adv_%ld", (long)i];

            NSMutableDictionary *display = [@{
                @"title": @{@"zh": @"", @"pinyin": @"", @"en": @""},
                @"options": @[],
                @"audio": @{@"referenceUrl": @""},
            } mutableCopy];
            NSString *correctOptionId = @"";

            if (t == YTUnitTypeExerciseChooseWordFillBlank) {
                display[@"title"] = @{@"zh": @"请问图书馆在__里？", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"哪"},
                    @{@"id": @"b", @"text": @"那"},
                    @{@"id": @"c", @"text": @"呢"},
                ];
                correctOptionId = @"a";
            } else if (t == YTUnitTypeExerciseListenChooseResponse) {
                display[@"title"] = @{@"zh": @"听音选择正确回应", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"id": @"a", @"text": @"还没有，要到九点才开门。"},
                    @{@"id": @"b", @"text": @"我是学生。"},
                    @{@"id": @"c", @"text": @"谢谢。"},
                ];
                correctOptionId = @"a";
            } else if (t == YTUnitTypeExerciseBuildSentence) {
                display[@"title"] = @{@"zh": @"拼出句子", @"pinyin": @"", @"en": @""};
                display[@"options"] = @[
                    @{@"text": @"现在"},
                    @{@"text": @"开门"},
                    @{@"text": @"了吗"},
                    @{@"text": @"？"},
                ];
                display[@"correctSentenceText"] = @"现在开门了吗？";
            } else if (t == YTUnitTypeExerciseCompleteDialogue) {
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
                @"unitType": @(t),
                @"unitId": unitId,
                @"display": display,
                @"evaluation": @{@"rule": @{@"correctOptionId": correctOptionId}}
            }];
        }

        {
            NSString *unitId = [NSString stringWithFormat:@"ex_adv_%ld", (long)exTypes.count];
            NSString *correctSentenceText = @"现在请你打开书本开始学习";
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
                @"correctSentenceText": correctSentenceText,
                @"audio": @{@"referenceUrl": @""},
            } mutableCopy];

            [resp addObject:@{
                @"unitType": @(YTUnitTypeExerciseBuildSentence),
                @"unitId": unitId,
                @"display": display,
                @"evaluation": @{@"rule": @{}}
            }];
        }
    }

    YTAppendBuiltinTransitionAndCompletionIfMissing(resp, sceneId, levelId);

    return @{
        @"units": resp,
    };
}

+ (NSDictionary *)practiceTransitionUnitPayloadForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    NSString *uid = [NSString stringWithFormat:@"%@_%ld_practice_transition", sceneId ?: @"scene", (long)levelId];
    NSMutableDictionary *display = [NSMutableDictionary dictionary];
    switch (levelId) {
        case YTLevelIdBeginner:
            display[@"title"] = NSLocalizedString(@"Talk_PracticeTransition_Title_Beginner", @"");
            display[@"subtitle"] = NSLocalizedString(@"Talk_PracticeTransition_Subtitle", @"");
            break;
        case YTLevelIdIntermediate:
            display[@"title"] = NSLocalizedString(@"Talk_PracticeTransition_Title_Intermediate", @"");
            display[@"subtitle"] = NSLocalizedString(@"Talk_PracticeTransition_Subtitle_Intermediate", @"");
            break;
        case YTLevelIdAdvanced:
            display[@"title"] = NSLocalizedString(@"Talk_PracticeTransition_Title_Advanced", @"");
            display[@"sections"] = @[
                @{ @"caption": NSLocalizedString(@"Talk_PracticeTransition_AdvSec1_Label", @""), @"body": NSLocalizedString(@"Talk_PracticeTransition_AdvSec1_Body", @"") },
                @{ @"caption": NSLocalizedString(@"Talk_PracticeTransition_AdvSec2_Label", @""), @"body": NSLocalizedString(@"Talk_PracticeTransition_AdvSec2_Body", @"") },
            ];
            break;
    }
    return @{ @"unitType": @(YTUnitTypePracticeTransition), @"unitId": uid, @"display": [display copy] };
}

+ (NSDictionary *)levelCompletionUnitPayloadForSceneId:(NSString *)sceneId levelId:(YTLevelId)levelId {
    NSString *uid = [NSString stringWithFormat:@"%@_%ld_level_complete", sceneId ?: @"scene", (long)levelId];
    NSMutableDictionary *display = [NSMutableDictionary dictionary];
    switch (levelId) {
        case YTLevelIdBeginner:
            display[@"scoreText"] = NSLocalizedString(@"Talk_LevelComplete_Beginner_Score", @"");
            display[@"title"] = NSLocalizedString(@"Talk_LevelComplete_Beginner_Headline", @"");
            display[@"subtitle"] = NSLocalizedString(@"Talk_LevelComplete_Beginner_Subtitle", @"");
            break;
        case YTLevelIdIntermediate:
            display[@"title"] = NSLocalizedString(@"Talk_LevelComplete_Intermediate_Headline", @"");
            display[@"subtitle"] = NSLocalizedString(@"Talk_LevelComplete_Intermediate_Subtitle", @"");
            break;
        case YTLevelIdAdvanced:
            display[@"title"] = NSLocalizedString(@"Talk_LevelComplete_Advanced_Headline", @"");
            display[@"subtitle"] = NSLocalizedString(@"Talk_LevelComplete_Advanced_Subtitle", @"");
            break;
    }
    return @{ @"unitType": @(YTUnitTypeLevelCompletion), @"unitId": uid, @"display": [display copy] };
}

@end
