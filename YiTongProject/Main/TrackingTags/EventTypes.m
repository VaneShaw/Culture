//
//  EventTypes.m
//  YiTongProject
//
//  Created by ios01 on 2026/2/3.
//

#import "EventTypes.h"

@implementation EventTypes
NSString * const EventTypeAppActivate = @"app_activate";
NSString * const EventTypeAppLaunch = @"app_launch";
NSString * const EventTypeLogin = @"login";
NSString * const EventTypeRegister = @"register";
NSString * const EventTypeLogout = @"logout";
NSString * const EventTypeCancel = @"cancel";

NSString * const EventTypePageView = @"page_view";
NSString * const EventTypeLearn = @"learn";
NSString * const EventTypeStory = @"story";
NSString * const EventTypeQuiz = @"quiz";

NSString * const EventTypeAppForeground = @"app_foreground";
NSString * const EventTypeAppBackground = @"app_background";
NSString * const EventTypeAppHeartbeat = @"app_heartbeat";
/*
 app_activate      App 首次激活（只一次）
app_launch        App 启动
login             登录
register          注册
logout            退出登录
cancel            注销账号
 
page_view         页面访问
learn             学习
story             故事
quiz              测试
app_foreground    App 进入前台
app_background    App 进入后台
app_heartbeat     App 使用时长心跳
 */
@end
