//
//  DSViewController.m
//  DSWaveformImage
//
//  Created by Dennis Schmidt on 04.11.13.
//  Copyright (c) 2013 dmrschmidt. All rights reserved.
//

#import "DSViewController.h"
#import "DSWaveformImage.h"
#import "DSWaveformImageView.h"

@interface DSViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet DSWaveformImageView *waveformImageView;
@end

@implementation DSViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"example_sound" withExtension:@"m4a"];
  UIColor *color = [UIColor redColor];
  CGSize size = self.waveformImageView.bounds.size;
  UIImage *waveformImage = [DSWaveformImage waveformForAssetAtURL:audioURL
                                                            color:color
                                                             size:size
                                                            scale:2.0
                                                            style:DSWaveformStyleFull];
	self.imageView.image = waveformImage;
  [self.waveformImageView setAudioURL:audioURL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
