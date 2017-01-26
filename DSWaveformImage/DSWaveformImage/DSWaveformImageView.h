//
//  DSWaveformImageView.h
//  DSWaveformImage
//
//  Created by Dennis Schmidt on 04.11.13.
//  Copyright (c) 2013 dmrschmidt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSWaveformImageView : UIImageView
@property(nonatomic, strong) NSURL *audioURL;
@property(nonatomic, strong) UIColor *waveformColor;
@end
