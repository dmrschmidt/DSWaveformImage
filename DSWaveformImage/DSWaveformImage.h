//
//  DSWaveformImage.h
//
//  Created by Dennis Schmidt on 07.09.13.
//  Copyright (c) 2013 Dennis Schmidt. All rights reserved.
//
//  Large parts found at http://stackoverflow.com/questions/8298610/waveform-on-ios
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    DSWaveformStyleStripes = 0,
    DSWaveformStyleFull = 1
} DSWaveformStyle;

@interface DSWaveformImage : UIImage {
    NSInteger _sampleCount;
    Float32 _normalizeMax;
    CGFloat _imageHeight;
    CGFloat _imageWidth;
    
    Float32 *_samples;
    CGSize _graphSize;
}

@property(nonatomic) UIColor *graphColor;
@property(nonatomic) DSWaveformStyle style;

+ (UIImage *)waveformForAssetAtURL:(NSURL *)url
                             color:(UIColor *)color
                              size:(CGSize)size
                             scale:(CGFloat)scale
                             style:(DSWaveformStyle)style;

+ (UIImage *)waveformForAsset:(AVAsset *)asset
                        color:(UIColor *)color
                         size:(CGSize)size
                        scale:(CGFloat)scale
                        style:(DSWaveformStyle)style;

@end
