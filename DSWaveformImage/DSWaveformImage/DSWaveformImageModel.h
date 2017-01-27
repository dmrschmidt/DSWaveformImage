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

typedef NS_ENUM(NSInteger, DSWaveformStyle) {
    DSWaveformStyleStripes = 0,
    DSWaveformStyleFull = 1
};

typedef NS_ENUM(NSInteger, DSWaveformPosition) {
    DSWaveformPositionBottom = -1,
    DSWaveformPositionMiddle = 0,
    DSWaveformPositionTop = 1
};

@interface DSWaveformImage : UIImage

@property(nonatomic, strong) UIColor *graphColor;
@property(nonatomic, assign) DSWaveformStyle style;
@property(nonatomic, assign) DSWaveformPosition position;

+ (UIImage *)waveformForAssetAtURL:(NSURL *)url
                             color:(UIColor *)color
                              size:(CGSize)size
                             scale:(CGFloat)scale
                             style:(DSWaveformStyle)style
                          position:(DSWaveformPosition)position;

+ (UIImage *)waveformForAsset:(AVURLAsset *)asset
                        color:(UIColor *)color
                         size:(CGSize)size
                        scale:(CGFloat)scale
                        style:(DSWaveformStyle)style
                     position:(DSWaveformPosition)position;

@end
