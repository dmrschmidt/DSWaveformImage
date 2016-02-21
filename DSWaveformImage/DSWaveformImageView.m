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
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
  }
  return self;
}

- (void)setAudioURL:(NSURL *)audioURL {
  _audioURL = audioURL;
  UIImage *image = nil;
  if (audioURL) {
    image = [DSWaveformImage waveformForAssetAtURL:audioURL
                                             color:self.waveformColor
                                              size:self.bounds.size
                                             scale:[UIScreen mainScreen].scale
                                             style:DSWaveformStyleFull];
  }
  self.image = image;
}

@end
