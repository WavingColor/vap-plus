//
//  IJKVAPView.h
//  QGVAPlayer
//
//  Created by 高亮军 on 2021/6/6.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <IJKMediaFramework/IJKSDLGLViewProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface IJKVAPView : UIView

+ (void)setupIJK;

- (void)playHWDMP4:(NSString *)filePath repeatCount:(NSInteger)repeatCount;

/// 渲染
@property (nonatomic, copy) void(^renderFrame)(CVPixelBufferRef frame, NSUInteger index);
@property (nonatomic, copy) UIImage *(^snapshotBlock)(void);

- (void)pause;
- (void)play;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
