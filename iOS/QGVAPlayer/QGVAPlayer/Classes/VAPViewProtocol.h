//
//  VAPViewProtocol.h
//  QGVAPlayer
//
//  Created by 高亮军 on 2021/6/6.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VAPMacros.h"
#import "QGVAPLogger.h"

@protocol HWDMP4PlayDelegate;
@class QGMP4AnimatedImageFrame,QGVAPConfigModel, QGVAPSourceInfo;

/** 注意：回调方法会在子线程被执行。*/
@protocol HWDMP4PlayDelegate <NSObject>

@optional
//即将开始播放时询问，true马上开始播放，false放弃播放
- (BOOL)shouldStartPlayMP4:(VAPView *)container config:(QGVAPConfigModel *)config;

- (void)viewDidStartPlayMP4:(VAPView *)container;
- (void)viewDidPlayMP4AtFrame:(QGMP4AnimatedImageFrame*)frame view:(VAPView *)container;
- (void)viewDidStopPlayMP4:(NSInteger)lastFrameIndex view:(VAPView *)container;
- (void)viewDidFinishPlayMP4:(NSInteger)totalFrameCount view:(VAPView *)container;
- (void)viewDidFailPlayMP4:(NSError *)error;

//vap APIs
- (NSString *)contentForVapTag:(NSString *)tag resource:(QGVAPSourceInfo *)info;        //替换配置中的资源占位符（不处理直接返回tag）
- (void)loadVapImageWithURL:(NSString *)urlStr context:(NSDictionary *)context completion:(VAPImageCompletionBlock)completionBlock; //由于组件内不包含网络图片加载的模块，因此需要外部支持图片加载。

@end

@protocol VAPViewProtocol <NSObject>

@property (nonatomic, weak) id<HWDMP4PlayDelegate>      hwd_Delegate;
@property (nonatomic, readonly) QGMP4AnimatedImageFrame *hwd_currentFrame;
@property (nonatomic, strong) NSString                  *hwd_MP4FilePath;
@property (nonatomic, assign) NSInteger                 hwd_fps;         //fps for dipslay, each frame's duration would be set by fps value before display.
@property (nonatomic, assign) BOOL                      hwd_renderByOpenGL;      //是否使用opengl渲染，默认使用metal

@property (nonatomic, assign) BOOL                      ijk_Codec;      //是否使用ijkPlayer解码，默认 YES

- (void)playHWDMp4:(NSString *)filePath;
- (void)playHWDMP4:(NSString *)filePath delegate:(id<HWDMP4PlayDelegate>)delegate;
- (void)playHWDMP4:(NSString *)filePath repeatCount:(NSInteger)repeatCount delegate:(id<HWDMP4PlayDelegate>)delegate;

- (void)stopHWDMP4;

/// 注意，一旦退后台就会强制stop，退回前台后再resume无效
- (void)pauseHWDMP4;
- (void)resumeHWDMP4;

+ (void)registerHWDLog:(QGVAPLoggerFunc)logger;

@end
