//
//  DSWaveformImageView.m
//  DSWaveformImage
//
//  Created by Dennis Schmidt on 04.11.13.
//  Copyright (c) 2013 dmrschmidt. All rights reserved.
//

#import "DSWaveformImageView.h"
#import "DSWaveformImage.h"

@implementation DSWaveformImageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _waveformColor = [UIColor darkGrayColor];
        _waveformStyle = DSWaveformStyleFull;
        _waveformPosition = DSWaveformPositionMiddle;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _waveformColor = [UIColor darkGrayColor];
        _waveformStyle = DSWaveformStyleFull;
        _waveformPosition = DSWaveformPositionMiddle;
    }
    return self;
}

- (void)setWaveformColor:(UIColor *)waveformColor {
    _waveformColor = waveformColor;
    [self updateWaveform];
}

- (void)setWaveformStyle:(DSWaveformStyle)waveformStyle {
    _waveformStyle = waveformStyle;
    [self updateWaveform];
}

- (void)setWaveformPosition:(DSWaveformPosition)waveformPosition {
    _waveformPosition = waveformPosition;
    [self updateWaveform];
}

- (void)setAudioURL:(NSURL *)audioURL {
    _audioURL = audioURL;
    [self updateWaveform];
}

#pragma mark - Private

- (void)updateWaveform {
    UIImage *image = nil;
    if (self.audioURL) {
        image = [DSWaveformImage waveformForAssetAtURL:self.audioURL
                                                 color:self.waveformColor
                                                  size:self.bounds.size
                                                 scale:[UIScreen mainScreen].scale
                                                 style:self.waveformStyle
                                              position:self.waveformPosition];
    }
    self.image = image;
}

@end
