//
//  DSWaveformImageView.h
//  DSWaveformImage
//
//  Created by Dennis Schmidt on 04.11.13.
//  Copyright (c) 2013 dmrschmidt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSWaveformImageModel.h"

@interface DSWaveformImageView : UIImageView
@property(nonatomic, strong) IBInspectable NSURL *audioURL;
@property(nonatomic, strong) IBInspectable UIColor *waveformColor;
@property(nonatomic, assign) IBInspectable DSWaveformStyle waveformStyle;
@property(nonatomic, assign) IBInspectable DSWaveformPosition waveformPosition;
@end
