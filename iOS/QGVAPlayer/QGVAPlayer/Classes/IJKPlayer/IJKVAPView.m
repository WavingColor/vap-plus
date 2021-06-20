//
//  IJKVAPView.m
//  QGVAPlayer
//
//  Created by 高亮军 on 2021/6/6.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "IJKVAPView.h"
#import "QGHWDMP4OpenGLView.h"
#import <IJKMediaFramework/IJKMediaFramework.h>
#define QG_FOURCC(a, b, c, d) \
        (((uint32_t)a) | (((uint32_t)b) << 8) | (((uint32_t)c) << 16) | (((uint32_t)d) << 24))

// YUV formats
#define QG_FCC_YV12    QG_FOURCC('Y', 'V', '1', '2')  /**< bpp=12, Planar mode: Y + V + U  (3 planes) */
#define QG_FCC_IYUV    QG_FOURCC('I', 'Y', 'U', 'V')  /**< bpp=12, Planar mode: Y + U + V  (3 planes) */
#define QG_FCC_I420    QG_FOURCC('I', '4', '2', '0')  /**< bpp=12, Planar mode: Y + U + V  (3 planes) */

@interface IJKVAPView () <IJKSDLGLViewProtocol>

@property(atomic, strong) id<IJKMediaPlayback> player;
@property (nonatomic, assign) NSUInteger frameIndex;

@end

@implementation IJKVAPView
@synthesize fps = _fps;
@synthesize isThirdGLView = _isThirdGLView;
@synthesize scaleFactor = _scaleFactor;


+ (void)setupIJK {
#ifdef DEBUG
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];

}

- (void)dealloc {
    [self.player stop];
}

- (void)playHWDMP4:(NSString *)filePath repeatCount:(NSInteger)repeatCount {
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    [options setOptionIntValue:1 forKey:@"videotoolbox" ofCategory:kIJKFFOptionCategoryPlayer];

    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self.player stop];
    [self.player.view removeFromSuperview];
    
    self.frameIndex = 0;
    QGHWDMP4OpenGLView *glView = [[QGHWDMP4OpenGLView alloc] initWithFrame:self.bounds];
    self.player = [[IJKFFMoviePlayerController alloc] initWithMoreContentString:filePath withOptions:options withGLView:self];
    [glView setupGL];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didPlayToEnd:) name:IJKMPMoviePlayerPlaybackDidFinishNotification object:self.player];
    self.player.view.frame = self.bounds;
    self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    self.player.shouldAutoplay = YES;
    
    [self.player prepareToPlay];
}

- (void)didPlayToEnd:(NSNotification *)noti {
    self.frameIndex = 0;
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)play {
    [self.player play];
}

- (void)stop {
    [self.player stop];
}

- (void)renderPixel:(CVPixelBufferRef)pixel {
    if (self.renderFrame) {
        self.renderFrame(pixel, self.frameIndex);
        self.frameIndex++;
    }
}

#pragma mark - IJKSDLGLViewProtocol
- (void)display_pixels:(IJKOverlay *)overlay {
    if (overlay->pixel_buffer) {
        [self renderPixel:overlay->pixel_buffer];
    } else if (overlay->pixels) {
        CVPixelBufferRef pixel = [self YUVPixelBufferCreate:overlay];
        [self renderPixel:pixel];
        if (pixel) {
            CVPixelBufferRelease(pixel);
        }
    }
}

- (UIImage *)snapshot {
    if (self.snapshotBlock) {
        return self.snapshotBlock();
    }
    return nil;
}

- (CVPixelBufferRef)YUVPixelBufferCreate:(IJKOverlay *)overlay {
    CGSize frameSize = CGSizeMake(overlay->w, overlay->h);
    
    int     planes[3]           = { 0, 1, 2 };
    const GLsizei widths[3]     = { overlay->pitches[0], overlay->pitches[1], overlay->pitches[2] };
    const GLsizei heights[3]    = { overlay->h,          overlay->h / 2,      overlay->h / 2 };
    const GLubyte *pixels[3]    = { overlay->pixels[0],  overlay->pixels[1],  overlay->pixels[2] };
    
    switch (overlay->format) {
        case QG_FCC_I420:
            break;
        case QG_FCC_YV12:
            planes[1] = 2;
            planes[2] = 1;
            break;
        default:
            VAP_Error(kQGVAPModuleCommon, @"[yuv420p] unexpected format %x\n", overlay->format);
            return GL_FALSE;
    }
    NSDictionary *pixelAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameSize.width,
                                          frameSize.height,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                          (__bridge CFDictionaryRef)(pixelAttributes),
                                          &pixelBuffer);

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t planeC = CVPixelBufferGetPlaneCount(pixelBuffer);
    
    for (int pc = 0; pc < planeC; pc++) {
        size_t pw1 = CVPixelBufferGetWidthOfPlane(pixelBuffer, pc);
        size_t ph1 = CVPixelBufferGetHeightOfPlane(pixelBuffer, pc);
        size_t yBytePerRow = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, pc);
        uint8_t *destPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, pc);
        size_t iTop, iBottom, iLeft, iRight;
        CVPixelBufferGetExtendedPixels(pixelBuffer, &iLeft, &iRight, &iTop, &iBottom);
        VAP_Info(kQGVAPModuleCommon, @"generate pixel properites of plane %d: w: %zu, h: %zu, bytePerRow: %zu, baseAddr: %p, extend: [%zu, %zu, %zu, %zu]", pc, pw1, ph1, yBytePerRow, destPlane, iTop, iBottom, iLeft, iRight);
    }
    
    uint8_t *yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(yDestPlane, pixels[0], widths[0] * heights[0]);
    
    size_t uvH = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    size_t uvBytePerRow = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    uint8_t *uvDestPlane = (uint8_t *) CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
//    memcpy(uvDestPlane, pixels[1], widths[1] * heights[1]);

    memset(uvDestPlane, 0x80, uvH * uvBytePerRow);

    uint8_t *uData = (uint8_t *)pixels[1];
    uint8_t *vData = (uint8_t *)pixels[2];

    for (int row = 0; row < uvH; row++) {
        size_t startAddr = row * uvBytePerRow;

        for (int u = 0; u < widths[1]; u++) {
            memset(uvDestPlane + startAddr + u * 2, uData[row * widths[1] + u], sizeof(int8_t));
        }
        for (int v = 0; v < widths[2]; v++) {
            memset(uvDestPlane + startAddr + v * 2 + 1, vData[row * widths[2] + v], sizeof(int8_t));
        }
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return pixelBuffer;
}


@end
